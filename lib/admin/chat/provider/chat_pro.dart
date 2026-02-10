import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:http/http.dart' as http;
import 'package:print_helper/models/search_modals.dart';
import 'package:print_helper/models/twilio_models.dart';
import 'package:print_helper/services/helpers.dart';
import 'package:print_helper/services/api_service.dart';
import 'package:print_helper/widgets/toasts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_group_model.dart';
import '../models/chat_models.dart';
import '../../../models/profile_models.dart';
import '../../../services/api_routes.dart';
import '../service/chat_push_notify.dart';
import '../service/reverb_service.dart';
import '../service/voice_recorder_service.dart';
import '../../../utils/console_util.dart';
import '../../../widgets/loaders.dart';

class ChatPro extends ChangeNotifier {
  bool isConnecting = true;
  // NEW: Track user online status
  bool isOtherUserOnline = false;
  bool isOtherUserTyping = false;
  bool isChatScreenOpen = false;
  int? currentActiveConversationId;
  int totalUnreadCount = 0; // Aggregated badge count for nav
  final List<ChatConversation> conversations = [];
  final List<ChatMessage> messages = [];
  ReverbSocketService? _chatListSocket; // Keeps global user events (new chats)
  ReverbSocketService? _conversationSocket;

  Timer? _typingThrottle;
  Timer? _typingAutoClear;

  GroupDetail? currentGroup;
  bool isGroupLoading = false;

  List<SearchUsers> searchResults = [];
  final Set<int> selectedUserIdss = {};
  final List<SearchUsers> selectedUsers = [];
  bool isLoading = false;
  String? errorMessage;
  Timer? _debounce;

  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;

  // Message search-related state
  List<ChatMessage> messageSearchResults = [];
  bool isSearching = false;
  String searchQuery = "";
  int searchTotalResults = 0;
  int searchCurrentPage = 1;
  int searchLastPage = 1;
  ProfileData? _userProfile;
  // String? get errorMessage => _errorMessage;
  ProfileData? get userProfile => _userProfile;

  final VoiceRecorderService _voiceRecorder = VoiceRecorderService();
  bool isRecordingVoice = false;

  // Twilio Numbers
  List<TwilioCredential> twilioNumbers = [];
  bool isTwilioLoading = false;
  bool twilioHasError = false;

  // Twilio Clients with Contacts
  List<TwilioClient> twilioClients = [];
  bool isTwilioClientsLoading = false;
  bool twilioClientsHasError = false;

  // Twilio Staff (Assigned Accounts)
  List<AssignedAccount> twilioStaff = [];
  bool isTwilioStaffLoading = false;
  bool twilioStaffHasError = false;
  int twilioNumbersRevision = 0;
  int twilioClientsRevision = 0;
  int twilioStaffRevision = 0;
  Future<void> startDummyVoiceRecording() async {
    isRecordingVoice = true;
    notifyListeners();
    await _voiceRecorder.start();
  }

