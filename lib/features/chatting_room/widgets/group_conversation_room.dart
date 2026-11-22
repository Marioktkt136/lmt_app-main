import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/services/native_media_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/app_preferences.dart';
import '../../../core/utils/device_file_helper.dart';
import '../../../core/widgets/lmt_empty_state.dart';
import '../cubit/chat_cubit.dart';
import '../sheets/chat_attachment_menu_sheet.dart';
import '../sheets/chat_message_actions_sheet.dart';
import '../sheets/chat_sticker_picker_sheet.dart';
import 'chat_message_bubble.dart';
import 'chat_typing_indicator.dart';
import 'conversation_composer_bar.dart';
import 'conversation_header_bar.dart';

/// Displays the active conversation room for a selected [ChatGroupModel].
///
/// - Always opens anchored at the latest message at the bottom (`reverse: true`).
/// - Displays an animated [ChatTypingIndicator] when typing is active.
class GroupConversationRoom extends StatefulWidget {
  /// The active chat group being viewed.
  final ChatGroupModel group;

  /// Callback invoked to return to the chat groups list.
  final VoidCallback onBack;

  /// Whether to render [ConversationHeaderBar] inline (false when hosted by
  /// [GroupConversationPage] which places it in `Scaffold.appBar`).
  final bool showInlineHeader;

  /// Creates a [GroupConversationRoom].
  const GroupConversationRoom({
    super.key,
    required this.group,
    required this.onBack,
    this.showInlineHeader = false,
  });

  @override
  State<GroupConversationRoom> createState() => _GroupConversationRoomState();
}

