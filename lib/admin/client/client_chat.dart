import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dart_pusher_channels/dart_pusher_channels.dart';

/// ================= CONFIG =================
const String serverHost = "myrta-volatilisable-eloisa.ngrok-free.dev";
const int serverPort = 443;
const String serverScheme = 'wss';

const String appKey = "8xK9mP2nL5qR7vW4jH6tY3bF1sD0gX8e";
const String apiBaseUrl = "https://myrta-volatilisable-eloisa.ngrok-free.dev";

/// ==========================================

class ClientChat extends StatefulWidget {
  final int clientId;
  final String authToken;

  const ClientChat({
    super.key,
    required this.clientId,
    required this.authToken,
  });

  @override
  State<ClientChat> createState() => _ClientChatState();
}

class _ClientChatState extends State<ClientChat> {
  final TextEditingController _messageCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  final List<ChatMessage> _messages = [];

  late PusherChannelsClient _client;
  late PrivateChannel _privateChannel;

  StreamSubscription? _connectionSub;
  StreamSubscription? _messageSub;

  @override
  void initState() {
    super.initState();
    _initPusher();
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _connectionSub?.cancel();
    _privateChannel.unsubscribe();
    _client.dispose();
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // =================================================
  // 🔌 INIT PUSHER (MATCHES PUB.DEV EXAMPLE)
  // =================================================
  void _initPusher() {
    PusherChannelsPackageLogger.enableLogs();

    final options = PusherChannelsOptions.fromHost(
      scheme: serverScheme,
      host: serverHost,
      port: serverPort,
      key: appKey,
      shouldSupplyMetadataQueries: true,
      metadata: PusherChannelsOptionsMetadata.byDefault(),
    );

    _client = PusherChannelsClient.websocket(
      options: options,
      connectionErrorHandler: (error, trace, refresh) {
        debugPrint("❌ Connection error: $error");
        refresh();
      },
    );

    // 🔐 CREATE PRIVATE CHANNEL (AUTH HERE)
    final channelName = "private-chat.${widget.clientId}";
    _privateChannel = _client.privateChannel(
      channelName,
      authorizationDelegate:
          EndpointAuthorizableChannelTokenAuthorizationDelegate.forPrivateChannel(
            authorizationEndpoint: Uri.parse("$apiBaseUrl/broadcasting/auth"),
            headers: {
              "Authorization": "Bearer ${widget.authToken}",
              "Accept": "application/json",
              "ngrok-skip-browser-warning": "true",
            },
          ),
    );

    // 🔁 Subscribe on connect (IMPORTANT)
    _connectionSub = _client.onConnectionEstablished.listen((_) {
      debugPrint("✅ Connected to Reverb");
      _privateChannel.subscribeIfNotUnsubscribed();
    });

    // 📩 Listen to messages
    _messageSub = _privateChannel.bind("new-message").listen((event) {
      final data = jsonDecode(event.data);

      setState(() {
        _messages.add(
          ChatMessage(
            message: data['message'] ?? '',
            isMe: false,
            time: data['time'] ?? '',
          ),
        );
      });

      _scrollToBottom();
    });

    // 🔌 Connect
    unawaited(_client.connect());
  }

  // =================================================
  // 📨 SEND MESSAGE (UI ONLY)
  // =================================================
  void _sendMessage() {
    if (_messageCtrl.text.trim().isEmpty) return;

    final msg = _messageCtrl.text.trim();

    setState(() {
      _messages.add(ChatMessage(message: msg, isMe: true, time: "Now"));
    });

    _messageCtrl.clear();
    _scrollToBottom();

    // 🔴 Call your Laravel API here
    // POST /api/send-message
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // =================================================
  // 🖥 UI
  // =================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Client Chat"),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(child: _chatList()),
          _chatInput(),
        ],
      ),
    );
  }

  Widget _chatList() {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.all(12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];

        return Align(
          alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(12),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: msg.isMe ? Colors.black : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  msg.message,
                  style: TextStyle(
                    color: msg.isMe ? Colors.white : Colors.black,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  msg.time,
                  style: TextStyle(
                    fontSize: 10,
                    color: msg.isMe ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _chatInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageCtrl,
              decoration: const InputDecoration(
                hintText: "Type message...",
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send, color: Colors.black),
          ),
        ],
      ),
    );
  }
}

/// ================= MODEL =================
class ChatMessage {
  final String message;
  final bool isMe;
  final String time;

  ChatMessage({required this.message, required this.isMe, required this.time});
}