  /// ---------------- API HEADERS ----------------
  Future<Map<String, String>> apiHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString("token") ?? "";
    return {
      "Accept": "application/json",
      "Content-Type": "application/json",
      "Authorization": "Bearer $authToken",
    };
  }

  Future<String?> getTwilioAccessToken({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString("twilio_access_token");
    if (!forceRefresh && cached != null && cached.isNotEmpty) {
      return cached;
    }
    try {
      final headers = await apiHeaders();
      debugPrint(
        "Twilio access token request: ${ApiRoutes.baseUrl}${ApiRoutes.twilioAccessToken}",
      );
      debugPrint("Twilio access token headers: $headers");
      final data = await ApiService().getDataFromApi(
        api: ApiRoutes.twilioAccessToken,
        headers: headers,
        showRes: true,
      );
      debugPrint("Twilio access token raw response: $data");
      if (data is Map<String, dynamic>) {
        final dynamic payload = data["data"] ?? data;
        debugPrint("Twilio access token payload: $payload");
        final token = payload is Map<String, dynamic>
            ? (payload["token"] ?? payload["access_token"])
            : null;
        debugPrint("Twilio access token parsed: $token");
        if (token is String && token.isNotEmpty) {
          await prefs.setString("twilio_access_token", token);
          return token;
        }
      }
    } catch (e) {
      debugPrint("Twilio access token error: $e");
    }
    return null;
  }

  Future<List<CallFromNumber>> fetchCallFromNumbers() async {
    try {
      final url = Uri.parse("${ApiRoutes.baseUrl}${ApiRoutes.callFromNumbers}");
      final headers = await apiHeaders();
      debugPrint("call-from-numbers url: $url");
      debugPrint("call-from-numbers headers: $headers");
      final res = await http.get(url, headers: headers);
      debugPrint("call-from-numbers status: ${res.statusCode}");
      debugPrint("call-from-numbers body: ${res.body}");
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> numbers = data['data']['numbers'] ?? [];
          return numbers
              .map((e) => CallFromNumber.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint("fetchCallFromNumbers error: $e");
    }
    return [];
  }

  Future<List<CallFromNumber>> fetchUserTwilioNumbers(int userId) async {
    try {
      final url = Uri.parse(
        "${ApiRoutes.baseUrl}${ApiRoutes.userTwilioNumbers(userId)}",
      );
      final headers = await apiHeaders();
      debugPrint("user-twilio-numbers url: $url");
      debugPrint("user-twilio-numbers headers: $headers");
      final res = await http.get(url, headers: headers);
      debugPrint("user-twilio-numbers status: ${res.statusCode}");
      debugPrint("user-twilio-numbers body: ${res.body}");
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> numbers = data['data']['numbers'] ?? [];
          return numbers
              .map((e) => CallFromNumber.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint("fetchUserTwilioNumbers error: $e");
    }
    return [];
  }

  /// ---------------- INIT CHAT LIST SOCKET ----------------
  Future<void> initChatListSocket({
    required String userId,
    required dynamic context,
  }) async {
    // if (_socketInitialized) return;
    // _socketInitialized = true;
    if (_chatListSocket != null) return;
    final headers = await apiHeaders();
    _chatListSocket = ReverbSocketService(
      onConnected: () {
        debugPrint("✅ Chat list socket connected");
      },
      onMessageReceived: (data) {
        debugPrint("📩 CHAT LIST DATA: $data");
        _handleRealtimeChatListMessage(data, userId);
      },
      onTypingReceived: (isTyping) {
        isOtherUserTyping = isTyping;
        notifyListeners();
        _typingAutoClear?.cancel();
        if (isTyping) {
          _typingAutoClear = Timer(const Duration(seconds: 3), () {
            isOtherUserTyping = false;
            notifyListeners();
          });
        }
      },
      onConversationCreated: (data) {
        _handleNewConversation(data);
      },
      onGroupMemberAdded: (data) {
        _handleGroupMemberAdded(data);
      },
      onGroupMemberRemoved: (data) {
        _handleGroupMemberRemoved(data);
      },
      onUnreadCountUpdated: (data) {
        _handleUnreadCountUpdated(data);
      },
    );
    _chatListSocket!.connectUserChannel(
      host: ApiRoutes.socketHost,
      port: ApiRoutes.socketPort,
      appKey: ApiRoutes.appKey,
      userId: userId, // ✅ USER ID
      authEndpoint: Uri.parse("${ApiRoutes.baseUrl}broadcasting/auth"),
      headers: headers,
      context: context,
    );
  }

  Future<void> initConversationSocket({
    required int conversationId,
    required int currentUserId,
  }) async {
    disconnectConversationSocket();
    currentActiveConversationId = conversationId;
    final headers = await apiHeaders();
    _conversationSocket = ReverbSocketService(
      currentUserId: currentUserId.toString(),
      onConnected: () {
        debugPrint("✅ Conversation socket connected");
      },
      onMessageReceived: (data) {
        _handleRealtimeConversationMessage(data, currentUserId, conversationId);
      },
      onTypingReceived: (isTyping) {
        isOtherUserTyping = isTyping;
        notifyListeners();
        _typingAutoClear?.cancel();
        if (isTyping) {
          _typingAutoClear = Timer(const Duration(seconds: 4), () {
            isOtherUserTyping = false;
            notifyListeners();
          });
        }
      }, // 3. ✅ NEW: Message Deleted
      onMessageDeleted: (data) {
        _handleMessageDeleted(data);
      },
      // 4. ✅ NEW: Message Status (Read/Delivered)
      onMessageStatusUpdated: (data) {
        _handleMessageStatusUpdate(data);
      },
      // 5. ✅ NEW: User Status (Online/Offline)
      onUserStatusChanged: (data) {
        _handleUserStatusChange(data);
      },
    );
    _conversationSocket!.connectConversationChannel(
      host: ApiRoutes.socketHost,
      port: ApiRoutes.socketPort,
      appKey: ApiRoutes.appKey,
      conversationId: conversationId.toString(),
      authEndpoint: Uri.parse("${ApiRoutes.baseUrl}broadcasting/auth"),
      headers: headers,
    );
  }

  void disconnectConversationSocket() {
    if (_conversationSocket != null) {
      debugPrint("🔌 Disconnecting Conversation Socket...");
      _conversationSocket!.disconnect();
      _conversationSocket = null;
      isOtherUserTyping = false;
      isOtherUserOnline = false;
      currentActiveConversationId = null;
    }
  }

  // 1. Handle New Message (Existing)
  // void _handleRealtimeConversationMessage(
  //   Map<String, dynamic> data,
  //   int currentUserId,
  //   int conversationId,
  // ) {
  //   final payload = data.containsKey('message') && data['message'] is Map
  //       ? data['message']
  //       : data;
  //   if (payload['conversation_id'].toString() != conversationId.toString()) {
  //     return;
  //   }
  //   final msg = ChatMessage.fromJson(payload, currentUserId);
  //   if (msg.senderId == currentUserId) return; // Prevent duplicate self-message
  //   messages.insert(0, msg);
  //   debugPrint("📩 Message received. ChatScreenOpen: $isChatScreenOpen");
  //   if (!isChatScreenOpen) {
  //     NotificationService.instance.showChatNotification(
  //       title: "New message",
  //       body: msg.message,
  //       id: msg.id,
  //     );
  //   }
  //   // If we are in the chat, mark as read immediately via API
  //   markConversAsRead(conversationId);
  //   notifyListeners();
  // }

  void _handleRealtimeConversationMessage(
    Map<String, dynamic> data,
    int currentUserId,
    int conversationId,
  ) {
    final payload = data.containsKey('message') && data['message'] is Map
        ? data['message']
        : data;
    if (payload['conversation_id'].toString() != conversationId.toString()) {
      return;
    }
    final msg = ChatMessage.fromJson(payload, currentUserId);

    /// Prevent duplicate self-message
    if (msg.senderId == currentUserId) return;

    /// Check if message already exists
    final existingIndex = messages.indexWhere((m) => m.id == msg.id);

    /// If exists → update message
    if (existingIndex != -1) {
      messages[existingIndex] = msg;
    }
    /// If new → insert at top
    else {
      messages.insert(0, msg);

      /// Show notification only for new messages & when chat is closed
      if (!isChatScreenOpen) {
        NotificationService.instance.showChatNotification(
          title: "New message",
          body: msg.message,
          id: msg.id,
        );
      }
    }
    debugPrint("📩 Message received. ChatScreenOpen: $isChatScreenOpen");

    /// If chat screen is open, mark as read
    if (isChatScreenOpen) {
      markConversAsRead(conversationId);
    }

    notifyListeners();
  }

  // 2. ✅ Handle Message Deletion
  void _handleMessageDeleted(Map<String, dynamic> data) {
    // Expected data: { "id": 123, "conversation_id": 456 }
    final messageId = data['id'];
    if (messageId == null) return;
    messages.removeWhere((m) => m.id.toString() == messageId.toString());
    notifyListeners();
  }

  void _handleMessageStatusUpdate(Map<String, dynamic> data) {
    final status = data['status']; // "read" | "delivered"
    final messageId = data['id'];
    if (messageId == null) return;
    final index = messages.indexWhere(
      (m) => m.id.toString() == messageId.toString(),
    );
    if (index == -1) return;
    if (status == 'read') {
      messages[index] = messages[index].copyWith(
        isRead: true,
        readAt: DateTime.now(),
      );
    }
    if (status == 'delivered') {
      messages[index] = messages[index].copyWith(
        isDelivered: true,
        deliveredAt: DateTime.now(),
      );
    }
    notifyListeners();
  }

  // 4. ✅ Handle User Online Status
  void _handleUserStatusChange(Map<String, dynamic> data) {
    // Expected data: { "user_id": 99, "status": "online" }
    final status = data['status']; // 'online' or 'offline'
    isOtherUserOnline = (status == 'online');
    notifyListeners();
  }

  // 5. ✅ Handle New Conversation (Chat List)
  void _handleNewConversation(Map<String, dynamic> data) {
    // Add logic here if you want new chats to appear instantly in the list
    // strictly parsing data into ChatConversation and inserting at index 0
    try {
      final newChat = ChatConversation.fromJson(data['conversation']);
      final existingIndex = conversations.indexWhere((c) => c.id == newChat.id);
      if (existingIndex != -1) {
        // Replace existing conversation to avoid duplicates
        conversations[existingIndex] = newChat;
      } else {
        conversations.insert(0, newChat);
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error parsing new conversation: $e");
    }
  }

  // 6. ✅ Handle Group Member Added
  void _handleGroupMemberAdded(Map<String, dynamic> data) async {
    try {
      final conversationId = data['conversation_id'];
      if (conversationId == null) return;
      debugPrint("Member added to group $conversationId");
      // Fetch updated conversation details
      await _updateSingleConversation(conversationId);
      notifyListeners();
    } catch (e) {
      debugPrint("Error handling group member added: $e");
    }
  }

  // 7. ✅ Handle Group Member Removed
  void _handleGroupMemberRemoved(Map<String, dynamic> data) async {
    try {
      final conversationId = data['conversation_id'];
      final removedUserId = data['user_id'];
      if (conversationId == null) return;
      debugPrint("Member $removedUserId removed from group $conversationId");
      // Fetch updated conversation details
      await _updateSingleConversation(conversationId);
      notifyListeners();
    } catch (e) {
      debugPrint("Error handling group member removed: $e");
    }
  }

  /// ---------------- UPDATE SINGLE CONVERSATION ----------------
  Future<void> _updateSingleConversation(int conversationId) async {
    try {
      final res = await http.get(
        Uri.parse("${ApiRoutes.baseUrl}chat/conversations/$conversationId"),
        headers: await apiHeaders(),
      );
      debugPrint("_updateSingleConversation response: ${res.statusCode}");
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        debugPrint("_updateSingleConversation data: $data");
        if (data['success'] == true && data['data'] != null) {
          final updatedConvo = ChatConversation.fromJson(data['data']);
          // Find and replace the conversation in the list
          final index = conversations.indexWhere((c) => c.id == conversationId);
          if (index != -1) {
            conversations[index] = updatedConvo;
            debugPrint("Updated conversation $conversationId in list");
          } else {
            // If not found, add to top (new conversation)
            conversations.insert(0, updatedConvo);
            debugPrint("Added new conversation $conversationId to list");
          }
        } else if (data['success'] == false) {
          // If backend returns success=false, user might have been removed
          debugPrint(
            "Backend returned success=false for conversation $conversationId",
          );
          final index = conversations.indexWhere((c) => c.id == conversationId);
          if (index != -1) {
            conversations.removeAt(index);
            debugPrint(
              "Removed conversation $conversationId from list (no access)",
            );
          }
        }
      } else if (res.statusCode == 403 || res.statusCode == 404) {
        // User no longer has access to this conversation (removed from group)
        debugPrint("User removed from conversation $conversationId");
        final index = conversations.indexWhere((c) => c.id == conversationId);
        if (index != -1) {
          conversations.removeAt(index);
          debugPrint("Removed conversation $conversationId from list");
        }
      }
    } catch (e) {
      debugPrint("_updateSingleConversation error: $e");
    }
  }

  /// ---------------- HANDLE REALTIME MESSAGE (CHAT LIST) ----------------
  // void _handleRealtimeChatListMessage(
  //   Map<String, dynamic> data,
  //   String currentUserId,
  // ) {
  //   final conversationId = data['conversation_id'];
  //   final senderId = data['user_id'];
  //   final index = conversations.indexWhere(
  //     (c) => c.id.toString() == conversationId.toString(),
  //   );
  //   // if (index == -1) {
  //   //   // Optional: Reload list if a new conversation appears that isn't in the list yet
  //   //   // loadConversations();
  //   //   return;
  //   // }
  //   final old = conversations[index];
  //   final latestMessage = ChatLatestMessage.fromJson(data);

  //   final existingIndex = messages.indexWhere((m) {
  //     logData(title: "m.id, m.message", data: "${m.id}, ${m.message}");

  //     logData(title: "latestMessage.id", data: latestMessage.id);
  //     return m.id == latestMessage.id;
  //   });
  //   logData(title: "existingIndex", data: '$existingIndex');

  //   final insertIndex = existingIndex != -1 ? existingIndex : 0;
  //   logData(title: "insertIndex", data: insertIndex);

  //   final updatedConversation = ChatConversation(
  //     id: old.id,
  //     type: old.type,
  //     title: old.title,
  //     participants: old.participants,
  //     latestMessage: latestMessage,
  //     unreadCount: senderId.toString() == currentUserId
  //         ? old.unreadCount
  //         : old.unreadCount + 1,
  //     updatedAt: DateTime.now(),
  //     isDefault: old.isDefault,
  //   );
  //   conversations
  //     ..removeAt(index)
  //     ..insert(insertIndex, updatedConversation);

  //   NotificationService.instance.showChatNotification(
  //     title: "New message From ${latestMessage.userName}",
  //     body: latestMessage.message,
  //     id: latestMessage.id,
  //   );
  //   notifyListeners();
  // }

  void _handleRealtimeChatListMessage(
    Map<String, dynamic> data,
    String currentUserId,
  ) {
    final conversationId = data['conversation_id'];
    final senderId = data['user_id'];

    final convoIndex = conversations.indexWhere(
      (c) => c.id.toString() == conversationId.toString(),
    );

    if (convoIndex == -1) return;

    final oldConversation = conversations[convoIndex];
    final latestMessage = ChatLatestMessage.fromJson(data);

    /// Check if this message already exists
    final existingIndex = messages.indexWhere((m) => m.id == latestMessage.id);

    /// Update unread count
    final unreadCount = senderId.toString() == currentUserId
        ? oldConversation.unreadCount
        : oldConversation.unreadCount + 1;

    // final updatedConversation = oldConversation.copyWith(
    //   latestMessage: latestMessage,
    //   unreadCount: unreadCount,
    //   updatedAt: DateTime.now(),
    // );

    final updatedConversation = ChatConversation(
      id: oldConversation.id,
      type: oldConversation.type,
      title: oldConversation.title,
      participants: oldConversation.participants,
      latestMessage: latestMessage,
      unreadCount: unreadCount,
      updatedAt: DateTime.now(),
      isDefault: oldConversation.isDefault,
      image: oldConversation.image,
    );

    /// Remove old position
    conversations.removeAt(convoIndex);

    /// 👉 If message exists → keep it in same position
    /// 👉 If new message → move to top (index 0)
    final insertIndex = existingIndex != -1 ? convoIndex : 0;

    conversations.insert(insertIndex, updatedConversation);

    // Keep aggregated unread badge in sync for nav
    if (senderId.toString() != currentUserId && existingIndex == -1) {
      totalUnreadCount = totalUnreadCount + 1;
    }

    _recomputeTotalUnreadFromList();

    /// Show notification only for new incoming messages
    if (senderId.toString() != currentUserId && existingIndex == -1) {
      NotificationService.instance.showChatNotification(
        title: "New message from ${latestMessage.userName}",
        body: latestMessage.message,
        id: latestMessage.id,
      );
    }

    notifyListeners();
  }

  /// ---------------- LOAD CONVERSATIONS ----------------
  Future<void> loadConversations() async {
    Loaders.show();
    notifyListeners();
    try {
      final res = await http.get(
        Uri.parse("${ApiRoutes.baseUrl}chat/conversations"),
        headers: await apiHeaders(),
      );
      if (res.statusCode != 200) {
        throw Exception("HTTP ${res.statusCode}");
      }
      final decoded = jsonDecode(res.body);
      totalUnreadCount = decoded['total_unread_count'] ?? 0;
      debugPrint("totalUnreadCount: $totalUnreadCount");
      final List list = decoded['data'] ?? [];

      conversations
        ..clear()
        ..addAll(
          list.map(
            (e) => ChatConversation.fromJson(
              e,
              totalUnreadCount: totalUnreadCount,
            ),
          ),
        );

      _recomputeTotalUnreadFromList();
    } catch (e) {
      debugPrint("loadConversations error: $e");
    } finally {
      Loaders.hide();
      notifyListeners();
    }
  }

  void _handleUnreadCountUpdated(Map<String, dynamic> data) {
    try {
      final dynamic raw =
          data['total_unread_count'] ?? data['count'] ?? data['unread_count'];
      final int parsed = int.tryParse(raw?.toString() ?? '') ?? 0;
      totalUnreadCount = parsed;
      notifyListeners();
    } catch (e) {
      debugPrint("_handleUnreadCountUpdated error: $e");
    }
  }

  Future<void> fetchMessages({
    required String conversationId,
    required int currentUserId,
    int? lastPage,
    bool loadMore = false,
  }) async {
    if (_isLoadingMore || (!_hasMore && loadMore)) return;
    if (!loadMore) {
      // initial load: show loader and clear any previous state
      Loaders.show();
      notifyListeners();
    } else {
      _isLoadingMore = true;
      notifyListeners();
      await delayed(millisec: 1000);
    }
    final pageToLoad = _currentPage;
    try {
      final res = await http.get(
        Uri.parse(
          "${ApiRoutes.baseUrl}chat/conversations/$conversationId/messages?page=$pageToLoad",
        ),
        headers: await apiHeaders(),
      );
      debugPrint("uri: ${res.request!.url}");
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        // Try to read last_page from API meta if caller didn't provide it
        final metaLastPage = decoded['meta']?['last_page'] ?? lastPage ?? 1;
        final List data = decoded['data'] ?? [];
        final fetched = data
            .map((e) => ChatMessage.fromJson(e, currentUserId))
            .toList()
            .reversed
            .toList(); // already oldest→newest
        messages.addAll(fetched);
        // go to next page
        _currentPage++;
        // check if more pages exist
        _hasMore = _currentPage <= metaLastPage;
        debugPrint(
          'currentPage $_currentPage lastPage $metaLastPage hasMore $_hasMore',
        );
      }
    } catch (e) {
      debugPrint("fetchMessages error: $e");
    } finally {
      _isLoadingMore = false;
      if (!loadMore) Loaders.hide();
      notifyListeners();
    }
  }

  /// Cleanup on screen exit
  void reset() {
    messages.clear();
    _currentPage = 1;
    _hasMore = true;
    _isLoadingMore = false;
    notifyListeners();
  }

  /// ---------------- SEARCH MESSAGES ----------------
  Future<void> searchMessages({
    required String conversationId,
    required String query,
    required int currentUserId,
  }) async {
    if (query.trim().isEmpty) {
      clearSearch();
      return;
    }
    isSearching = true;
    searchQuery = query;
    notifyListeners();
    try {
      final res = await http.get(
        Uri.parse(
          "${ApiRoutes.baseUrl}chat/conversations/$conversationId/messages/search?query=${Uri.encodeComponent(query)}",
        ),
        headers: await apiHeaders(),
      );
      debugPrint("Search URI: ${res.request!.url}");
      debugPrint("Search Response: ${res.body}");
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded['success'] == true) {
          final List data = decoded['data'] ?? [];
          final meta = decoded['meta'];
          messageSearchResults = data
              .map((e) => ChatMessage.fromJson(e, currentUserId))
              .toList();
          // If meta is available, use it; otherwise use data length
          searchTotalResults = meta?['total'] ?? data.length;
          searchCurrentPage = meta?['current_page'] ?? 1;
          searchLastPage = meta?['last_page'] ?? 1;
          debugPrint("Search found: $searchTotalResults results");
        }
      }
    } catch (e) {
      debugPrint("searchMessages error: $e");
    } finally {
      notifyListeners();
    }
  }

  void clearSearch() {
    messageSearchResults.clear();
    isSearching = false;
    searchQuery = "";
    searchTotalResults = 0;
    searchCurrentPage = 1;
    searchLastPage = 1;
    notifyListeners();
  }

  /// ---------------- SEND MESSAGE ----------------
  // Future<void> sendMessage({
  //   required String text,
  //   required int conversationId,
  //   required int currentUserId,
  // }) async {
  //   if (text.trim().isEmpty) return;
  //   final tempMessage = ChatMessage(
  //     id: DateTime.now().millisecondsSinceEpoch,
  //     senderId: currentUserId,
  //     conversationId: conversationId,
  //     isMe: true,
  //     message: text,
  //     createdAt: DateTime.now(),
  //   );
  //   // Only add to UI list if we are currently inside THIS specific chat
  //   if (currentActiveConversationId == conversationId) {
  //     messages.insert(0, tempMessage);
  //   }
  //   // messages.insert(0, tempMessage);
  //   final index = conversations.indexWhere((c) => c.id == conversationId);
  //   if (index != -1) {
  //     final old = conversations[index];
  //     final updatedConversation = ChatConversation(
  //       id: old.id,
  //       type: old.type,
  //       title: old.title,
  //       participants: old.participants,
  //       latestMessage: ChatLatestMessage(
  //         id: tempMessage.id,
  //         message: text,
  //         type: "text",
  //         createdAt: DateTime.now(),
  //         userId: currentUserId,
  //         userName: userProfile?.name ?? "You",
  //       ),
  //       unreadCount: 0, // sender = me
  //       updatedAt: DateTime.now(),
  //       isDefault: old.isDefault,
  //       image: old.image,
  //     );
  //     conversations
  //       ..removeAt(index)
  //       ..insert(0, updatedConversation);
  //   }
  //   notifyListeners();
  //   /// API call
  //   try {
  //     await http.post(
  //       Uri.parse(
  //         "${ApiRoutes.baseUrl}chat/conversations/$conversationId/messages",
  //       ),
  //       headers: await apiHeaders(),
  //       body: jsonEncode({"message": text, "type": "text"}),
  //     );
  //   } catch (e) {
  //     debugPrint("sendMessage error: $e");
  //   }
  // }               //old

  // Inside ChatPro class

  Future<void> sendMessage({
    required String text,
    required int conversationId,
    required int currentUserId,
    String type = 'text',
    String? audioUrl,
    int? audioDuration,
  }) async {
    // 1. Create Optimistic Message
    final tempMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch,
      senderId: currentUserId,
      conversationId: conversationId,
      isMe: true,
      message: text,
      createdAt: DateTime.now(),
      type: type, //  Use passed type
      audioUrl: audioUrl, // Use passed URL
      audioDuration: audioDuration,
    );
    // 2. Add to UI List (Only if in current chat)
    if (currentActiveConversationId == conversationId) {
      messages.insert(0, tempMessage);
    }
    // 3. Update Chat List "Latest Message"
    final index = conversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      final old = conversations[index];
      // Determine preview text based on type
      String previewText = text;
      if (type == 'voice') previewText = "🎤 Voice Message";
      if (type == 'image') previewText = "📷 Image";
      final updatedConversation = ChatConversation(
        id: old.id,
        type: old.type,
        title: old.title,
        participants: old.participants,
        latestMessage: ChatLatestMessage(
          id: tempMessage.id,
          message: previewText, //  Show correct preview
          type: type,
          createdAt: DateTime.now(),
          userId: currentUserId,
          userName: userProfile?.name ?? "You",
        ),
        unreadCount: 0,
        updatedAt: DateTime.now(),
        isDefault: old.isDefault,
        image: old.image,
      );
      conversations
        ..removeAt(index)
        ..insert(0, updatedConversation);
    }
    notifyListeners();
    try {
      final Map<String, dynamic> body = {"message": text, "type": type};
      // If forwarding voice, include the URL and Duration
      if (type == 'voice' && audioUrl != null) {
        body['audio_url'] = audioUrl;
        body['voice_duration'] = audioDuration;
      }
      await http.post(
        Uri.parse(
          "${ApiRoutes.baseUrl}chat/conversations/$conversationId/messages",
        ),
        headers: await apiHeaders(),
        body: jsonEncode(body),
      );
    } catch (e) {
      debugPrint("sendMessage error: $e");
    }
  }

  /// ---------------- TYPING ----------------

  void onTextTyping({required int conversationId, required String text}) {
    if (conversationId <= 0) return;
    _typingThrottle?.cancel();
    final isTyping = text.isNotEmpty;
    _typingThrottle = Timer(const Duration(milliseconds: 1000), () {
      sendTypingStatus(conversationId: conversationId, isTyping: isTyping);
    });
    if (text.length == 1) {
      sendTypingStatus(conversationId: conversationId, isTyping: true);
    }
  }

  Future<void> sendTypingStatus({
    required int conversationId,
    required bool isTyping,
  }) async {
    try {
      final res = await http.post(
        Uri.parse(
          "${ApiRoutes.baseUrl}chat/conversations/$conversationId/typing",
        ),
        headers: await apiHeaders(),
        body: jsonEncode({"is_typing": isTyping ? "true" : "false"}),
      );
      debugPrint("Typing status sent: $isTyping");
      debugPrint("uri: ${res.request!.url}");

      if (res.statusCode != 200) {
        throw Exception("HTTP ${res.statusCode}");
      }
    } catch (_) {}
  }

  /// MARK CONVERSATION AS READ
  Future<void> markConversAsRead(int conversationId) async {
    try {
      final res = await http.post(
        Uri.parse(
          "${ApiRoutes.baseUrl}chat/conversations/$conversationId/read",
        ),
        headers: await apiHeaders(),
      );
      if (res.statusCode == 200) {
        final index = conversations.indexWhere((c) => c.id == conversationId);
        if (index != -1) {
          final int unreadBefore = conversations[index].unreadCount;
          totalUnreadCount = totalUnreadCount - unreadBefore;
          if (totalUnreadCount < 0) totalUnreadCount = 0;
          conversations[index].unreadCount = 0;
          _recomputeTotalUnreadFromList();
          notifyListeners();
        }
        debugPrint("Conversation $conversationId marked as read");
      } else {
        debugPrint("Failed to mark as read (${res.statusCode}): ${res.body}");
      }
    } catch (e) {
      debugPrint(" markConversationAsRead error: $e");
    }
  }

  void _recomputeTotalUnreadFromList() {
    final int sum = conversations.fold<int>(
      0,
      (acc, c) => acc + (c.unreadCount),
    );
    totalUnreadCount = sum;
  }

  Future<bool> createGroup({
    required String title,
    required List<int> userIds,
    File? image,
    required BuildContext context,
  }) async {
    Loaders.show();
    notifyListeners();
    try {
      final url = Uri.parse('${ApiRoutes.baseUrl}chat/conversations');
      final request = http.MultipartRequest('POST', url);
      final headers = await apiHeaders();
      request.headers.addAll(headers);
      request.fields['type'] = 'group';
      request.fields['title'] = title;
      for (int i = 0; i < userIds.length; i++) {
        request.fields['user_ids[$i]'] = userIds[i].toString();
      }
      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', image.path),
        );
      }
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        clearGroupCreationState();
        return true;
      } else {
        errorMessage = data['message'] ?? 'Failed to create group';
        return false;
      }
    } catch (e) {
      errorMessage = 'Network error';
      debugPrint('createGroup error: $e');
      return false;
    } finally {
      Loaders.hide();
      notifyListeners();
    }
  }

  Future<bool> updateGroup({
    required int conversationId,
    required String title,
    required List<int> userIds,
    File? image,
  }) async {
    Loaders.show();
    notifyListeners();
    try {
      final url = Uri.parse(
        '${ApiRoutes.baseUrl}chat/conversations/$conversationId/update',
      );
      debugPrint("URL: $url");
      final request = http.MultipartRequest('POST', url);
      final headers = await apiHeaders();
      request.headers.addAll(headers);
      request.fields['title'] = title;
      for (int i = 0; i < userIds.length; i++) {
        request.fields['user_ids[$i]'] = userIds[i].toString();
      }
      debugPrint("request.fields: ${request.fields}");
      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', image.path),
        );
      }
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);
      debugPrint("data: $data");
      if (data['success'] == true) {
        // If API returns updated group data, update in-memory state
        try {
          final returned = data['data'];
          if (returned != null && returned is Map) {
            final Map<String, dynamic> returnedMap = Map<String, dynamic>.from(
              returned,
            );
            // Update currentGroup if full group details are returned
            if (returnedMap.containsKey('title')) {
              try {
                currentGroup = GroupDetail.fromJson(returnedMap);
              } catch (_) {}
            }
            // Update conversations list entry (title/image/updatedAt)
            final idx = conversations.indexWhere((c) => c.id == conversationId);
            if (idx != -1) {
              final old = conversations[idx];
              final updatedTitle = returnedMap['title'] ?? old.title;
              final updatedImage = returnedMap['image'] ?? old.image;
              final updatedAt = returnedMap['updated_at'] != null
                  ? DateTime.tryParse(returnedMap['updated_at'].toString()) ??
                        DateTime.now()
                  : DateTime.now();
              final updatedConversation = ChatConversation(
                id: old.id,
                type: old.type,
                title: updatedTitle,
                participants: old.participants,
                latestMessage: old.latestMessage,
                image: updatedImage,
                unreadCount: old.unreadCount,
                updatedAt: updatedAt,
                isDefault: old.isDefault,
              );
              conversations
                ..removeAt(idx)
                ..insert(idx, updatedConversation);
            }
          }
        } catch (e) {
          showToast(message: data['message'] ?? 'Failed to update group');
          debugPrint('updateGroup: failed to apply returned data: $e');
        }
        clearGroupCreationState();
        notifyListeners();
        return true;
      } else {
        showToast(message: data['message'] ?? 'Failed to update group');
        errorMessage = data['message'] ?? 'Failed to update group';
        return false;
      }
    } catch (e) {
      errorMessage = 'Network error';
      debugPrint('updateGroup error: $e');
      return false;
    } finally {
      Loaders.hide();
      notifyListeners();
    }
  }

  Future<GroupDetail?> getGroupDetails(int conversationId) async {
    try {
      currentGroup = null;
      isGroupLoading = true;
      notifyListeners();
      final res = await http.get(
        Uri.parse("${ApiRoutes.baseUrl}chat/conversations/$conversationId"),
        headers: await apiHeaders(),
      );
      debugPrint("uri: ${res.request!.url}");
      final data = jsonDecode(res.body);
      debugPrint("data: $data");

      if (data['success'] == true && data['data'] != null) {
        currentGroup = GroupDetail.fromJson(data['data']);
        selectedUsers
          ..clear()
          ..addAll(
            currentGroup!.participants.map(
              (p) => SearchUsers(
                id: p.id,
                name: p.name,
                lastName: p.lastName,
                image: p.image,
                role: p.role,
              ),
            ),
          );
        notifyListeners();
        return currentGroup;
      }
    } catch (e) {
      printData(title: "getGroupDetails error", data: e, e: true);
    } finally {
      isGroupLoading = false;
      notifyListeners();
    }
    return null;
  }

  Future<void> _searchUsers(String query, {bool includeGroups = false}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final url = Uri.parse(
        '${ApiRoutes.baseUrl}chat/users/search?query=$query&include_groups=$includeGroups',
      );
      debugPrint("URL: $url");
      final response = await http.get(url, headers: await apiHeaders());
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint("data: $data");
        if (data['success'] == true) {
          searchResults = (data['data'] as List)
              .map((e) => SearchUsers.fromJson(e))
              .toList();
        } else {
          errorMessage = "Failed to load users";
          searchResults = [];
        }
      } else {
        errorMessage = "Server error (${response.statusCode})";
        searchResults = [];
        isLoading = false;
      }
    } catch (e) {
      errorMessage = "Network error";
      searchResults = [];
      isLoading = false;
    }
    isLoading = false;
    notifyListeners();
  }

  /// ---------------- FETCH PROFILE ----------------

  Future<void> fetchUserProfile(String id, {int? conversationId}) async {
    Loaders.show();
    errorMessage = null;
    notifyListeners();
    try {
      final uri = conversationId != null
          ? Uri.parse(
              "${ApiRoutes.baseUrl}chat/users/$id?conversationId=$conversationId",
            )
          : Uri.parse("${ApiRoutes.baseUrl}chat/users/$id");
      debugPrint("Fetching profile from: $uri");
      final res = await http.get(uri, headers: await apiHeaders());
      debugPrint("uri: ${res.request!.url}");
      if (res.statusCode == 200) {
        final jsonResponse = json.decode(res.body);
        final profileResponse = ProfileResponse.fromJson(jsonResponse);
        if (profileResponse.success) {
          _userProfile = profileResponse.data;
        } else {
          errorMessage = "Failed to retrieve data";
        }
      } else {
        errorMessage = "Error: ${res.statusCode}";
      }
    } catch (e) {
      errorMessage = "Connection error: $e";
    } finally {
      Loaders.hide();
      notifyListeners();
    }
  }

  /// ---------------- CLEAR SEARCH ----------------
  void clearUserSearch() {
    _debounce?.cancel();
    searchResults.clear();
    errorMessage = null;
    isLoading = false;
    notifyListeners();
  }

  void clearGroupCreationState() {
    selectedUsers.clear();
    searchResults.clear();
    isLoading = false;
    errorMessage = null;
    notifyListeners();
  }

  void onSearchChanged(String query) {
    // Cancel previous debounce
    _debounce?.cancel();
    // If input is empty → clear immediately
    if (query.trim().isEmpty) {
      clearUserSearch();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchUsers(query.trim());
    });
  }

  void onSearchGlobalChanged(String query) {
    // Cancel previous debounce
    _debounce?.cancel();
    // If input is empty → clear immediately
    if (query.trim().isEmpty) {
      clearUserSearch();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchUsers(query.trim(), includeGroups: true);
    });
  }

  void toggleUserSelection(SearchUsers user) {
    final exists = selectedUsers.any((u) => u.id == user.id);
    if (exists) {
      selectedUsers.removeWhere((u) => u.id == user.id);
    } else {
      selectedUsers.add(user);
    }
    notifyListeners();
  }

  void removeSelectedUser(SearchUsers user) {
    selectedUsers.removeWhere((u) => u.id == user.id);
    notifyListeners();
  }

  @override
  void dispose() {
    _typingThrottle?.cancel();
    _conversationSocket?.disconnect(); // Cleanup on full provider dispose
    _chatListSocket?.disconnect(); // Cleanup global socket
    _debounce?.cancel();
    super.dispose();
  }

  Future<int?> createConvId({
    required String type,
    required List<int> userIds,
    File? image,
    required BuildContext context,
  }) async {
    Loaders.show();
    notifyListeners();
    try {
      final url = Uri.parse('${ApiRoutes.baseUrl}chat/conversations');
      final request = http.MultipartRequest('POST', url);
      debugPrint('urlcreateConvId: $url');
      final headers = await apiHeaders();
      request.headers.addAll(headers);
      request.fields['type'] = type;
      for (int i = 0; i < userIds.length; i++) {
        request.fields['user_ids[$i]'] = userIds[i].toString();
      }
      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', image.path),
        );
      }
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);
      debugPrint('datacreateConvId: $data');
      if (data['success'] == true) {
        final convData = data['data'];
        final conv = ChatConversation.fromJson(convData);
        conversations.insert(0, conv);
        debugPrint("CONVvvvvvvvvvvvvvvvvvvv ID: ${conv.id}");
        return conv.id;
      } else {
        errorMessage = data['message'] ?? 'Failed to create';
        return null;
      }
    } catch (e) {
      errorMessage = 'Network error';
      debugPrint('create error: $e');
      return null;
    } finally {
      Loaders.hide();
      notifyListeners();
    }
  }

  int? findPrivateConversationWithUser(int otherUserId) {
    try {
      final convo = conversations.firstWhere(
        (c) =>
            c.type == 'private' &&
            c.participants.any((p) => p.id == otherUserId),
      );
      return convo.id;
    } catch (_) {
      return null;
    }
  }

  /// Forward an existing voice message (without re-uploading)
  Future<void> forwardVoiceMessage({
    required String audioUrl,
    required int audioDuration,
    required int conversationId,
    required int currentUserId,
  }) async {
    Loaders.show();
    // 1. Create Optimistic Message with remote URL
    final tempMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch,
      conversationId: conversationId,
      senderId: currentUserId,
      message: "Voice message", // Required by backend
      createdAt: DateTime.now(),
      isMe: true,
      type: 'voice',
      audioUrl: audioUrl, // Use the remote URL directly
      audioDuration: audioDuration,
      senderName: userProfile?.name ?? "Me",
      isRead: false,
      isDelivered: false,
    );
    // 2. Add to UI if in current conversation
    if (currentActiveConversationId == conversationId) {
      messages.insert(0, tempMessage);
    }
    // 3. Update conversation list
    final index = conversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      final old = conversations[index];
      final updatedConversation = ChatConversation(
        id: old.id,
        type: old.type,
        title: old.title,
        participants: old.participants,
        latestMessage: ChatLatestMessage(
          id: tempMessage.id,
          message: "🎤 Voice Message",
          type: 'voice',
          createdAt: DateTime.now(),
          userId: currentUserId,
          userName: userProfile?.name ?? "You",
        ),
        unreadCount: 0,
        updatedAt: DateTime.now(),
        isDefault: old.isDefault,
        image: old.image,
      );
      conversations
        ..removeAt(index)
        ..insert(0, updatedConversation);
    }
    notifyListeners();
    try {
      final url = Uri.parse(
        '${ApiRoutes.baseUrl}chat/conversations/$conversationId/messages',
      );
      // Download the remote file and re-upload it as multipart
      final fileResponse = await http.get(Uri.parse(audioUrl));
      if (fileResponse.statusCode != 200) {
        throw Exception("Failed to download voice file");
      }
      final request = http.MultipartRequest('POST', url);
      final headers = await apiHeaders();
      headers.remove('Content-Type'); // Let multipart set it
      request.headers.addAll(headers);
      request.fields['type'] = 'voice';
      request.fields['voice_duration'] = audioDuration.toString();
      // Add the downloaded file as multipart
      request.files.add(
        http.MultipartFile.fromBytes(
          'voice_file',
          fileResponse.bodyBytes,
          filename: 'forwarded_voice.mp3',
          contentType: MediaType('audio', 'mpeg'),
        ),
      );
      debugPrint("Forwarding voice message...");
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      debugPrint("Forward voice response: ${response.statusCode}");
      debugPrint("Forward voice response body: ${response.body}");
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        debugPrint("Forward voice data received: $data");
        if (data['success'] == true && data['data'] != null) {
          // Replace temp message with server response
          final realMessage = ChatMessage.fromJson(data['data'], currentUserId);
          debugPrint("Real message audioUrl: ${realMessage.audioUrl}");
          debugPrint("Real message type: ${realMessage.type}");
          debugPrint("Real message duration: ${realMessage.audioDuration}");
          debugPrint("Real message: ${data['data']}");
          final msgIndex = messages.indexWhere((m) => m.id == tempMessage.id);
          if (msgIndex != -1) {
            messages[msgIndex] = realMessage;
          }
        }
        showToast(message: "Voice message forwarded");
      } else {
        showToast(
          message: "Failed to forward voice message (${response.statusCode})",
        );
        messages.removeWhere((m) => m.id == tempMessage.id);
      }
    } catch (e) {
      debugPrint('Forward voice error: $e');
      messages.removeWhere((m) => m.id == tempMessage.id);
      showToast(message: "Error forwarding voice message");
    } finally {
      Loaders.hide();
    }

    notifyListeners();
  }

  // 1. Start Recording
  DateTime? _recordingStartTime; // 1. Add this variable to track start time
  Future<void> startVoiceRecording() async {
    try {
      // 2. Mark the start time
      _recordingStartTime = DateTime.now();
      await _voiceRecorder.start();
      isRecordingVoice = true;
      notifyListeners();
    } catch (e) {
      debugPrint("Error starting recorder: $e");
      isRecordingVoice = false;
      notifyListeners();
    }
  }

  Future<void> stopRecordingAndSend({
    required int conversationId,
    required int currentUserId,
  }) async {
    if (!isRecordingVoice) return;
    try {
      final path = await _voiceRecorder.stop();
      // 3. Calculate duration
      final startTime = _recordingStartTime ?? DateTime.now();
      final difference = DateTime.now().difference(startTime).inSeconds;
      // 4. Ensure minimum duration is 1 second (Backend Requirement)
      final duration = difference < 1 ? 1 : difference;
      isRecordingVoice = false;
      notifyListeners();
      if (path != null) {
        await sendVoiceMessage(
          filePath: path,
          duration: duration, // 5. Pass calculated duration
          conversationId: conversationId,
          currentUserId: currentUserId,
        );
      }
    } catch (e) {
      debugPrint("Error stopping recorder: $e");
      isRecordingVoice = false;
      notifyListeners();
    }
  }

  // 3. Cancel (Called when user slides to cancel)
  Future<void> cancelRecording() async {
    if (!isRecordingVoice) return;
    try {
      await _voiceRecorder.stop();
      // Optional: Delete the file here if your service saves it
    } catch (e) {
      debugPrint("Error canceling recorder: $e");
    } finally {
      isRecordingVoice = false;
      notifyListeners();
    }
  }

  Future<void> sendVoiceMessage({
    required String filePath,
    required int duration,
    required int conversationId,
    required int currentUserId,
  }) async {
    // 1. Create a Temporary "Optimistic" Message
    // We use the local file path so it plays immediately without downloading
    final tempId = DateTime.now().millisecondsSinceEpoch;
    final tempMessage = ChatMessage(
      id: tempId,
      conversationId: conversationId,
      senderId: currentUserId,
      message: "", // Voice messages usually have empty text
      createdAt: DateTime.now(),
      isMe: true,
      type: 'voice',
      audioUrl: filePath, // ✅ Use LOCAL path initially
      audioDuration: duration,
      senderName: userProfile?.name ?? "Me",
      isRead: false,
      isDelivered: false,
    );
    // 2. Insert into list immediately & Notify UI
    // messages.insert(0, tempMessage);
    if (currentActiveConversationId == conversationId) {
      messages.insert(0, tempMessage);
    }
    notifyListeners();
    try {
      final fileOnDisk = File(filePath);
      if (!await fileOnDisk.exists()) {
        debugPrint("Error: Voice file not found at $filePath");
        // Remove the temp message if file missing
        messages.removeWhere((m) => m.id == tempId);
        notifyListeners();
        return;
      }
      final url = Uri.parse(
        '${ApiRoutes.baseUrl}chat/conversations/$conversationId/messages',
      );
      final request = http.MultipartRequest('POST', url);
      final headers = await apiHeaders();
      headers.remove('Content-Type');
      request.headers.addAll(headers);
      request.fields['type'] = 'voice';
      request.fields['voice_duration'] = duration.toString();
      final multipartFile = await http.MultipartFile.fromPath(
        'voice_file',
        filePath,
        contentType: MediaType('audio', 'mp4'),
      );
      request.files.add(multipartFile);
      debugPrint("SENDING VOICE MESSAGE...");
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      debugPrint("SERVER RESPONSE: ${response.statusCode}");
      if (response.statusCode == 200 || response.statusCode == 201) {
        // 3. Success!
        // Ideally, parse the response to get the REAL server ID and remote URL.
        final data = jsonDecode(response.body);
        debugPrint("Voice upload response: $data");
        if (data['success'] == true && data['data'] != null) {
          // Parse the real message from server
          final realMessage = ChatMessage.fromJson(data['data'], currentUserId);
          debugPrint("Uploaded voice audioUrl: ${realMessage.audioUrl}");
          debugPrint("Uploaded voice type: ${realMessage.type}");
          // Find the temp message index
          final index = messages.indexWhere((m) => m.id == tempId);
          if (index != -1) {
            // Replace local file message with server URL message
            messages[index] = realMessage;
          }
        } else {
          // Fallback: Just fetch latest if parsing fails
          await fetchMessages(
            conversationId: conversationId.toString(),
            currentUserId: currentUserId,
          );
        }
      } else {
        // 4. Upload Failed: Remove the temp message so user knows it failed
        debugPrint("Upload failed");
        messages.removeWhere((m) => m.id == tempId);
        showToast(message: "Failed to send voice note");
      }
    } catch (e) {
      debugPrint('Voice send exception: $e');
      // Remove temp message on error
      messages.removeWhere((m) => m.id == tempId);
    }
    notifyListeners();
  }

  Future<void> editMessage({
    required int messageId,
    required String newMessage,
  }) async {
    Loaders.show();
    final index = messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      messages[index] = messages[index].copyWith(message: newMessage);
      notifyListeners();
    }
    try {
      final url = Uri.parse("${ApiRoutes.baseUrl}chat/messages/$messageId");
      debugPrint("Edit mesg url: $url");
      final res = await http.put(
        url,
        headers: await apiHeaders(),
        body: jsonEncode({"message": newMessage}),
      );
      debugPrint("Edit response: ${res.statusCode} - ${res.body}");
      if (res.statusCode == 200) {
        showToast(message: "Message edited successfully");
      } else {
        String backendMsg = "Unable to edit message";
        try {
          final decoded = jsonDecode(res.body);
          if (decoded is Map && decoded['message'] is String) {
            backendMsg = decoded['message'];
          }
        } catch (_) {}
        showToast(message: backendMsg);
        debugPrint("Failed to edit message");
      }
    } catch (e) {
      debugPrint("editMessage error: $e");
    } finally {
      Loaders.hide();
    }
  }

  Future<void> deleteMessage({
    required int messageId,
    required int conversationId,
  }) async {
    Loaders.show();
    final int index = messages.indexWhere((m) => m.id == messageId);
    ChatMessage? deletedMessage;
    if (index != -1) {
      deletedMessage = messages[index];
      messages.removeAt(index);
      notifyListeners();
    }
    try {
      final url = Uri.parse("${ApiRoutes.baseUrl}chat/messages/$messageId");
      final res = await http.delete(url, headers: await apiHeaders());
      debugPrint("Delete response: ${res.statusCode}");
      if (res.statusCode == 200 || res.statusCode == 204) {
        showToast(message: "Message deleted successfully");
      } else {
        if (deletedMessage != null && index != -1) {
          messages.insert(index, deletedMessage);
          notifyListeners();
          showToast(message: "Failed to delete message");
        }
      }
    } catch (e) {
      debugPrint("deleteMessage error: $e");
      // Revert on error
      if (deletedMessage != null && index != -1) {
        messages.insert(index, deletedMessage);
        notifyListeners();
      }
    } finally {
      Loaders.hide();
    }
  }

  /// ---------------- FETCH TWILIO NUMBERS ----------------
  Future<void> fetchTwilioNumbers() async {
    isTwilioLoading = true;
    twilioHasError = false;
    notifyListeners();
    try {
      final res = await http.get(
        Uri.parse("${ApiRoutes.baseUrl}${ApiRoutes.twilioNumbers}"),
        headers: await apiHeaders(),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> numbersData = data['data']['numbers'] ?? [];
          twilioNumbers = numbersData
              .map((json) => TwilioCredential.fromJson(json))
              .toList();
          twilioNumbersRevision++;
          isTwilioLoading = false;
          twilioHasError = false;
        } else {
          twilioHasError = true;
          isTwilioLoading = false;
          showToast(
            message: data['message'] ?? 'Failed to load Twilio numbers',
          );
        }
      } else {
        twilioHasError = true;
        isTwilioLoading = false;
        showToast(message: 'Error: ${res.statusCode}');
      }
    } catch (e) {
      twilioHasError = true;
      isTwilioLoading = false;
      showToast(message: 'Failed to fetch Twilio numbers');
      debugPrint('Error fetching Twilio numbers: $e');
    }
    notifyListeners();
  }

  /// ---------------- FETCH TWILIO CLIENTS WITH CONTACTS ----------------
  Future<void> fetchTwilioClientsWithContacts() async {
    isTwilioClientsLoading = true;
    twilioClientsHasError = false;
    notifyListeners();

    try {
      final res = await http.get(
        Uri.parse("${ApiRoutes.baseUrl}${ApiRoutes.twilioClientsWithContacts}"),
        headers: await apiHeaders(),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> clientsData = data['data']['clients'] ?? [];
          twilioClients = clientsData
              .map((json) => TwilioClient.fromJson(json))
              .toList();
          twilioClientsRevision++;
          isTwilioClientsLoading = false;
          twilioClientsHasError = false;
        } else {
          twilioClientsHasError = true;
          isTwilioClientsLoading = false;
          showToast(message: data['message'] ?? 'Failed to load clients');
        }
      } else {
        twilioClientsHasError = true;
        isTwilioClientsLoading = false;
        showToast(message: 'Error: ${res.statusCode}');
      }
    } catch (e) {
      twilioClientsHasError = true;
      isTwilioClientsLoading = false;
      showToast(message: 'Failed to fetch clients');
      debugPrint('Error fetching Twilio clients: $e');
    }
    notifyListeners();
  }

  /// ---------------- FETCH TWILIO STAFF (ASSIGNED ACCOUNTS) ----------------
  Future<void> fetchTwilioStaff() async {
    isTwilioStaffLoading = true;
    twilioStaffHasError = false;
    notifyListeners();

    try {
      final res = await http.get(
        Uri.parse("${ApiRoutes.baseUrl}${ApiRoutes.twilioStaff}"),
        headers: await apiHeaders(),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        debugPrint("data: $data");
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> staffData = data['data']['staff'] ?? [];
          twilioStaff = staffData
              .map((json) => AssignedAccount.fromJson(json))
              .toList();
          twilioStaffRevision++;
          debugPrint("twilioStaff: $twilioStaff");
          isTwilioStaffLoading = false;
          twilioStaffHasError = false;
        } else {
          twilioStaffHasError = true;
          isTwilioStaffLoading = false;
          showToast(message: data['message'] ?? 'Failed to load staff');
        }
      } else {
        twilioStaffHasError = true;
        isTwilioStaffLoading = false;
        showToast(message: 'Error: ${res.statusCode}');
      }
    } catch (e) {
      twilioStaffHasError = true;
      isTwilioStaffLoading = false;
      showToast(message: 'Failed to fetch staff');
      debugPrint('Error fetching twilio staff: $e');
    }
    notifyListeners();
  }

  /// ---------------- UPDATE TWILIO NUMBER ASSIGNMENTS ----------------
  Future<bool> updateTwilioNumberAssignments({
    required int numberId,
    required int? clientId,
    required List<int> contactIds,
    required List<int> accountIds,
  }) async {
    try {
      final url = Uri.parse(
        "${ApiRoutes.baseUrl}${ApiRoutes.twilioNumbers}/$numberId",
      );
      debugPrint('updating Twilio number: $url');
      final payload = {
        "client_id": clientId,
        "contact_ids": contactIds,
        "account_ids": accountIds,
      };
      debugPrint('updating Twilio payload: $payload');

      final res = await http.put(
        url,
        headers: await apiHeaders(),
        body: jsonEncode(payload),
      );
      debugPrint('updating Twilio body: ${res.body}');

      if (res.statusCode == 200 || res.statusCode == 204) {
        return true;
      }

      final data = jsonDecode(res.body);
      debugPrint('updating Twilio number: $data');
      showToast(message: data['message'] ?? 'Failed to update number');
      return false;
    } catch (e) {
      debugPrint('Error updating Twilio number: $e');
      showToast(message: 'Failed to update number');
      return false;
    }
  }
}
