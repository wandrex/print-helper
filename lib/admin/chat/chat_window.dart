import 'dart:async';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:print_helper/admin/chat/chat_profile.dart';
import 'package:print_helper/admin/chat/groupchat/edit_group.dart';
import 'package:print_helper/providers/auth_pro.dart';
import 'package:print_helper/services/helpers.dart';
import 'package:print_helper/widgets/image_widget.dart';
import 'package:provider/provider.dart';

import '../../constants/colors.dart';
import '../../constants/paths.dart';
import '../../models/chat_models.dart';
import '../../providers/chat_pro.dart';
import '../../widgets/loaders.dart';
import '../../widgets/spacers.dart';
import '../../widgets/text_widget.dart';
import '../../widgets/toasts.dart';
import '../../widgets/typing_dots.dart';
import 'components/mesg_forward_sheet.dart';
import 'components/mesg_options_dialog.dart';
import 'components/voice_mesg_bubble.dart';

class ChatScreen extends StatefulWidget {
  final int? conversationId;
  final int receiverUserId;
  final String title;
  const ChatScreen({
    super.key,
    this.conversationId,
    required this.title,
    required this.receiverUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  Timer? _recordTimer;
  Duration _recordDuration = Duration.zero;
  double _cancelSliderOffset = 0.0;
  ChatMessage? _editingMessage;
  final _messageCtrl = TextEditingController();
  bool isSmsSelected = false;
  String? currentVisibleDate;
  bool _showEmojiPicker = false;
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _groupOverlay;
  String selectedSmsNumber = "(323) 000-0000";
  final _scrollCtrl = ScrollController();
  static const double _inputAreaHeight = 20;
  late ChatPro _chatPro;
  final List<String> smsNumbers = [
    "(323) 000-0000",
    "(323) 808-4052",
    "(415) 123-4567",
  ];
  void _startEditing(ChatMessage msg) {
    setState(() {
      _editingMessage = msg;
      _messageCtrl.text = msg.message; // Pre-fill input
    });
    // Slight delay to focus input
    Future.delayed(Duration(milliseconds: 50), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  // 3. HELPER TO CANCEL EDITING
  void _cancelEditing() {
    setState(() {
      _editingMessage = null;
      _messageCtrl.clear();
    });
    _focusNode.unfocus();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final pro = getChatPro(context);
      final authpro = getAuthPro(context);
      pro.isChatScreenOpen = true;
      pro.reset();
      // NEW CHAT (no conversation yet)
      if (widget.conversationId == null) {
        return; // Do NOT fetch messages or init socket
      }
      // Ensure we are at 0 (bottom) before adding listener
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(0.0);
      }
      // Fetch initial data
      await _getChatMessages(pro, authpro);
      // Add listener AFTER initial fetch to prevent premature triggers
      _scrollCtrl.addListener(_onScroll);
      await pro.initConversationSocket(
        conversationId: widget.conversationId!,
        currentUserId: authpro.user!.id,
      );
    });
  }

  Future<void> _getChatMessages(ChatPro pro, AuthPro authpro) async {
    await pro.fetchMessages(
      conversationId: widget.conversationId.toString(),
      currentUserId: authpro.user!.id,
    );
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 100) {
      final pro = getChatPro(context);
      final auth = getAuthPro(context);
      // For reverse list, first visible item = messages[0]
      final firstMsg = pro.messages.isNotEmpty ? pro.messages[0] : null;
      if (firstMsg != null) {
        final label = chatDateLabel(firstMsg.createdAt);
        if (label != currentVisibleDate) {
          setState(() {
            currentVisibleDate = label;
          });
        }
      }
      if (!pro.isLoadingMore && pro.hasMore) {
        pro.fetchMessages(
          conversationId: widget.conversationId.toString(),
          currentUserId: auth.user!.id,
          loadMore: true,
        );
      }
    }
  }

  Future<void> _initScrollToBottom() async {
    if (!_scrollCtrl.hasClients) return;
    _scrollCtrl.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.decelerate,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Save the provider reference without listening
    _chatPro = Provider.of<ChatPro>(context, listen: false);
  }

  @override
  void dispose() {
    // 3. Use the SAVED reference (_chatPro), NOT context
    // _chatPro.disconnectConversationSocket();
    if (widget.conversationId != null) {
      _chatPro.disconnectConversationSocket();
    }
    _chatPro.isChatScreenOpen = false;
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _messageCtrl.dispose();
    _recordTimer?.cancel();
    super.dispose();
  }

