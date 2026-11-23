import 'dart:async';

import '../../../core/cubit/lmt_cubit.dart';
import '../../../core/models/lmt_models.dart';
import '../../../core/services/local_notification_service.dart';

export '../../../core/cubit/lmt_cubit.dart';

/// Feature Cubit alias for the Chatting Room feature module.
typedef ChatCubit = LmtCubit;

/// Encapsulates Chatting Room groups, pinning, messages, voice notes, stickers,
/// reactions, live typing indicators, real seen receipts, forwarding, editing,
/// and deletion logic.
mixin ChatCubitMixin on LmtBaseCubit {
  final Map<String, StreamSubscription<List<TypingMemberStatus>>>
      _typingSubscriptions = {};

  /// Cancels all active typing indicator listeners on Cubit disposal.
  void cancelTypingWatchers() {
    for (final sub in _typingSubscriptions.values) {
      sub.cancel();
    }
    _typingSubscriptions.clear();
  }

  /// Starts watching live typing indicators for [groupId].
  void startWatchingGroupTyping(String groupId) {
    if (_typingSubscriptions.containsKey(groupId)) return;
    _typingSubscriptions[groupId] = repository
        .watchGroupTyping(groupId)
        .listen((remoteTypists) {
      final now = DateTime.now();
      final active = remoteTypists
          .where((t) => now.difference(t.updatedAt).inSeconds.abs() <= 8)
          .toList();
      final updatedMap =
          Map<String, List<TypingMemberStatus>>.from(state.typingByGroup);
      updatedMap[groupId] = active;
      emit(state.copyWith(typingByGroup: updatedMap));
    }, onError: (_) {});
  }

  /// Stops watching live typing indicators for [groupId].
  void stopWatchingGroupTyping(String groupId) {
    _typingSubscriptions.remove(groupId)?.cancel();
  }

  /// Updates the active user's typing heartbeat in [groupId] (supports multiple
  /// simultaneous typists while hiding self-typing from the sender UI).
  Future<void> setTypingInGroup({
    required String groupId,
    required bool isTyping,
  }) async {
    final group = state.chatGroups.where((g) => g.id == groupId).firstOrNull;
    final actor = state.currentUser;
    if (group == null || !group.memberIds.contains(actor.id)) return;

    final now = DateTime.now();
    final existing = List<TypingMemberStatus>.from(
      state.typingByGroup[groupId] ?? const [],
    ).where(
      (t) =>
          t.memberId != actor.id &&
          now.difference(t.updatedAt).inSeconds.abs() <= 8,
    ).toList();

    if (isTyping) {
      existing.add(
        TypingMemberStatus(
          groupId: groupId,
          memberId: actor.id,
          memberName: actor.name,
          avatarPath: actor.avatarPath,
          updatedAt: now,
        ),
      );
    }

    final updatedMap =
        Map<String, List<TypingMemberStatus>>.from(state.typingByGroup);
    updatedMap[groupId] = existing;
    emit(state.copyWith(typingByGroup: updatedMap));

    await repository.setGroupTypingStatus(
      groupId: groupId,
      member: actor,
      isTyping: isTyping,
    );
  }

  /// Selects or clears the active chatting group room.
  void selectChatGroup(String? groupId) {
    emit(
      state.copyWith(
        selectedChatGroupId: groupId,
        clearSelectedChatGroup: groupId == null,
      ),
    );
  }

  /// Creates a new chat group (Admin & Editor).
  Future<void> createChatGroup({
    required String name,
    required String description,
    required String imagePath,
    required List<String> memberIds,
  }) async {
    if (!state.currentUser.role.canManageGroups) return;

    final resolvedMembers = memberIds.isEmpty
        ? state.members.map((m) => m.id).toList()
        : memberIds;
    final newGroup = ChatGroupModel(
      id: 'grp_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      description: description.trim(),
      imagePath: imagePath,
      memberIds: resolvedMembers,
      adminId: state.currentUser.id,
      adminName: state.currentUser.name,
      isPinned: false,
      createdAt: DateTime.now(),
    );

    final updatedGroups = [newGroup, ...state.chatGroups];
    final recipients = newGroup.memberIds
        .where((id) => id != state.currentUser.id)
        .toList();
    if (recipients.isNotEmpty) {
      pushNotification(
        title: 'تمت إضافتك لمجموعة جديدة 💬',
        description:
            'قام ${state.currentUser.name} بإنشاء مجموعة "${newGroup.name}" وإضافتك إليها.',
        category: NotificationCategory.chat,
        tone: LmtNotificationTone.chatMessage,
        targetTabIndex: 1,
        targetGroupId: newGroup.id,
        targetMemberIds: recipients,
        excludedMemberIds: [state.currentUser.id],
      );
    }

    emit(state.copyWith(chatGroups: updatedGroups));
    await persistState();
  }

  /// Updates an existing chat group's details and notifies ONLY newly added
  /// members (never existing members or the editor/admin making the change).
  Future<void> updateChatGroup(ChatGroupModel updatedGroup) async {
    if (!state.currentUser.role.canManageGroups) return;
    final previousGroup =
        state.chatGroups.where((g) => g.id == updatedGroup.id).firstOrNull;

    final updatedGroups = state.chatGroups
        .map((g) => g.id == updatedGroup.id ? updatedGroup : g)
        .toList();

    if (previousGroup != null) {
      final newlyAddedIds = updatedGroup.memberIds
          .where(
            (id) =>
                id != state.currentUser.id &&
                !previousGroup.memberIds.contains(id),
          )
          .toList();
      if (newlyAddedIds.isNotEmpty) {
        pushNotification(
          title: 'تمت إضافتك لمجموعة "${updatedGroup.name}" 💬',
          description:
              'قام ${state.currentUser.name} بإضافتك إلى مجموعة "${updatedGroup.name}".',
          category: NotificationCategory.chat,
          tone: LmtNotificationTone.chatMessage,
          targetTabIndex: 1,
          targetGroupId: updatedGroup.id,
          targetMemberIds: newlyAddedIds,
          excludedMemberIds: [state.currentUser.id],
        );
      }
    }

    emit(state.copyWith(chatGroups: updatedGroups));
    await persistState();
  }

  /// Deletes a chat group and its associated messages (Administrator ONLY).
  Future<void> deleteChatGroup(String groupId) async {
    if (!state.currentUser.role.canDeleteGroups) return;
    final updatedGroups =
        state.chatGroups.where((g) => g.id != groupId).toList();
    final updatedMessages =
        state.chatMessages.where((m) => m.groupId != groupId).toList();
    emit(
      state.copyWith(
        chatGroups: updatedGroups,
        chatMessages: updatedMessages,
        clearSelectedChatGroup: state.selectedChatGroupId == groupId,
      ),
    );
    await persistState();
  }

  /// Toggles the pinned status of a chat group.
  Future<void> togglePinChatGroup(String groupId) async {
    final updatedGroups = state.chatGroups.map((g) {
      if (g.id == groupId) {
        return g.copyWith(isPinned: !g.isPinned);
      }
      return g;
    }).toList();
    emit(state.copyWith(chatGroups: updatedGroups));
    await persistState();
  }

  /// Sends a text, voice note, image, file, or sticker message to [groupId].
  ///
  /// Starts with an empty `seenBy` list so only real group members who enter
  /// the conversation room appear in the Seen list (excluding the sender).
  Future<void> sendChatMessage({
    required String groupId,
    required MessageType type,
    required String content,
    String? attachmentPath,
    String? fileSize,
    int? voiceDurationSeconds,
    ChatMessageModel? replyTo,
  }) async {
    final now = DateTime.now();
    final senderId = state.currentUser.id;

    final message = ChatMessageModel(
      id: 'msg_${now.millisecondsSinceEpoch}',
      groupId: groupId,
      senderId: senderId,
      senderName: state.currentUser.name,
      senderAvatar: state.currentUser.avatarPath,
      senderRole: state.currentUser.role,
      type: type,
      content: content,
      attachmentPath: attachmentPath,
      fileSize: fileSize,
      voiceDurationSeconds: voiceDurationSeconds,
      replyToMessageId: replyTo?.id,
      replyToSenderName: replyTo?.senderName,
      replyToPreview: replyTo == null
          ? null
          : (replyTo.content.trim().isNotEmpty
              ? replyTo.content
              : _messagePreviewText(replyTo.type, replyTo.content)),
      seenBy: const [],
      sentAt: now,
    );

    final updatedMessages = [...state.chatMessages, message];
    emit(state.copyWith(chatMessages: updatedMessages));

    final group = state.chatGroups.where((g) => g.id == groupId).firstOrNull;
    if (group != null) {
      final recipients =
          group.memberIds.where((id) => id != senderId).toList();
      if (recipients.isNotEmpty) {
        final preview = _messagePreviewText(type, content);
        pushNotification(
          title: '${group.name} 💬',
          description: '${state.currentUser.name}: $preview',
          category: NotificationCategory.chat,
          tone: LmtNotificationTone.chatMessage,
          targetTabIndex: 1,
          targetGroupId: groupId,
          targetMemberIds: recipients,
          excludedMemberIds: [senderId],
        );
      }
    }

    await persistState();
  }

  /// Marks all messages from other members inside [groupId] as seen by the
  /// active user when they actually enter the group conversation room.
  ///
  /// Never records a member as having seen their own sent messages.
  Future<void> markGroupMessagesSeen(String groupId) async {
    final group = state.chatGroups.where((g) => g.id == groupId).firstOrNull;
    final viewer = state.currentUser;
    if (group == null || !group.memberIds.contains(viewer.id)) return;

    final now = DateTime.now();
    var hasChanges = false;

    final updatedMessages = state.chatMessages.map((msg) {
      if (msg.groupId != groupId) return msg;

      final sanitized =
          msg.seenBy.where((s) => s.memberId != msg.senderId).toList();
      final hadSenderInSeen = sanitized.length != msg.seenBy.length;

      if (msg.senderId == viewer.id) {
        if (!hadSenderInSeen) return msg;
        hasChanges = true;
        return msg.copyWith(seenBy: sanitized);
      }

      final alreadySeen = sanitized.any((s) => s.memberId == viewer.id);
      if (alreadySeen) {
        if (!hadSenderInSeen) return msg;
        hasChanges = true;
        return msg.copyWith(seenBy: sanitized);
      }

      hasChanges = true;
      return msg.copyWith(
        seenBy: [
          ...sanitized,
          SeenStatusModel(
            memberId: viewer.id,
            memberName: viewer.name,
            avatarPath: viewer.avatarPath,
            timestamp: now,
            hasListened: false,
          ),
        ],
      );
    }).toList();

    if (!hasChanges) return;
    emit(state.copyWith(chatMessages: updatedMessages));
    await persistState();
  }

  /// Records that the current user listened to a voice note message (only when
  /// they are not the sender).
  Future<void> markVoiceNoteListened(String messageId) async {
    final viewer = state.currentUser;
    var hasChanges = false;
    final now = DateTime.now();

    final updatedMessages = state.chatMessages.map((msg) {
      if (msg.id != messageId || msg.senderId == viewer.id) return msg;

      final group =
          state.chatGroups.where((g) => g.id == msg.groupId).firstOrNull;
      if (group == null || !group.memberIds.contains(viewer.id)) return msg;

      final existingIdx =
          msg.seenBy.indexWhere((s) => s.memberId == viewer.id);
      if (existingIdx == -1) {
        hasChanges = true;
        return msg.copyWith(
          seenBy: [
            ...msg.seenBy.where((s) => s.memberId != msg.senderId),
            SeenStatusModel(
              memberId: viewer.id,
              memberName: viewer.name,
              avatarPath: viewer.avatarPath,
              timestamp: now,
              hasListened: true,
            ),
          ],
        );
      }
      if (!msg.seenBy[existingIdx].hasListened) {
        hasChanges = true;
        final updatedSeen = List<SeenStatusModel>.from(msg.seenBy);
        updatedSeen[existingIdx] =
            updatedSeen[existingIdx].copyWith(hasListened: true);
        return msg.copyWith(seenBy: updatedSeen);
      }
      return msg;
    }).toList();

    if (!hasChanges) return;
    emit(state.copyWith(chatMessages: updatedMessages));
    await persistState();
  }

  String _messagePreviewText(MessageType type, String content) {
    switch (type) {
      case MessageType.voiceNote:
        return 'أرسل رسالة صوتية 🎤';
      case MessageType.image:
        return content.trim().isNotEmpty ? content : 'أرسل صورة 🖼️';
      case MessageType.video:
        return content.trim().isNotEmpty ? content : 'أرسل فيديو 🎬';
      case MessageType.file:
        return content.trim().isNotEmpty ? content : 'أرسل ملفاً 📄';
      case MessageType.sticker:
        return content.trim().isNotEmpty ? content : 'أرسل ملصقاً 😊';
      case MessageType.text:
        return content;
    }
  }

  /// Toggles an emoji reaction on a chat message and notifies ONLY the message
  /// sender with the `Message_Reacts` custom tone when a reaction is added.
  Future<void> toggleMessageReaction({
    required String messageId,
    required String emoji,
  }) async {
    final userName = state.currentUser.name;
    final actorId = state.currentUser.id;
    ChatMessageModel? reactedTarget;
    var reactionAdded = false;

    final updatedMessages = state.chatMessages.map((msg) {
      if (msg.id != messageId) return msg;

      final updatedReactions = <String, List<String>>{};
      msg.reactions.forEach((key, value) {
        updatedReactions[key] = List<String>.from(value);
      });

      final currentList = updatedReactions[emoji] ?? <String>[];
      if (currentList.contains(userName)) {
        currentList.remove(userName);
        if (currentList.isEmpty) {
          updatedReactions.remove(emoji);
        } else {
          updatedReactions[emoji] = currentList;
        }
      } else {
        currentList.add(userName);
        updatedReactions[emoji] = currentList;
        reactionAdded = true;
        reactedTarget = msg;
      }

      return msg.copyWith(reactions: updatedReactions);
    }).toList();

    emit(state.copyWith(chatMessages: updatedMessages));

    if (reactionAdded &&
        reactedTarget != null &&
        reactedTarget!.senderId != actorId &&
        reactedTarget!.senderId != 'system_auto_khelwa') {
      final target = reactedTarget!;
      final groupName = state.chatGroups
              .where((g) => g.id == target.groupId)
              .map((g) => g.name)
              .firstOrNull ??
          'Group Chat';
      pushNotification(
        title: 'تفاعل جديد على رسالتك $emoji',
        description:
            'تفاعل $userName بـ $emoji على رسالتك في "$groupName".',
        category: NotificationCategory.chat,
        tone: LmtNotificationTone.messageReacts,
        targetTabIndex: 1,
        targetGroupId: target.groupId,
        targetMemberIds: [target.senderId],
        excludedMemberIds: [actorId],
      );
    }

    await persistState();
  }

  /// Forwards a message to another chat group.
  Future<void> forwardMessageToGroup({
    required ChatMessageModel message,
    required String targetGroupId,
  }) async {
    final sourceGroup = state.chatGroups
        .where((g) => g.id == message.groupId)
        .map((g) => g.name)
        .firstOrNull;

    final now = DateTime.now();
    final senderId = state.currentUser.id;
    final forwarded = ChatMessageModel(
      id: 'msg_${now.millisecondsSinceEpoch}',
      groupId: targetGroupId,
      senderId: senderId,
      senderName: state.currentUser.name,
      senderAvatar: state.currentUser.avatarPath,
      senderRole: state.currentUser.role,
      type: message.type,
      content: message.content,
      attachmentPath: message.attachmentPath,
      fileSize: message.fileSize,
      voiceDurationSeconds: message.voiceDurationSeconds,
      forwardedFromGroup: sourceGroup ?? 'Chat Group',
      seenBy: const [],
      sentAt: now,
    );

    emit(state.copyWith(chatMessages: [...state.chatMessages, forwarded]));

    final targetGroup =
        state.chatGroups.where((g) => g.id == targetGroupId).firstOrNull;
    if (targetGroup != null) {
      final recipients =
          targetGroup.memberIds.where((id) => id != senderId).toList();
      if (recipients.isNotEmpty) {
        pushNotification(
          title: '${targetGroup.name} 💬',
          description:
              'قام ${state.currentUser.name} بإعادة توجيه رسالة: ${_messagePreviewText(message.type, message.content)}',
          category: NotificationCategory.chat,
          tone: LmtNotificationTone.chatMessage,
          targetTabIndex: 1,
          targetGroupId: targetGroupId,
          targetMemberIds: recipients,
          excludedMemberIds: [senderId],
        );
      }
    }

    await persistState();
  }

  /// Maximum window after sending during which the sender may edit a message.
  static const Duration messageEditTimeLimit = Duration(minutes: 15);

  /// Returns whether the active user may currently edit [msg] (sender-only and
  /// within [messageEditTimeLimit]).
  bool canEditMessageNow(ChatMessageModel msg) {
    if (msg.senderId != state.currentUser.id) return false;
    final elapsed = DateTime.now().difference(msg.sentAt);
    return elapsed <= messageEditTimeLimit;
  }

  /// Edits a chat message (allowed only by the original sender within 15 minutes).
  Future<bool> editChatMessage({
    required String messageId,
    required String newContent,
  }) async {
    final index = state.chatMessages.indexWhere((m) => m.id == messageId);
    if (index == -1) return false;

    final msg = state.chatMessages[index];
    if (!canEditMessageNow(msg)) {
      return false;
    }

    final updated = msg.copyWith(
      content: newContent.trim(),
      isEdited: true,
    );
    final updatedList = List<ChatMessageModel>.from(state.chatMessages);
    updatedList[index] = updated;

    emit(state.copyWith(chatMessages: updatedList));
    await persistState();
    return true;
  }

  /// Deletes a chat message (allowed only by the Administrator or original sender).
  Future<bool> deleteChatMessage({
    required String messageId,
    required String groupId,
  }) async {
    final index = state.chatMessages.indexWhere((m) => m.id == messageId);
    if (index == -1) return false;

    final msg = state.chatMessages[index];
    final isSender = msg.senderId == state.currentUser.id;
    final isAdmin = state.currentUser.role == UserRole.admin;

    if (!isSender && !isAdmin) {
      return false;
    }

    final updatedList =
        state.chatMessages.where((m) => m.id != messageId).toList();
    emit(state.copyWith(chatMessages: updatedList));
    await persistState();
    return true;
  }
}
