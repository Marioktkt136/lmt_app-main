import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/services/native_media_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/app_preferences.dart';
import '../../../core/utils/device_file_helper.dart';
import '../../../core/widgets/adaptive_layout.dart';
import '../../../core/widgets/lmt_empty_state.dart';
import '../../auth/services/biometric_session_lock_controller.dart';
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

  /// Whether viewing this room should automatically record Seen receipts.
  ///
  /// Set to `false` for non-selected desktop split-view previews until the
  /// user explicitly clicks or interacts with the group.
  final bool autoMarkSeen;

  /// Optional callback fired when the user directly interacts with this room.
  final VoidCallback? onUserInteracted;

  /// Creates a [GroupConversationRoom].
  const GroupConversationRoom({
    super.key,
    required this.group,
    required this.onBack,
    this.showInlineHeader = false,
    this.autoMarkSeen = true,
    this.onUserInteracted,
  });

  @override
  State<GroupConversationRoom> createState() => _GroupConversationRoomState();
}

class _GroupConversationRoomState extends State<GroupConversationRoom>
    with WidgetsBindingObserver {
  static const double _bottomThresholdPx = 56.0;
  static const double _showFabThresholdPx = 180.0;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _listViewportKey = GlobalKey();
  final Map<String, GlobalKey> _messageKeys = {};

  ChatMessageModel? _replyingTo;
  ChatMessageModel? _editingMessage;
  bool _isRecordingVoice = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  Timer? _typingHideTimer;
  Timer? _highlightClearTimer;
  Timer? _seenSyncThrottleTimer;
  bool _isTyping = false;
  DateTime? _lastTypingHeartbeatAt;
  bool _isMarkingSeen = false;
  final Set<String> _lastMeasuredVisibleIds = <String>{};
  bool _showScrollToBottom = false;
  String? _sessionUnreadAnchorMessageId;
  int _sessionUnreadCount = 0;
  bool _didInitialUnreadCheck = false;
  String? _playingVoiceMessageId;
  String? _highlightedMessageId;
  List<String> _savedStickers = const [];
  LmtCubit? _cubitRef;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    BiometricSessionLockController.instance.isLocked
        .addListener(_onBiometricLockChanged);
    _loadSavedStickers();
    _scrollController.addListener(_onScrollChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final cubit = context.read<LmtCubit>();
        _cubitRef = cubit;
        cubit.startWatchingGroupTyping(widget.group.id);
        _initializeUnreadAnchorAndScroll();
      }
    });
  }

  void _onBiometricLockChanged() {
    if (!mounted) return;
    if (!BiometricSessionLockController.instance.isLocked.value &&
        _canMarkMessagesSeenNow) {
      _scheduleVisibleSeenSync();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        mounted &&
        _canMarkMessagesSeenNow) {
      _scheduleVisibleSeenSync();
    } else if ((state == AppLifecycleState.inactive ||
            state == AppLifecycleState.paused ||
            state == AppLifecycleState.hidden) &&
        mounted &&
        widget.autoMarkSeen &&
        !BiometricSessionLockController.instance.isLocked.value &&
        _cubitRef != null) {
      final inInactiveChatTab = widget.showInlineHeader &&
          context.findAncestorWidgetOfExactType<PageView>() != null &&
          _cubitRef!.state.activeLayoutTab != 1;
      if (!inInactiveChatTab) {
        _flushSeenOnLeaveOrBackground();
      }
    }
  }

  bool get _canMarkMessagesSeenNow {
    if (!mounted || !widget.autoMarkSeen) return false;
    if (BiometricSessionLockController.instance.isLocked.value) return false;
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle == AppLifecycleState.paused ||
        lifecycle == AppLifecycleState.hidden ||
        lifecycle == AppLifecycleState.inactive) {
      return false;
    }
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;
    if (widget.showInlineHeader &&
        _cubitRef != null &&
        context.findAncestorWidgetOfExactType<PageView>() != null &&
        _cubitRef!.state.activeLayoutTab != 1) {
      return false;
    }
    return true;
  }

  @override
  void didUpdateWidget(covariant GroupConversationRoom oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.group.id != widget.group.id) {
      _cubitRef?.stopWatchingGroupTyping(oldWidget.group.id);
      _didInitialUnreadCheck = false;
      _sessionUnreadAnchorMessageId = null;
      _sessionUnreadCount = 0;
      _showScrollToBottom = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final cubit = context.read<LmtCubit>();
          _cubitRef = cubit;
          cubit.startWatchingGroupTyping(widget.group.id);
          _initializeUnreadAnchorAndScroll();
        }
      });
    } else if (!oldWidget.autoMarkSeen && widget.autoMarkSeen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _canMarkMessagesSeenNow) {
          _syncSeenReceipts();
        }
      });
    }
  }

  void _onScrollChanged() {
    if (!mounted || !_scrollController.hasClients) return;
    widget.onUserInteracted?.call();
    final pixels = _scrollController.position.pixels;
    final shouldShowFab = pixels > _showFabThresholdPx;
    if (shouldShowFab != _showScrollToBottom) {
      setState(() => _showScrollToBottom = shouldShowFab);
    }
    if (_canMarkMessagesSeenNow) {
      _scheduleVisibleSeenSync();
    }
  }

  void _scheduleVisibleSeenSync() {
    _seenSyncThrottleTimer?.cancel();
    _seenSyncThrottleTimer = Timer(const Duration(milliseconds: 160), () {
      if (mounted && _canMarkMessagesSeenNow) {
        _syncSeenReceipts();
      }
    });
  }

  Future<void> _initializeUnreadAnchorAndScroll() async {
    if (!mounted || _didInitialUnreadCheck) return;
    final cubit = context.read<LmtCubit>();
    if (!cubit.state.isInitialized) return;
    _didInitialUnreadCheck = true;

    final messages = cubit.state.messagesForGroup(widget.group.id);
    final uid = cubit.state.currentUser.id;
    final firstUnreadIdx = messages.indexWhere(
      (m) => m.senderId != uid && !m.seenBy.any((s) => s.memberId == uid),
    );

    if (firstUnreadIdx == -1) {
      if (_canMarkMessagesSeenNow) {
        await _syncSeenReceipts();
      }
      return;
    }

    final anchorId = messages[firstUnreadIdx].id;
    final unreadCount = messages
        .where(
          (m) => m.senderId != uid && !m.seenBy.any((s) => s.memberId == uid),
        )
        .length;

    setState(() {
      _sessionUnreadAnchorMessageId = anchorId;
      _sessionUnreadCount = unreadCount;
    });

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await _scrollToMessage(
      anchorId,
      messages,
      alignment: 0.78,
      highlight: false,
    );
    if (!mounted) return;
    if (_canMarkMessagesSeenNow) {
      await _syncSeenReceipts();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _canMarkMessagesSeenNow) {
        _syncSeenReceipts();
      }
    });
  }

  bool get _isScrolledToBottom {
    final hasDim = _scrollController.hasClients &&
        _scrollController.position.hasContentDimensions;
    return !hasDim ||
        _scrollController.position.pixels <= _bottomThresholdPx ||
        _scrollController.position.maxScrollExtent <= _bottomThresholdPx;
  }

  void _flushSeenOnLeaveOrBackground() {
    if (!widget.autoMarkSeen ||
        BiometricSessionLockController.instance.isLocked.value ||
        _cubitRef == null) {
      return;
    }
    if (_isScrolledToBottom) {
      unawaited(_cubitRef!.markGroupMessagesSeen(widget.group.id));
    } else if (_lastMeasuredVisibleIds.isNotEmpty) {
      unawaited(
        _cubitRef!.markGroupMessagesSeen(
          widget.group.id,
          onlyMessageIds: Set<String>.from(_lastMeasuredVisibleIds),
        ),
      );
    }
  }

  Future<void> _syncSeenReceipts() async {
    if (_isMarkingSeen || !_canMarkMessagesSeenNow) return;
    final cubit = context.read<LmtCubit>();
    final messages = cubit.state.messagesForGroup(widget.group.id);
    final uid = cubit.state.currentUser.id;
    final hasAnyUnseen = messages.any(
      (m) => m.senderId != uid && !m.seenBy.any((s) => s.memberId == uid),
    );
    if (!hasAnyUnseen) return;

    _isMarkingSeen = true;
    try {
      if (_isScrolledToBottom) {
        _lastMeasuredVisibleIds
          ..clear()
          ..addAll(messages.map((m) => m.id));
        await cubit.markGroupMessagesSeen(widget.group.id);
        return;
      }

      // User is paused/scrolled above the latest message: mark only up to the
      // bottom edge of the visible viewport so deeper unseen messages below
      // retain their unseen status until scrolled into view.
      final viewportRender = _listViewportKey.currentContext?.findRenderObject();
      var maxVisibleIdx = -1;
      if (viewportRender is RenderBox && viewportRender.hasSize) {
        final viewportBottomY = viewportRender
            .localToGlobal(Offset(0, viewportRender.size.height))
            .dy;
        for (var i = 0; i < messages.length; i++) {
          final ctx = _messageKeys[messages[i].id]?.currentContext;
          final render = ctx?.findRenderObject();
          if (render is RenderBox && render.attached && render.hasSize) {
            final itemTopY = render.localToGlobal(Offset.zero).dy;
            if (itemTopY <= viewportBottomY + 32.0) {
              maxVisibleIdx = i;
            }
          }
        }
      }

      if (maxVisibleIdx == -1 && _sessionUnreadAnchorMessageId != null) {
        final anchorIdx =
            messages.indexWhere((m) => m.id == _sessionUnreadAnchorMessageId);
        if (anchorIdx != -1) {
          maxVisibleIdx = anchorIdx;
        }
      }

      if (maxVisibleIdx >= 0) {
        final visibleIds = <String>{
          for (var i = 0; i <= maxVisibleIdx; i++) messages[i].id,
        };
        _lastMeasuredVisibleIds
          ..clear()
          ..addAll(visibleIds);
        await cubit.markGroupMessagesSeen(
          widget.group.id,
          onlyMessageIds: visibleIds,
        );
      }
    } finally {
      _isMarkingSeen = false;
    }
  }

  Future<void> _loadSavedStickers() async {
    final stickers = await AppPreferences.getSavedStickers();
    if (!mounted) return;
    setState(() => _savedStickers = stickers);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    BiometricSessionLockController.instance.isLocked
        .removeListener(_onBiometricLockChanged);
    _recordingTimer?.cancel();
    _typingHideTimer?.cancel();
    _highlightClearTimer?.cancel();
    _seenSyncThrottleTimer?.cancel();
    _flushSeenOnLeaveOrBackground();
    _scrollController.removeListener(_onScrollChanged);
    if (_isTyping) {
      _cubitRef?.setTypingInGroup(groupId: widget.group.id, isTyping: false);
    }
    _cubitRef?.stopWatchingGroupTyping(widget.group.id);
    NativeMediaService.stopVoiceNote();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _scrollToMessage(
    String targetMessageId,
    List<ChatMessageModel> messages, {
    double alignment = 0.45,
    bool highlight = true,
  }) async {
    final targetIdx = messages.indexWhere((m) => m.id == targetMessageId);
    if (targetIdx == -1) {
      if (!mounted) return;
      return;
    }

    if (highlight) {
      _highlightClearTimer?.cancel();
      setState(() => _highlightedMessageId = targetMessageId);
    }

    final directContext = _messageKeys[targetMessageId]?.currentContext;
    if (directContext != null) {
      await Scrollable.ensureVisible(
        directContext,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        alignment: alignment,
      );
    } else if (_scrollController.hasClients) {
      final totalItems = messages.length;
      final reversedIdx = totalItems - 1 - targetIdx;
      final maxExtent = _scrollController.position.maxScrollExtent;
      if (maxExtent > 0 && totalItems > 1) {
        final estimatedOffset =
            ((reversedIdx / (totalItems - 1)) * maxExtent).clamp(0.0, maxExtent);
        _scrollController.jumpTo(estimatedOffset);
      }

      for (var attempt = 0; attempt < 24; attempt++) {
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) return;
        final ctx = _messageKeys[targetMessageId]?.currentContext;
        if (ctx != null && ctx.mounted) {
          await Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: alignment,
          );
          break;
        }
        if (!_scrollController.hasClients) break;
        double? delta;
        for (var i = 0; i < totalItems; i++) {
          if (_messageKeys[messages[i].id]?.currentContext != null) {
            // In reverse:true ListView, older items (smaller i) live higher
            // up at larger scroll offsets; newer items live at smaller offsets.
            delta = i > targetIdx ? 320.0 : -320.0;
            break;
          }
        }
        if (delta == null) break;
        final pos = _scrollController.position;
        final next = (pos.pixels + delta).clamp(0.0, pos.maxScrollExtent);
        if ((next - pos.pixels).abs() < 1.0) break;
        _scrollController.jumpTo(next);
      }
    }

    if (!mounted || !highlight) return;
    _highlightClearTimer?.cancel();
    _highlightClearTimer = Timer(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      if (_highlightedMessageId == targetMessageId) {
        setState(() => _highlightedMessageId = null);
      }
    });
  }

  Future<void> _jumpToOriginalMessage(
    String targetMessageId,
    List<ChatMessageModel> messages,
  ) =>
      _scrollToMessage(targetMessageId, messages);

  void _handleTextChanged(String value) {
    _typingHideTimer?.cancel();
    final cubit = context.read<LmtCubit>();
    final hasText = value.trim().isNotEmpty;
    if (!hasText) {
      if (_isTyping) {
        _isTyping = false;
        _lastTypingHeartbeatAt = null;
        cubit.setTypingInGroup(groupId: widget.group.id, isTyping: false);
      }
      return;
    }

    final now = DateTime.now();
    final needsHeartbeat = !_isTyping ||
        _lastTypingHeartbeatAt == null ||
        now.difference(_lastTypingHeartbeatAt!).inSeconds >= 2;
    if (needsHeartbeat) {
      _isTyping = true;
      _lastTypingHeartbeatAt = now;
      cubit.setTypingInGroup(groupId: widget.group.id, isTyping: true);
    }

    _typingHideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isTyping) {
        _isTyping = false;
        _lastTypingHeartbeatAt = null;
        context
            .read<LmtCubit>()
            .setTypingInGroup(groupId: widget.group.id, isTyping: false);
      }
    });
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      }
      if (mounted) {
        setState(() => _showScrollToBottom = false);
        await _syncSeenReceipts();
      }
    });
  }

  Future<void> _handleSendText() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _typingHideTimer?.cancel();
    final cubit = context.read<LmtCubit>();

    if (_editingMessage != null) {
      final isArabic = Localizations.localeOf(context).languageCode == 'ar';
      final edited = await cubit.editChatMessage(
        messageId: _editingMessage!.id,
        newContent: text,
      );
      if (!mounted) return;
      if (!edited) {
        showDialog<void>(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.schedule_rounded, color: AppColors.warning),
                const SizedBox(width: 8),
                Text(isArabic ? 'انتهت مهلة التعديل' : 'Edit Window Expired'),
              ],
            ),
            content: Text(
              isArabic
                  ? 'انتهى الوقت المتاح لتعديل هذه الرسالة (الحد الأقصى 15 دقيقة)'
                  : 'Edit window expired (messages can only be edited within 15 minutes)',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text(isArabic ? 'حسناً' : 'OK'),
              ),
            ],
          ),
        );
      }
      setState(() {
        _isTyping = false;
        _editingMessage = null;
        _messageController.clear();
      });
      return;
    }

    final replyTarget = _replyingTo;
    setState(() {
      _isTyping = false;
      _lastTypingHeartbeatAt = null;
      _replyingTo = null;
      _messageController.clear();
    });
    _scrollToLatest();

    unawaited(
      cubit.setTypingInGroup(groupId: widget.group.id, isTyping: false),
    );
    unawaited(
      cubit.sendChatMessage(
        groupId: widget.group.id,
        type: MessageType.text,
        content: text,
        replyTo: replyTarget,
      ),
    );
  }

  Future<void> _startVoiceNoteRecording() async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final granted = await NativeMediaService.requestMicrophonePermission();
    if (!mounted) return;

    if (!granted) {
      showDialog<void>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.mic_off_rounded, color: AppColors.error),
              const SizedBox(width: 8),
              Text(isArabic ? 'إذن الميكروفون' : 'Microphone Permission'),
            ],
          ),
          content: Text(
            isArabic
                ? 'يرجى السماح بإذن الميكروفون (Microphone Permission) لتسجيل الرسائل الصوتية 🎤'
                : 'Please grant Microphone permission to record voice notes 🎤',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(isArabic ? 'حسناً' : 'OK'),
            ),
          ],
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
    final replyTarget = _replyingTo;
    final cubit = context.read<LmtCubit>();
    setState(() {
      _isRecordingVoice = false;
      _recordingSeconds = 0;
      _replyingTo = null;
    });
    final recordedFilePath = await NativeMediaService.stopVoiceRecording();
    if (recordedFilePath == null || recordedFilePath.trim().isEmpty) return;

    final syncedVoicePath = await DeviceFileHelper.persistPickedFile(
      recordedFilePath,
      'voice_${DateTime.now().millisecondsSinceEpoch}.m4a',
    );
    if (!mounted) return;
    _scrollToLatest();
    unawaited(
      cubit.sendChatMessage(
        groupId: widget.group.id,
        type: MessageType.voiceNote,
        content: 'رسالة صوتية مسجلة 🎤',
        attachmentPath: syncedVoicePath,
        voiceDurationSeconds: duration,
        replyTo: replyTarget,
      ),
    );
  }

  void _togglePlayVoiceNote(ChatMessageModel msg) {
    final willPlay = _playingVoiceMessageId != msg.id;
    setState(() {
      _playingVoiceMessageId = willPlay ? msg.id : null;
    });
    if (willPlay) {
      context.read<LmtCubit>().markVoiceNoteListened(msg.id);
    }
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
  }

  Future<void> _saveStickerMessage(ChatMessageModel msg) async {
    final path = msg.attachmentPath?.trim();
    if (path == null || path.isEmpty) return;

    if (!_savedStickers.contains(path)) {
      final updated = [path, ..._savedStickers];
      await AppPreferences.setSavedStickers(updated);
      if (mounted) {
        setState(() => _savedStickers = updated);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LmtCubit, LmtState>(
      builder: (context, state) {
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        final messages = state.messagesForGroup(widget.group.id);
        final liveUnreadCount = state.unreadMessagesCountForGroup(widget.group.id);
        if (!_didInitialUnreadCheck && state.isInitialized) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _initializeUnreadAnchorAndScroll();
          });
        } else if (liveUnreadCount > 0 &&
            _canMarkMessagesSeenNow &&
            !_isMarkingSeen &&
            _isScrolledToBottom) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _syncSeenReceipts();
          });
        }

        return Listener(
          onPointerDown: (_) => widget.onUserInteracted?.call(),
          child: AdaptiveContentBox(
          maxWidth: 820,
          child: Column(
            children: [
            if (widget.showInlineHeader) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(18.r),
                child: SizedBox(
                  height: 62.h,
                  child: ConversationHeaderBar(
                    group: widget.group,
                    state: state,
                    onBack: widget.onBack,
                    showBackButton: false,
                  ),
                ),
              ),
              SizedBox(height: 8.h),
            ],
            Expanded(
              key: _listViewportKey,
              child: messages.isEmpty
                  ? LmtEmptyState(
                      icon: Icons.chat_bubble_outline_rounded,
                      message: isArabic
                          ? 'ابدأ المحادثة الآن في ${widget.group.name}'
                          : 'Start chatting in ${widget.group.name}',
                    )
                  : Stack(
                      children: [
                        ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          physics: const BouncingScrollPhysics(),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[messages.length - 1 - index];
                            final isMe = msg.senderId == state.currentUser.id;
                            final senderAvatarOverride = state.members
                                .where((m) => m.id == msg.senderId)
                                .map((m) => m.avatarPath)
                                .firstOrNull;
                            final itemKey = _messageKeys.putIfAbsent(
                              msg.id,
                              GlobalKey.new,
                            );

                            final bubble = ChatMessageBubble(
                              msg: msg,
                              isMe: isMe,
                              senderAvatarOverride: senderAvatarOverride,
                              isPlayingVoice: _playingVoiceMessageId == msg.id,
                              isHighlighted: _highlightedMessageId == msg.id,
                              onTapReplyPreview: msg.replyToMessageId != null
                                  ? () => _jumpToOriginalMessage(
                                        msg.replyToMessageId!,
                                        messages,
                                      )
                                  : null,
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
                              onShowSeenBy: () =>
                                  showChatSeenBySheet(context, msg),
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

                            final showUnreadBannerHere =
                                msg.id == _sessionUnreadAnchorMessageId &&
                                    _sessionUnreadCount > 0;

                            return KeyedSubtree(
                              key: itemKey,
                              child: showUnreadBannerHere
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        _UnreadMessagesStopBanner(
                                          count: _sessionUnreadCount,
                                          isArabic: isArabic,
                                        ),
                                        bubble,
                                      ],
                                    )
                                  : bubble,
                            );
                          },
                        ),
                        if (_showScrollToBottom)
                          PositionedDirectional(
                            end: 10.w,
                            bottom: 10.h,
                            child: _ScrollToBottomFab(
                              unreadCount: liveUnreadCount,
                              onPressed: _scrollToLatest,
                            ),
                          ),
                      ],
                    ),
            ),
            Builder(
              builder: (context) {
                final remoteTypists =
                    state.visibleTypingMembersForGroup(widget.group.id);
                if (remoteTypists.isEmpty) return const SizedBox.shrink();
                return ChatTypingIndicator(typingMembers: remoteTypists);
              },
            ),
            ReplyEditBanner(
              replyingTo: _replyingTo,
              editingMessage: _editingMessage,
              onCancel: () {
                _typingHideTimer?.cancel();
                _lastTypingHeartbeatAt = null;
                if (_isTyping) {
                  _isTyping = false;
                  context
                      .read<LmtCubit>()
                      .setTypingInGroup(groupId: widget.group.id, isTyping: false);
                }
                setState(() {
                  _replyingTo = null;
                  _editingMessage = null;
                  _messageController.clear();
                });
              },
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
        ),
        ),
        );
      },
    );
  }
}

