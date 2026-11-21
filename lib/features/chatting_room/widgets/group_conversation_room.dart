import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:material_ui/material_ui.dart';

import '../cubit/chat_cubit.dart';
import '../../../core/models/lmt_models.dart';
import '../../../core/services/native_media_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/app_assets.dart';
import '../../../core/utils/app_preferences.dart';
import '../../../core/utils/device_file_helper.dart';
import '../../../core/widgets/lmt_avatar.dart';
import '../../../core/widgets/lmt_card.dart';
import '../../../core/widgets/lmt_empty_state.dart';
import 'chat_message_bubble.dart';

/// Displays the active conversation room for a selected [ChatGroupModel].
///
/// Always opens anchored at the latest message at the bottom (`reverse: true`).
class GroupConversationRoom extends StatefulWidget {
  /// The active chat group being viewed.
  final ChatGroupModel group;

  /// Callback invoked to return to the chat groups list.
  final VoidCallback onBack;

  /// Creates a [GroupConversationRoom].
  const GroupConversationRoom({
    super.key,
    required this.group,
    required this.onBack,
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
  Timer? _playbackTimer;
  String? _playingVoiceMessageId;
  List<String> _savedStickers = const [];

  static const List<String> _quickEmojis = [
    '❤️',
    '👍',
    '🔥',
    '👏',
    '😂',
    '😮',
    '😢',
    '🙏',
    '🎭',
    '🎬',
    '✨',
    '💯',
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedStickers();
  }

  Future<void> _loadSavedStickers() async {
    final stickers = await AppPreferences.getSavedStickers();
    if (!mounted) return;
    setState(() {
      _savedStickers = stickers;
    });
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _playbackTimer?.cancel();
    NativeMediaService.stopVoiceNote();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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

    final cubit = context.read<LmtCubit>();

    if (_editingMessage != null) {
      await cubit.editChatMessage(
        messageId: _editingMessage!.id,
        newContent: text,
      );
      setState(() {
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
        setState(() {
          _recordingSeconds++;
        });
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

  Future<void> _togglePlayVoiceNote(ChatMessageModel msg) async {
    _playbackTimer?.cancel();
    if (_playingVoiceMessageId == msg.id) {
      await NativeMediaService.stopVoiceNote();
      if (!mounted) return;
      setState(() => _playingVoiceMessageId = null);
      return;
    }

    await NativeMediaService.stopVoiceNote();
    if (msg.attachmentPath != null && msg.attachmentPath!.isNotEmpty) {
      await NativeMediaService.playVoiceNote(msg.attachmentPath!);
    }

    if (!mounted) return;
    setState(() => _playingVoiceMessageId = msg.id);

    final durationSec = msg.voiceDurationSeconds ?? 15;
    _playbackTimer = Timer(Duration(seconds: durationSec), () {
      if (mounted && _playingVoiceMessageId == msg.id) {
        setState(() => _playingVoiceMessageId = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LmtCubit, LmtState>(
      builder: (context, state) {
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        final primary = AppColors.primaryOf(context);
        final accentGreen = AppColors.accentGreenOf(context);
        final textPrimary = AppColors.textPrimaryOf(context);
        final textSecondary = AppColors.textSecondaryOf(context);
        final messages = state.messagesForGroup(widget.group.id);

        return Column(
          children: [
            // Group Header Bar
            LmtCard(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
              borderRadius: 18.r,
              accentColor: primary,
              isHighlighted: true,
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                    ),
                  ),
                  LmtAvatar(
                    imagePath: widget.group.imagePath,
                    radius: 20,
                    showShadow: false,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.group.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.h6.copyWith(
                            color: textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.group.memberIds.length} ${isArabic ? 'عضو' : 'members'} • ${isArabic ? 'المسؤول:' : 'Admin:'} ${widget.group.adminName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: isArabic ? 'تثبيت المجموعة' : 'Pin Group',
                    onPressed: () => context
                        .read<LmtCubit>()
                        .togglePinChatGroup(widget.group.id),
                    icon: Icon(
                      widget.group.isPinned
                          ? Icons.push_pin_rounded
                          : Icons.push_pin_outlined,
                      color: widget.group.isPinned ? primary : textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),

            // Messages List (reverse: true opens immediately at the latest message)
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
                          onShowActions: () =>
                              _showMessageActionsSheet(context, state, msg),
                          onShowSeenBy: () => _showSeenBySheet(context, msg),
                          onToggleReaction: (emoji) => context
                              .read<LmtCubit>()
                              .toggleMessageReaction(
                                messageId: msg.id,
                                emoji: emoji,
                              ),
                          onToggleVoicePlay: () => _togglePlayVoiceNote(msg),
                        );
                      },
                    ),
            ),

            // Reply or Edit Banner above Input
            if (_replyingTo != null || _editingMessage != null)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                margin: EdgeInsets.only(bottom: 4.h),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      _editingMessage != null
                          ? Icons.edit_rounded
                          : Icons.reply_rounded,
                      color: primary,
                      size: 18.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        _editingMessage != null
                            ? '${isArabic ? 'تعديل الرسالة:' : 'Editing:'} ${_editingMessage!.content}'
                            : '${isArabic ? 'الرد على' : 'Replying to'} ${_replyingTo!.senderName}: ${_replyingTo!.content}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.sp, color: textPrimary),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => setState(() {
                        _replyingTo = null;
                        _editingMessage = null;
                        _messageController.clear();
                      }),
                    ),
                  ],
                ),
              ),

            // Voice Note Recording Bar OR Message Input Composer
            // Always kept in exact Left-to-Right layout regardless of app language
            if (_isRecordingVoice)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mic_rounded, color: AppColors.error),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        isArabic
                            ? 'جاري التسجيل... 00:${_recordingSeconds.toString().padLeft(2, '0')}'
                            : 'Recording Voice Note... 00:${_recordingSeconds.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _cancelVoiceNoteRecording,
                      child: Text(isArabic ? 'إلغاء' : 'Cancel'),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentGreen,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _sendVoiceNote,
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: Text(isArabic ? 'إرسال' : 'Send'),
                    ),
                  ],
                ),
              )
            else
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  children: [
                    IconButton(
                      tooltip: isArabic ? 'مرفقات وملصقات' : 'Attachments',
                      onPressed: () => _showAttachmentMenu(context),
                      icon: Icon(
                        Icons.add_circle_outline_rounded,
                        color: primary,
                      ),
                    ),
                    IconButton(
                      tooltip: isArabic ? 'ملصقات' : 'Stickers',
                      onPressed: () => _showStickerPickerSheet(context),
                      icon: Icon(
                        Icons.emoji_emotions_outlined,
                        color: primary,
                      ),
                    ),
                    Expanded(
                      child: Directionality(
                        textDirection:
                            isArabic ? TextDirection.rtl : TextDirection.ltr,
                        child: TextField(
                          controller: _messageController,
                          style: TextStyle(color: textPrimary, fontSize: 13.sp),
                          onSubmitted: (_) => _handleSendText(),
                          decoration: InputDecoration(
                            hintText: isArabic
                                ? 'اكتب رسالة للفريق...'
                                : 'Type a message...',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 10.h,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24.r),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    IconButton(
                      tooltip: isArabic ? 'تسجيل صوتي' : 'Voice Note',
                      onPressed: _startVoiceNoteRecording,
                      icon: Icon(Icons.mic_none_rounded, color: primary),
                    ),
                    IconButton.filled(
                      style: IconButton.styleFrom(backgroundColor: primary),
                      onPressed: _handleSendText,
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  void _showAttachmentMenu(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final primary = AppColors.primaryOf(context);
    final accentGreen = AppColors.accentGreenOf(context);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceOf(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isArabic
                    ? 'إرسال وسائط أو مرفقات للمجموعة'
                    : 'Send Media or Attachment to Group',
                style: AppTypography.h5.copyWith(
                  color: AppColors.textPrimaryOf(ctx),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _AttachmentOptionButton(
                    icon: Icons.image_rounded,
                    color: primary,
                    label: isArabic ? 'صورة (Image)' : 'Image',
                    onTap: () {
                      Navigator.pop(ctx);
                      _showSendImageSheet(context);
                    },
                  ),
                  _AttachmentOptionButton(
                    icon: Icons.attach_file_rounded,
                    color: accentGreen,
                    label: isArabic ? 'ملف (File)' : 'File Attach',
                    onTap: () {
                      Navigator.pop(ctx);
                      _showSendFileSheet(context);
                    },
                  ),
                  _AttachmentOptionButton(
                    icon: Icons.emoji_emotions_rounded,
                    color: const Color(0xFFF59E0B),
                    label: isArabic ? 'ملصق (Sticker)' : 'Stickers',
                    onTap: () {
                      Navigator.pop(ctx);
                      _showStickerPickerSheet(context);
                    },
                  ),
                  _AttachmentOptionButton(
                    icon: Icons.mic_rounded,
                    color: AppColors.error,
                    label: isArabic ? 'تسجيل صوتي' : 'Voice Note',
                    onTap: () {
                      Navigator.pop(ctx);
                      _startVoiceNoteRecording();
                    },
                  ),
                ],
              ),
              SizedBox(height: 12.h),
            ],
          ),
        );
      },
    );
  }

  void _showSendImageSheet(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final captionCtrl = TextEditingController(
      text: isArabic
          ? 'صورة من بروفة المسرح والتحضيرات 🎭'
          : 'Stage rehearsal photo 🎭',
    );
    String selectedAsset = AppAssets.actIcon;
    final images = [
      AppAssets.actIcon,
      AppAssets.appLogo,
      AppAssets.picturesIcon,
      AppAssets.galleryIcon,
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceOf(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20.w,
                right: 20.w,
                top: 18.h,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.h,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isArabic ? 'إرسال صورة للمجموعة 📷' : 'Send Image 📷',
                    style: AppTypography.h5.copyWith(
                      color: AppColors.textPrimaryOf(ctx),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final file = await DeviceFileHelper.pickFileSafely(
                          ctx,
                          type: FileType.image,
                        );
                        if (file != null && file.path != null) {
                          final savedPath =
                              await DeviceFileHelper.persistPickedFile(
                            file.path!,
                            file.name,
                          );
                          setModalState(() => selectedAsset = savedPath);
                        }
                      },
                      icon: const Icon(Icons.photo_library_rounded),
                      label: Text(
                        isArabic
                            ? 'اختيار صورة من معرض الهاتف 📱'
                            : 'Choose Image from Phone Gallery 📱',
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  SizedBox(
                    height: 90.h,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      separatorBuilder: (_, _) => SizedBox(width: 10.w),
                      itemBuilder: (_, idx) {
                        final img = images[idx];
                        final selected = selectedAsset == img;
                        return GestureDetector(
                          onTap: () =>
                              setModalState(() => selectedAsset = img),
                          child: Container(
                            width: 90.w,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primaryOf(ctx)
                                    : AppColors.borderOf(ctx),
                                width: selected ? 2.5 : 1,
                              ),
                            ),
                            child: DeviceFileHelper.buildImage(
                              img,
                              fit: BoxFit.contain,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: captionCtrl,
                    decoration: InputDecoration(
                      labelText: isArabic ? 'وصف الصورة' : 'Image Caption',
                    ),
                  ),
                  SizedBox(height: 14.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<LmtCubit>().sendChatMessage(
                              groupId: widget.group.id,
                              type: MessageType.image,
                              content: captionCtrl.text.trim(),
                              attachmentPath: selectedAsset,
                              replyTo: _replyingTo,
                            );
                        setState(() => _replyingTo = null);
                        Navigator.pop(ctx);
                        _scrollToLatest();
                      },
                      icon: const Icon(Icons.send_rounded),
                      label: Text(isArabic ? 'إرسال الصورة' : 'Send Image'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSendFileSheet(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final fileNameCtrl = TextEditingController(
      text: 'اسكريبت_المشهد_الجديد_LMT.pdf',
    );
    final noteCtrl = TextEditingController(
      text: isArabic
          ? 'مرفق ملف الاسكريبت وتوزيع المهام للمراجعة 📄'
          : 'Attached script & task sheet 📄',
    );

    String? pickedFilePath;
    String pickedFileSize = '1.8 MB';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceOf(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20.w,
                right: 20.w,
                top: 18.h,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.h,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isArabic ? 'إرفاق ملف في المحادثة 📎' : 'Attach File 📎',
                    style: AppTypography.h5.copyWith(
                      color: AppColors.textPrimaryOf(ctx),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final f = await DeviceFileHelper.pickFileSafely(ctx);
                        if (f != null && f.path != null) {
                          final savedPath =
                              await DeviceFileHelper.persistPickedFile(
                            f.path!,
                            f.name,
                          );
                          setModalState(() {
                            pickedFilePath = savedPath;
                            pickedFileSize =
                                DeviceFileHelper.formatBytes(f.size);
                            fileNameCtrl.text = f.name;
                          });
                        }
                      },
                      icon: const Icon(Icons.folder_open_rounded),
                      label: Text(
                        isArabic
                            ? 'اختيار ملف من الهاتف 📱'
                            : 'Choose File from Phone 📱',
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  TextField(
                    controller: fileNameCtrl,
                    decoration: InputDecoration(
                      labelText: isArabic ? 'اسم الملف' : 'File Name',
                      prefixIcon: const Icon(Icons.insert_drive_file_outlined),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: noteCtrl,
                    decoration: InputDecoration(
                      labelText: isArabic ? 'رسالة مع الملف' : 'Message Note',
                    ),
                  ),
                  SizedBox(height: 14.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<LmtCubit>().sendChatMessage(
                              groupId: widget.group.id,
                              type: MessageType.file,
                              content: noteCtrl.text.trim(),
                              attachmentPath:
                                  pickedFilePath ?? fileNameCtrl.text.trim(),
                              fileSize: pickedFileSize,
                              replyTo: _replyingTo,
                            );
                        setState(() => _replyingTo = null);
                        Navigator.pop(ctx);
                        _scrollToLatest();
                      },
                      icon: const Icon(Icons.upload_file_rounded),
                      label: Text(isArabic ? 'إرسال الملف' : 'Send File'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showStickerPickerSheet(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceOf(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final primary = AppColors.primaryOf(ctx);
            final textPrimary = AppColors.textPrimaryOf(ctx);
            final textSecondary = AppColors.textSecondaryOf(ctx);

            return Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.emoji_emotions_rounded,
                        color: primary,
                        size: 24.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          isArabic
                              ? 'الملصقات المحفوظة (Stickers)'
                              : 'Saved Stickers',
                          style: AppTypography.h5.copyWith(color: textPrimary),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await DeviceFileHelper.pickFileSafely(
                            ctx,
                            type: FileType.image,
                          );
                          if (picked != null && picked.path != null) {
                            final savedPath =
                                await DeviceFileHelper.persistPickedFile(
                              picked.path!,
                              picked.name,
                            );
                            final updated = [savedPath, ..._savedStickers];
                            await AppPreferences.setSavedStickers(updated);
                            if (mounted) {
                              setState(() => _savedStickers = updated);
                            }
                            setModalState(() {});
                          }
                        },
                        icon: Icon(Icons.add_rounded, size: 18.sp),
                        label: Text(
                          isArabic ? 'حفظ ملصق' : 'Add Sticker',
                          style: TextStyle(fontSize: 12.sp),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  if (_savedStickers.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        vertical: 28.h,
                        horizontal: 16.w,
                      ),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(18.r),
                        border: Border.all(color: AppColors.borderOf(ctx)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sticky_note_2_outlined,
                            size: 46.sp,
                            color: textSecondary,
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            isArabic
                                ? 'لا توجد أي ستيكرات محفوظة حالياً'
                                : 'No saved stickers found',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.5.sp,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            isArabic
                                ? 'اضغط على "حفظ ملصق" لإضافة ستيكرات من هاتفك وإرسالها في المحادثة'
                                : 'Tap "Add Sticker" to save stickers from your phone and send them in chat',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: 260.h),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _savedStickers.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 10.h,
                          crossAxisSpacing: 10.w,
                          childAspectRatio: 1.0,
                        ),
                        itemBuilder: (_, idx) {
                          final stickerPath = _savedStickers[idx];
                          return Stack(
                            children: [
                              Positioned.fill(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14.r),
                                  onTap: () {
                                    context.read<LmtCubit>().sendChatMessage(
                                          groupId: widget.group.id,
                                          type: MessageType.sticker,
                                          content: 'ملصق',
                                          attachmentPath: stickerPath,
                                          replyTo: _replyingTo,
                                        );
                                    setState(() => _replyingTo = null);
                                    Navigator.pop(ctx);
                                    _scrollToLatest();
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(6.w),
                                    decoration: BoxDecoration(
                                      color: primary.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(14.r),
                                      border: Border.all(
                                        color: AppColors.borderOf(ctx),
                                      ),
                                    ),
                                    child: DeviceFileHelper.buildImage(
                                      stickerPath,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: InkWell(
                                  onTap: () async {
                                    final updated = List<String>.from(
                                      _savedStickers,
                                    )..removeAt(idx);
                                    await AppPreferences.setSavedStickers(
                                      updated,
                                    );
                                    if (mounted) {
                                      setState(() => _savedStickers = updated);
                                    }
                                    setModalState(() {});
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: AppColors.error,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 12.sp,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showMessageActionsSheet(
    BuildContext context,
    LmtState state,
    ChatMessageModel message,
  ) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isSender = message.senderId == state.currentUser.id;
    final isGroupAdmin = widget.group.adminId == state.currentUser.id ||
        state.currentUser.role == UserRole.admin;
    final canDelete = isSender || isGroupAdmin;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceOf(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) {
        final textPrimary = AppColors.textPrimaryOf(ctx);
        final primary = AppColors.primaryOf(ctx);

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isArabic
                      ? 'تفاعل مع الرسالة بأي إيموجي'
                      : 'React with any Emoji',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondaryOf(ctx),
                  ),
                ),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  alignment: WrapAlignment.center,
                  children: [
                    ..._quickEmojis.map(
                      (emoji) => InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          context.read<LmtCubit>().toggleMessageReaction(
                                messageId: message.id,
                                emoji: emoji,
                              );
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            emoji,
                            style: TextStyle(fontSize: 20.sp),
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Navigator.pop(ctx);
                        _showCustomEmojiInputDialog(context, message);
                      },
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add_reaction_outlined,
                          color: primary,
                          size: 22.sp,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),

                ListTile(
                  dense: true,
                  leading: Icon(Icons.reply_rounded, color: primary),
                  title: Text(
                    isArabic ? 'رد على الرسالة (Reply)' : 'Reply to message',
                    style: TextStyle(color: textPrimary),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _replyingTo = message;
                      _editingMessage = null;
                    });
                  },
                ),

                ListTile(
                  dense: true,
                  leading: Icon(Icons.copy_rounded, color: primary),
                  title: Text(
                    isArabic ? 'نسخ محتوى الرسالة (Copy)' : 'Copy message text',
                    style: TextStyle(color: textPrimary),
                  ),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: message.content));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isArabic
                              ? 'تم نسخ الرسالة للحافظة'
                              : 'Message copied to clipboard',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),

                ListTile(
                  dense: true,
                  leading: Icon(Icons.forward_rounded, color: primary),
                  title: Text(
                    isArabic
                        ? 'إعادة توجيه لمجموعة أخرى (Forward)'
                        : 'Forward to another group',
                    style: TextStyle(color: textPrimary),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showForwardDialog(context, state, message);
                  },
                ),

                ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.done_all_rounded,
                    color: AppColors.accentGreenOf(ctx),
                  ),
                  title: Text(
                    message.type == MessageType.voiceNote
                        ? (isArabic
                            ? 'من قرأ واستمع للرسالة الصوتية (${message.seenBy.length})'
                            : 'Who Seen & Listened (${message.seenBy.length})')
                        : (isArabic
                            ? 'من قرأ الرسالة (${message.seenBy.length})'
                            : 'Seen By (${message.seenBy.length})'),
                    style: TextStyle(color: textPrimary),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showSeenBySheet(context, message);
                  },
                ),

                if (isSender)
                  ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.edit_outlined,
                      color: Color(0xFFF59E0B),
                    ),
                    title: Text(
                      isArabic
                          ? 'تعديل الرسالة (مرسل الرسالة فقط)'
                          : 'Edit Message (Sender only)',
                      style: TextStyle(color: textPrimary),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _editingMessage = message;
                        _replyingTo = null;
                        _messageController.text = message.content;
                      });
                    },
                  ),

                if (canDelete)
                  ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.error,
                    ),
                    title: Text(
                      isArabic
                          ? 'حذف الرسالة (المسؤول أو المرسل فقط)'
                          : 'Delete Message (Group Admin or Sender only)',
                      style: const TextStyle(color: AppColors.error),
                    ),
                    onTap: () {
                      context.read<LmtCubit>().deleteChatMessage(
                            messageId: message.id,
                            groupId: widget.group.id,
                          );
                      Navigator.pop(ctx);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCustomEmojiInputDialog(
    BuildContext context,
    ChatMessageModel message,
  ) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final emojiCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isArabic ? 'أدخل أي إيموجي للتفاعل' : 'Enter any Emoji',
        ),
        content: TextField(
          controller: emojiCtrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '🎉 🤩 🙌 💐 🕊️ ...',
            labelText: isArabic ? 'الإيموجي' : 'Emoji',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = emojiCtrl.text.trim();
              if (val.isNotEmpty) {
                context.read<LmtCubit>().toggleMessageReaction(
                      messageId: message.id,
                      emoji: val,
                    );
              }
              Navigator.pop(ctx);
            },
            child: Text(isArabic ? 'تفاعل' : 'React'),
          ),
        ],
      ),
    );
  }

  void _showForwardDialog(
    BuildContext context,
    LmtState state,
    ChatMessageModel message,
  ) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceOf(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isArabic
                    ? 'اختر المجموعة لإعادة توجيه الرسالة إليها:'
                    : 'Select a group to forward message to:',
                style: AppTypography.h5.copyWith(
                  color: AppColors.textPrimaryOf(ctx),
                ),
              ),
              SizedBox(height: 12.h),
              ...state.chatGroups.map(
                (grp) => ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        DeviceFileHelper.imageProviderFor(grp.imagePath),
                  ),
                  title: Text(grp.name),
                  subtitle: Text('${grp.memberIds.length} members'),
                  trailing: const Icon(Icons.send_rounded),
                  onTap: () {
                    context.read<LmtCubit>().forwardMessageToGroup(
                          message: message,
                          targetGroupId: grp.id,
                        );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isArabic
                              ? 'تم إعادة توجيه الرسالة إلى ${grp.name}'
                              : 'Forwarded to ${grp.name}',
                        ),
                        backgroundColor: AppColors.accentGreenOf(context),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSeenBySheet(BuildContext context, ChatMessageModel message) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isVoice = message.type == MessageType.voiceNote;
    final accentGreen = AppColors.accentGreenOf(context);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceOf(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.done_all_rounded, color: accentGreen),
                  SizedBox(width: 8.w),
                  Text(
                    isVoice
                        ? (isArabic
                            ? 'من قرأ واستمع للرسالة الصوتية 🎤'
                            : 'Seen & Listened By 🎤')
                        : (isArabic
                            ? 'من قرأ الرسالة (Seen By) 👀'
                            : 'Seen By 👀'),
                    style: AppTypography.h5.copyWith(
                      color: AppColors.textPrimaryOf(ctx),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              ...message.seenBy.map(
                (seen) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundImage: AssetImage(seen.avatarPath),
                  ),
                  title: Text(
                    seen.memberName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryOf(ctx),
                    ),
                  ),
                  subtitle: Text(
                    DateFormat('dd/MM/yyyy • hh:mm a').format(seen.timestamp),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.textSecondaryOf(ctx),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isVoice && seen.hasListened) ...[
                        Icon(
                          Icons.headphones_rounded,
                          color: accentGreen,
                          size: 18.sp,
                        ),
                        SizedBox(width: 4.w),
                      ],
                      Icon(
                        Icons.done_all_rounded,
                        color: accentGreen,
                        size: 18.sp,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AttachmentOptionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _AttachmentOptionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26.sp),
            ),
            SizedBox(height: 6.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