  void _startRecordTimer() {
    _recordTimer?.cancel();
    setState(() {
      _recordDuration = Duration.zero;
      _cancelSliderOffset = 0.0;
    });
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordDuration = Duration(seconds: timer.tick);
      });
    });
  }

  void _stopRecordTimer() {
    _recordTimer?.cancel();
    setState(() {
      _recordDuration = Duration.zero;
      _cancelSliderOffset = 0.0;
    });
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ImageWidget(image: Paths.chtbg, fit: BoxFit.cover),
        ),
        Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: Colors.transparent,
          appBar: _appBar(context),
          body: Consumer<ChatPro>(
            builder: (context, pro, _) {
              return Column(
                children: [
                  Expanded(
                    child: Consumer<ChatPro>(
                      builder: (context, pro, _) {
                        final loadMore = pro.isLoadingMore;
                        return ListView.builder(
                          controller: _scrollCtrl,
                          reverse: true,
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            12.w,
                            12.w,
                            12.w,
                            _inputAreaHeight +
                                MediaQuery.of(context).viewInsets.bottom +
                                2,
                          ),
                          itemCount: pro.messages.length + (loadMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            /// 🔄 Loader appears at TOP (because reverse = true)
                            if (loadMore && index == pro.messages.length) {
                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: Center(child: showLoader()),
                              );
                            }
                            if (index >= pro.messages.length) {
                              return const SizedBox.shrink();
                            }
                            final msg = pro.messages[index];
                            bool showHeader = false;
                            final isLast = index == pro.messages.length - 1;
                            if (isLast) {
                              showHeader = true;
                            } else {
                              final nextMsg = pro.messages[index + 1];
                              final currDate = DateTime(
                                msg.createdAt.year,
                                msg.createdAt.month,
                                msg.createdAt.day,
                              );
                              final nextDate = DateTime(
                                nextMsg.createdAt.year,
                                nextMsg.createdAt.month,
                                nextMsg.createdAt.day,
                              );
                              if (currDate != nextDate) showHeader = true;
                            }
                            return Column(
                              children: [
                                if (showHeader) _dateHeader(msg.createdAt),
                                _messageRow(msg),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          bottomNavigationBar: AnimatedPadding(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SafeArea(
              child: Consumer<ChatPro>(
                builder: (context, pro, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (pro.isOtherUserTyping)
                        Padding(
                          padding: EdgeInsets.only(left: 12.w, bottom: 6.h),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                TextWidget(
                                  text: "Typing",
                                  textAlign: TextAlign.center,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                                TypingBubbleWave(),
                              ],
                            ),
                          ),
                        ),
                      _channelSelector(),
                      _inputBar(),
                      if (_showEmojiPicker)
                        SizedBox(
                          height: 280,
                          child: EmojiPicker(
                            onEmojiSelected: (category, emoji) {
                              _messageCtrl.text += emoji.emoji;
                              _messageCtrl
                                  .selection = TextSelection.fromPosition(
                                TextPosition(offset: _messageCtrl.text.length),
                              );
                            },
                            config: Config(
                              height: 280,
                              emojiViewConfig: EmojiViewConfig(
                                emojiSizeMax: 28,
                              ),
                              skinToneConfig: SkinToneConfig(),
                              categoryViewConfig: CategoryViewConfig(
                                indicatorColor: const Color(0xffFFC107),
                                iconColor: Colors.grey,
                                iconColorSelected: const Color(0xffFFC107),
                              ),
                              bottomActionBarConfig: BottomActionBarConfig(
                                enabled: false,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dateHeader(DateTime dt) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.w),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: TextWidget(
            text: chatDateLabel(dt),
            color: Colors.black54,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _inputBar() {
    final isRecording = context.watch<ChatPro>().isRecordingVoice;
    return SafeArea(
      minimum: EdgeInsets.only(bottom: 10.h),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.black, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_editingMessage != null) _editingBanner(),
                  TextField(
                    controller: _messageCtrl,
                    focusNode: _focusNode,
                    minLines: 1,
                    maxLines: 4,
                    onTap: () {
                      setState(() => _showEmojiPicker = false);
                    },
                    onChanged: (text) {
                      if (widget.conversationId == null) return;
                      context.read<ChatPro>().onTextTyping(
                        conversationId: widget.conversationId!,
                        text: text,
                      );
                    },
                    decoration: InputDecoration(
                      hintText: isSmsSelected
                          ? "Type your SMS… (Carrier charges may apply)"
                          : "Type your Message",
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1, thickness: 1, color: Colors.black12),
                  const SizedBox(height: 8),
                  inputKeys(isRecording),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editingBanner() {
    return Container(
      margin: EdgeInsets.only(bottom: 6.h),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8.r),
        border: const Border(
          left: BorderSide(color: AppColors.primary, width: 4),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidget(
                  text: "Editing message",
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
                Spacers.sb2(),
                TextWidget(
                  text: _editingMessage!.message,
                  maxLines: 1,
                  fontWeight: FontWeight.w400,
                  overflow: TextOverflow.ellipsis,
                  fontSize: 11,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _cancelEditing,
            child: Icon(Icons.close, size: 18.sp),
          ),
        ],
      ),
    );
  }

  Row inputKeys(bool isRecording) {
    return Row(
      children: [
        if (isRecording)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Text(
              _formatDuration(_recordDuration),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          )
        else
          _actionIcon(icon: Icons.add_circle_outline_sharp, onTap: () {}),
        Spacers.sbw12(),
        GestureDetector(
          key: const ValueKey('mic_btn'),
          onLongPress: () {
            if (widget.conversationId == null) {
              return; // Prevent recording if no chat exists yet
            }
            context
                .read<ChatPro>()
                .startVoiceRecording(); // Changed from startDummy
            _startRecordTimer();
          },
          onLongPressMoveUpdate: (details) {
            // HANDLING SLIDE TO CANCEL
            if (details.offsetFromOrigin.dx < 0) {
              // Check direction (usually left on RTL, right on LTR)
              // Adjust logic based on your swipe direction preference
              // Your original code used dx > 0 for right swipe
              setState(() {
                _cancelSliderOffset = details.offsetFromOrigin.dx;
              });
            }
            // Example: If dragged more than 150px
            if (details.offsetFromOrigin.dx.abs() > 150) {
              context.read<ChatPro>().cancelRecording(); // Cancel logic
              _stopRecordTimer();
            }
          },
          onLongPressEnd: (details) {
            final pro = context.read<ChatPro>();
            final auth = context.read<AuthPro>();
            // 1. Check if cancelled via slider
            if (_cancelSliderOffset.abs() > 150) {
              pro.cancelRecording();
            }
            // 2. Check if recording was too short (optional usability fix)
            else if (_recordDuration.inSeconds < 1) {
              showToast(message: "Message too short");
              pro.cancelRecording();
            }
            // 3. SEND MESSAGE
            else {
              if (widget.conversationId != null && auth.user != null) {
                pro.stopRecordingAndSend(
                  conversationId: widget.conversationId!,
                  currentUserId: auth.user!.id,
                );
              } else {
                pro.cancelRecording();
              }
            }
            _stopRecordTimer();
          },
          child: AnimatedScale(
            scale: isRecording ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isRecording ? Icons.mic : Icons.mic_none,
              color: isRecording ? Colors.red : Colors.black,
              size: 24, // Original size
            ),
          ),
        ),
        Spacers.sbw12(),
        if (isRecording)
          Expanded(
            child: Opacity(
              opacity: (_cancelSliderOffset > 50) ? 0.5 : 1.0,
              child: Row(
                children: [
                  TextWidget(
                    text: "Slide right to cancel",
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                  const SizedBox(width: 4),
                  Transform.translate(
                    offset: Offset(
                      _cancelSliderOffset > 0 ? _cancelSliderOffset : 0,
                      0,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          _actionIcon(
            icon: CupertinoIcons.smiley,
            onTap: () {
              FocusScope.of(context).unfocus();
              setState(() {
                _showEmojiPicker = !_showEmojiPicker;
              });
            },
          ),
          Spacers.sbw12(),
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xffFFC107), width: 1.5),
            ),
            child: const Text(
              "+ Project",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              if (_editingMessage != null) {
                _onEditSubmit();
              } else {
                _onSendPressed();
              }
            },
            child: Container(
              height: 35,
              width: 35,
              decoration: const BoxDecoration(
                color: Color(0xffFFC107),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, size: 20, color: Colors.white),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _onEditSubmit() async {
    final newText = _messageCtrl.text.trim();
    if (newText.isEmpty || _editingMessage == null) return;
    final msgId = _editingMessage!.id;
    await context.read<ChatPro>().editMessage(
      messageId: msgId,
      newMessage: newText,
    );
    _cancelEditing();
  }

  // void _onSendPressed() async {
  //   final text = _messageCtrl.text.trim();
  //   if (text.isEmpty) return;
  //   setState(() => _showEmojiPicker = false);
  //   _focusNode.requestFocus();
  //   final pro = getChatPro(context);
  //   final authpro = getAuthPro(context);
  //   int? conversationId = widget.conversationId;
  //   // STEP 1: If no conversationId yet, check existing history
  //   // if conversationId == null
  //   conversationId ??= pro.findPrivateConversationWithUser(
  //     widget.receiverUserId,
  //   );
  //   // STEP 2: Still no conversation → create it
  //   if (conversationId == null) {
  //     conversationId = await pro.createConvId(
  //       type: 'private', // for non group
  //       userIds: [widget.receiverUserId],
  //       context: context,
  //     );
  //     if (conversationId == null) return;
  //   }
  //   _messageCtrl.clear();
  //   // STEP 3: Send message (ONLY ONCE)
  //   await pro.sendMessage(
  //     text: text,
  //     conversationId: conversationId,
  //     currentUserId: authpro.user!.id,
  //   );
  //   _initScrollToBottom();
  // }

  void _onSendPressed() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _showEmojiPicker = false);
    _focusNode.requestFocus();
    final pro = getChatPro(context);
    final authpro = getAuthPro(context);
    int? conversationId = widget.conversationId;
    // STEP 1: If no conversationId yet, check existing history or create new
    if (conversationId == null) {
      conversationId = pro.findPrivateConversationWithUser(
        widget.receiverUserId,
      );
      // Still no conversation → create it
      if (conversationId == null) {
        conversationId = await pro.createConvId(
          type: 'private',
          userIds: [widget.receiverUserId],
          context: context,
        );
        // IMPORTANT: If we just created the ID, we MUST initialize the socket!
        // This sets 'currentActiveConversationId' in the provider
        if (conversationId != null) {
          await pro.initConversationSocket(
            conversationId: conversationId,
            currentUserId: authpro.user!.id,
          );
        }
      }
    }
    if (conversationId == null) return;
    _messageCtrl.clear();
    // STEP 2: Send message (Now safe because socket is initialized)
    await pro.sendMessage(
      text: text,
      conversationId: conversationId,
      currentUserId: authpro.user!.id,
    );
    _initScrollToBottom();
  }

  Widget _channelSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            setState(() => isSmsSelected = false);
          },
          child: Container(
            height: 32,
            padding: EdgeInsets.symmetric(horizontal: 18.w),
            decoration: BoxDecoration(
              color: !isSmsSelected ? Color(0xff231f20) : Color(0xffd1d3d4),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
              ),
            ),
            child: Center(
              child: TextWidget(
                text: "App Chat",
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Spacers.sbw8(),
        PopupMenuButton<String>(
          onSelected: (value) {
            setState(() {
              isSmsSelected = true;
              selectedSmsNumber = value;
            });
          },
          itemBuilder: (context) {
            return smsNumbers
                .map(
                  (n) => PopupMenuItem(
                    value: n,
                    child: Text(n, style: const TextStyle(fontSize: 13)),
                  ),
                )
                .toList();
          },
          color: Colors.white,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Container(
            height: 32,
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            decoration: BoxDecoration(
              color: isSmsSelected ? Color(0xff231f20) : Color(0xffd1d3d4),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextWidget(
                  text: "SMS Text ",
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isSmsSelected ? Colors.white : Colors.black,
                ),
                Spacers.sbw2(),
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(9.r),
                  ),
                  child: Row(
                    children: [
                      TextWidget(
                        text: selectedSmsNumber,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                      Spacers.sbw5(),
                      ImageWidget(
                        image: Paths.down,
                        width: 10,
                        color: Colors.grey,
                      ),
                      Spacers.sbw5(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionIcon({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, size: 20.sp, color: Colors.black),
    );
  }

  String _appBarSubtitle(BuildContext context) {
    final pro = getChatPro(context);
    final convo = pro.conversations.firstWhere(
      (c) => c.id == widget.conversationId,
      orElse: () => ChatConversation(
        id: -1,
        type: 'private',
        title: widget.title,
        participants: [],
        latestMessage: null,
        image: '',
        unreadCount: 0,
        updatedAt: DateTime.now(),
        isDefault: true,
      ),
    );
    if (convo.type == 'group') {
      return "${convo.participants.length} members";
    }
    return "New chat";
  }

  PreferredSizeWidget _appBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      surfaceTintColor: Colors.white,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: AppColors.black,
          size: 25,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: GestureDetector(
        onTap: () {
          if (widget.conversationId == null) return;
          final convo = getChatPro(
            context,
          ).conversations.firstWhere((c) => c.id == widget.conversationId);
          // final convo = getChatPro(
          //   context,
          // ).conversations.firstWhere((c) => c.id == widget.conversationId);
          if (convo.type == 'group') {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              barrierColor: Colors.black.withValues(alpha: .25),
              builder: (_) => FractionallySizedBox(
                heightFactor: .98,
                child: EditChatGroup(conversationId: convo.id),
              ),
            );
          } else {
            navTo(
              context: context,
              page: ProfileDetails(id: convo.participants[0].id.toString()),
            );
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Consumer<ChatPro>(
              builder: (context, pro, _) {
                // NEW CHAT SAFE HANDLING
                if (widget.conversationId == null) {
                  return TextWidget(
                    text: widget.title,
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  );
                }
                final convo = pro.conversations.firstWhere(
                  (c) => c.id == widget.conversationId,
                  orElse: () => ChatConversation(
                    id: -1, // ✅ SAFE
                    type: 'private',
                    title: widget.title,
                    participants: const [],
                    latestMessage: null,
                    image: '',
                    unreadCount: 0,
                    updatedAt: DateTime.now(),
                    isDefault: true,
                  ),
                );

                return TextWidget(
                  text: convo.title,
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                );
              },
            ),

            Spacers.sb2(),
            Consumer<ChatPro>(
              builder: (context, _, _) {
                return TextWidget(
                  text: _appBarSubtitle(context),
                  color: Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: ImageIcon(
            AssetImage(Paths.vc),
            color: AppColors.black,
            size: 30,
          ),
          onPressed: () {},
        ),
        IconButton(
          icon: ImageIcon(
            AssetImage(Paths.call),
            color: AppColors.black,
            size: 23,
          ),
          onPressed: () {},
        ),
        _groupInfoAction(),
        IconButton(
          icon: Icon(
            CupertinoIcons.search,
            color: AppColors.black.withValues(alpha: 0.8),
            size: 29,
            weight: 400,
          ),
          onPressed: () {},
        ),
        Spacers.sbw5(),
      ],
    );
  }

  Widget _groupInfoAction() {
    if (widget.conversationId == null) return const SizedBox.shrink();
    return Consumer<ChatPro>(
      builder: (context, pro, _) {
        final convo = pro.conversations.firstWhere(
          (c) => c.id == widget.conversationId,
          orElse: () => ChatConversation(
            id: -1,
            type: 'private',
            title: '',
            participants: const [],
            latestMessage: null,
            image: '',
            unreadCount: 0,
            updatedAt: DateTime.now(),
            isDefault: true,
          ),
        );
        if (convo.type != 'group') return const SizedBox.shrink();
        return IconButton(
          icon: const Icon(Icons.info_outline, size: 29),
          onPressed: () => _showGroupInfoPopup(convo),
        );
      },
    );
  }

  Widget _messageRow(ChatMessage msg) {
    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: msg.isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!msg.isMe)
            Padding(
              padding: EdgeInsets.only(right: 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50.r),
                child: ImageWidget(
                  image: msg.senderAvatar != null
                      ? msg.senderAvatar!
                      : Paths.user,
                  height: 35,
                  width: 35,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: _bubble(msg),
            ),
          ),
          Builder(
            builder: (iconCtx) {
              return GestureDetector(
                onTap: () {
                  final RenderBox box = iconCtx.findRenderObject() as RenderBox;
                  final Offset pos = box.localToGlobal(Offset.zero);
                  final Size size = box.size;
                  showMessageOptionsDialog(
                    context: context,
                    position: pos,
                    size: size,
                    msg: msg,
                    onEdit: () {
                      _startEditing(msg);
                    },
                    onForward: () {
                      _showForwardPopup(msg);
                    },
                    onDelete: () async {
                      _deletePopup(msg);
                    },
                  );
                },

                child: Container(
                  width: 30.w,
                  height: 30.h,
                  margin: EdgeInsets.only(left: 8.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13.r),
                    border: Border.all(color: Colors.grey, width: 1),
                  ),
                  child: Icon(Icons.more_vert, size: 20.sp),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<dynamic> _deletePopup(ChatMessage msg) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        title: TextWidget(
          text: "Delete Message?",
          color: Colors.black,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.none,
        ),
        content: TextWidget(
          text: "Are you sure you want to delete this message?",
          color: Colors.black,
          fontSize: 13,
          fontWeight: FontWeight.w400,
          decoration: TextDecoration.none,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: TextWidget(
              text: "Cancel",
              color: Colors.grey,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await getChatPro(context).deleteMessage(
                messageId: msg.id,
                conversationId: msg.conversationId,
              );
            },
            child: TextWidget(
              text: "Delete",
              color: Colors.red,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(ChatMessage msg) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: msg.isMe ? Colors.white : AppColors.primary,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sender name (group chat)
          if (!msg.isMe && msg.senderName != null)
            Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: TextWidget(
                text: msg.senderName!,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          if (msg.type == 'voice' && msg.audioUrl != null)
            VoiceMessageBubbleUI(
              path: msg.audioUrl!,
              duration: msg.audioDuration ?? 0,
              isMe: msg.isMe,
            ),
          if (msg.type != 'voice')
            TextWidget(
              text: msg.message,
              fontSize: 13,
              color: Colors.black,
              fontWeight: FontWeight.w400,
            ),
          SizedBox(height: 4.h),
          // Time + ticks
          _metaRow(msg),
        ],
      ),
    );
  }

  String formatMessageTime(String dateTime) {
    final dt = DateTime.parse(dateTime);
    return DateFormat("dd/MM/yyyy • h:mma").format(dt).toLowerCase();
  }

  Widget _metaRow(ChatMessage msg) {
    Color iconColor = Colors.grey;
    IconData iconData = Icons.done;
    if (msg.isRead == true) {
      iconData = Icons.done_all;
      iconColor = Colors.blue;
    } else if (msg.isDelivered == true) {
      iconData = Icons.done_all;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextWidget(
          text: 'APP Chat • ${formatMessageTime(msg.createdAt.toString())}',
          fontSize: 10,
          color: Colors.black54,
          fontWeight: FontWeight.w400,
          overflow: TextOverflow.ellipsis,
        ),
        if (msg.isMe) ...[
          SizedBox(width: 4.w),
          Icon(iconData, size: 14.sp, color: iconColor),
        ],
      ],
    );
  }

  Widget imageMessage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: Center(
        child: ImageWidget(
          image: "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e",
          height: 160,
          width: 160,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  void _showGroupInfoPopup(ChatConversation convo) {
    if (_groupOverlay != null) return;
    _groupOverlay = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            GestureDetector(
              onTap: _hideGroupInfoPopup,
              child: Container(color: Colors.black.withValues(alpha: 0.35)),
            ),
            Positioned(
              top: kToolbarHeight + MediaQuery.of(context).padding.top + 5,
              right: 14,
              child: _groupInfoCard(convo),
            ),
          ],
        );
      },
    );
    Overlay.of(context).insert(_groupOverlay!);
  }

  void _hideGroupInfoPopup() {
    _groupOverlay?.remove();
    _groupOverlay = null;
  }

  Widget _groupInfoCard(ChatConversation convo) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 300.w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22.r),
          boxShadow: [
            BoxShadow(
              blurRadius: 22,
              color: Colors.black.withValues(alpha: 0.15),
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 20.sp),
                      Spacers.sbw5(),
                      TextWidget(
                        text: "Group Info",
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _hideGroupInfoPopup,
                    child: Icon(Icons.close, size: 20.sp),
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: convo.participants.length,
              itemBuilder: (_, i) {
                final user = convo.participants[i];
                return Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 6.w,
                    horizontal: 16.w,
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(50.r),
                        child: ImageWidget(
                          image: user.image != null ? user.image! : Paths.user,
                          height: 35,
                          width: 35,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Spacers.sbw10(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextWidget(
                            text: user.name,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          TextWidget(
                            text: "@${user.username}",
                            color: Colors.grey,
                            fontSize: 12,
                            maxLines: 1,
                            fontWeight: FontWeight.w500,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            Spacers.sb10(),
          ],
        ),
      ),
    );
  }

  void _showForwardPopup(ChatMessage msg) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Important for rounded corners
      builder: (_) => ForwardMessageSheet(messageToForward: msg),
    );
  }

  String chatDateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(msgDay).inDays;
    if (diff == 0) return "Today";
    if (diff == 1) return "Yesterday";
    // Else: Format like WhatsApp
    return DateFormat("d MMM yyyy").format(dt);
  }
}