class _GroupConversationRoomState extends State<GroupConversationRoom> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  ChatMessageModel? _replyingTo;
  ChatMessageModel? _editingMessage;
  bool _isRecordingVoice = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  Timer? _typingHideTimer;
  bool _isTyping = false;
  String? _playingVoiceMessageId;
  List<String> _savedStickers = const [];

  @override
  void initState() {
    super.initState();
    _loadSavedStickers();
  }

  Future<void> _loadSavedStickers() async {
    final stickers = await AppPreferences.getSavedStickers();
    if (!mounted) return;
    setState(() => _savedStickers = stickers);
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _typingHideTimer?.cancel();
    NativeMediaService.stopVoiceNote();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleTextChanged(String value) {
    _typingHideTimer?.cancel();
    final hasText = value.trim().isNotEmpty;
    if (!hasText) {
      if (_isTyping) {
        setState(() => _isTyping = false);
      }
      return;
    }
    if (!_isTyping) {
      setState(() => _isTyping = true);
    }
    _typingHideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isTyping) {
        setState(() => _isTyping = false);
      }
    });
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendText() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _typingHideTimer?.cancel();
    final cubit = context.read<LmtCubit>();

    if (_editingMessage != null) {
      await cubit.editChatMessage(
        messageId: _editingMessage!.id,
        newContent: text,
      );
      setState(() {
        _isTyping = false;
        _editingMessage = null;
        _messageController.clear();
      });
      return;
    }

    await cubit.sendChatMessage(
      groupId: widget.group.id,
      type: MessageType.text,
      content: text,
      replyTo: _replyingTo,
    );

    setState(() {
      _isTyping = false;
      _replyingTo = null;
      _messageController.clear();
    });
    _scrollToLatest();
  }

  Future<void> _startVoiceNoteRecording() async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final granted = await NativeMediaService.requestMicrophonePermission();
    if (!mounted) return;

    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'يرجى السماح بإذن الميكروفون (Microphone Permission) لتسجيل الرسائل الصوتية 🎤'
                : 'Please grant Microphone permission to record voice notes 🎤',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await NativeMediaService.startVoiceRecording();
    if (!mounted) return;

    _recordingTimer?.cancel();
    setState(() {
      _isRecordingVoice = true;
      _recordingSeconds = 0;
    });

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _isRecordingVoice) {
        setState(() => _recordingSeconds++);
      }
    });
  }

  Future<void> _cancelVoiceNoteRecording() async {
    _recordingTimer?.cancel();
    await NativeMediaService.cancelVoiceRecording();
    if (!mounted) return;
    setState(() {
      _isRecordingVoice = false;
      _recordingSeconds = 0;
    });
  }

  Future<void> _sendVoiceNote() async {
    _recordingTimer?.cancel();
    final duration = _recordingSeconds > 0 ? _recordingSeconds : 1;
    final recordedFilePath = await NativeMediaService.stopVoiceRecording();
    if (!mounted) return;

    await context.read<LmtCubit>().sendChatMessage(
          groupId: widget.group.id,
          type: MessageType.voiceNote,
          content: 'رسالة صوتية مسجلة 🎤',
          attachmentPath: recordedFilePath,
          voiceDurationSeconds: duration,
          replyTo: _replyingTo,
        );
    setState(() {
      _isRecordingVoice = false;
      _recordingSeconds = 0;
      _replyingTo = null;
    });
    _scrollToLatest();
  }

  void _togglePlayVoiceNote(ChatMessageModel msg) {
    setState(() {
      if (_playingVoiceMessageId == msg.id) {
        _playingVoiceMessageId = null;
      } else {
        _playingVoiceMessageId = msg.id;
      }
    });
  }

  void _openStickersSheet() {
    showChatStickerPickerSheet(
      context: context,
      groupId: widget.group.id,
      initialSavedStickers: _savedStickers,
      onStickersUpdated: (updated) {
        if (mounted) setState(() => _savedStickers = updated);
      },
      replyTo: _replyingTo,
      onStickerSent: () {
        if (mounted) setState(() => _replyingTo = null);
        _scrollToLatest();
      },
    );
  }

  Future<void> _captureCameraAndSend() async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final picked = await DeviceFileHelper.capturePhotoFromCamera(context);
    if (!mounted || picked == null || picked.path == null) return;

    final cubit = context.read<LmtCubit>();
    final savedPath = await DeviceFileHelper.persistPickedFile(
      picked.path!,
      picked.name,
    );
    await cubit.sendChatMessage(
      groupId: widget.group.id,
      type: MessageType.image,
      content: '',
      attachmentPath: savedPath,
      fileSize: DeviceFileHelper.formatBytes(picked.size),
      replyTo: _replyingTo,
    );
    if (!mounted) return;
    setState(() => _replyingTo = null);
    _scrollToLatest();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isArabic ? 'تم التقاط وإرسال الصورة 📷✅' : 'Photo captured & sent 📷✅',
        ),
        backgroundColor: AppColors.accentGreenOf(context),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveStickerMessage(ChatMessageModel msg) async {
    final path = msg.attachmentPath?.trim();
    if (path == null || path.isEmpty) return;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    if (!_savedStickers.contains(path)) {
      final updated = [path, ..._savedStickers];
      await AppPreferences.setSavedStickers(updated);
      if (mounted) {
        setState(() => _savedStickers = updated);
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isArabic
              ? 'تم حفظ الملصق في ملصقاتك المحفوظة ⭐'
              : 'Sticker saved to your Saved Stickers ⭐',
        ),
        backgroundColor: AppColors.accentGreenOf(context),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LmtCubit, LmtState>(
      builder: (context, state) {
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        final messages = state.messagesForGroup(widget.group.id);

        return Column(
          children: [
            if (widget.showInlineHeader) ...[
              ConversationHeaderBar(
                group: widget.group,
                state: state,
                onBack: widget.onBack,
              ),
              SizedBox(height: 8.h),
            ],
            Expanded(
              child: messages.isEmpty
                  ? LmtEmptyState(
                      icon: Icons.chat_bubble_outline_rounded,
                      message: isArabic
                          ? 'ابدأ المحادثة الآن في ${widget.group.name}'
                          : 'Start chatting in ${widget.group.name}',
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[messages.length - 1 - index];
                        final isMe = msg.senderId == state.currentUser.id;

                        return ChatMessageBubble(
                          msg: msg,
                          isMe: isMe,
                          isPlayingVoice: _playingVoiceMessageId == msg.id,
                          onShowActions: () => showChatMessageActionsSheet(
                            context: context,
                            state: state,
                            group: widget.group,
                            message: msg,
                            onSaveSticker: _saveStickerMessage,
                            onReply: (target) => setState(() {
                              _replyingTo = target;
                              _editingMessage = null;
                            }),
                            onEdit: (target) => setState(() {
                              _editingMessage = target;
                              _replyingTo = null;
                              _messageController.text = target.content;
                            }),
                          ),
                          onShowSeenBy: () => showChatSeenBySheet(context, msg),
                          onToggleReaction: (emoji) => context
                              .read<LmtCubit>()
                              .toggleMessageReaction(
                                messageId: msg.id,
                                emoji: emoji,
                              ),
                          onToggleVoicePlay: () => _togglePlayVoiceNote(msg),
                          onReply: (target) => setState(() {
                            _replyingTo = target;
                            _editingMessage = null;
                          }),
                          onSaveSticker: _saveStickerMessage,
                        );
                      },
                    ),
            ),
            if (_isTyping)
              ChatTypingIndicator(
                typingUserName: state.currentUser.name,
                avatarPath: state.currentUser.avatarPath,
              ),
            ReplyEditBanner(
              replyingTo: _replyingTo,
              editingMessage: _editingMessage,
              onCancel: () => setState(() {
                _replyingTo = null;
                _editingMessage = null;
                _isTyping = false;
                _messageController.clear();
              }),
            ),
            if (_isRecordingVoice)
              VoiceRecordingBar(
                recordingSeconds: _recordingSeconds,
                onCancel: _cancelVoiceNoteRecording,
                onSend: _sendVoiceNote,
              )
            else
              ConversationComposerBar(
                messageController: _messageController,
                onChanged: _handleTextChanged,
                onOpenAttachments: () => showChatAttachmentMenuSheet(
                  context: context,
                  groupId: widget.group.id,
                  replyTo: _replyingTo,
                  onMessageSent: () {
                    if (mounted) setState(() => _replyingTo = null);
                    _scrollToLatest();
                  },
                ),
                onOpenStickers: _openStickersSheet,
                onCaptureCamera: _captureCameraAndSend,
                onStartVoiceRecording: _startVoiceNoteRecording,
                onSendText: _handleSendText,
              ),
          ],
        );
      },
    );
  }
}