class _UnreadMessagesStopBanner extends StatelessWidget {
  final int count;
  final bool isArabic;

  const _UnreadMessagesStopBanner({
    required this.count,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    const badgeGreen = Color(0xFF25D366);
    final label = isArabic
        ? '$count رسائل غير مقروءة'
        : '$count unread ${count == 1 ? 'message' : 'messages'}';

    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.h),
      padding: EdgeInsets.symmetric(vertical: 6.h),
      decoration: BoxDecoration(
        color: badgeGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: AppColors.cardSurfaceOf(context),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: badgeGreen.withValues(alpha: 0.45)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.bold,
              color: badgeGreen,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScrollToBottomFab extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onPressed;

  const _ScrollToBottomFab({
    required this.unreadCount,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    const badgeGreen = Color(0xFF25D366);
    final primary = AppColors.primaryOf(context);
    final surface = AppColors.cardSurfaceOf(context);
    final iconColor = AppColors.textPrimaryOf(context);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          elevation: 5,
          shape: const CircleBorder(),
          color: surface,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Container(
              width: 42.w,
              height: 42.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: primary.withValues(alpha: 0.25),
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.keyboard_double_arrow_down_rounded,
                size: 22.sp,
                color: iconColor,
              ),
            ),
          ),
        ),
        if (unreadCount > 0)
          Positioned(
            top: -6,
            right: -4,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: badgeGreen,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
