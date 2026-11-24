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
  static int _outgoingMessageSeq = 0;
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
    List<String> groupAdminIds = const [],
  }) async {
    if (!state.currentUser.role.canManageGroups) return;

    final resolvedMembers = memberIds.isEmpty
        ? state.members.map((m) => m.id).toList()
        : memberIds.toSet().toList();
    final creatorId = state.currentUser.id;
    final normalizedAdmins = <String>{
      if (resolvedMembers.contains(creatorId)) creatorId,
      ...groupAdminIds.where(resolvedMembers.contains),
    }.toList();

    final newGroup = ChatGroupModel(
      id: 'grp_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      description: description.trim(),
      imagePath: imagePath,
      memberIds: resolvedMembers,
      groupAdminIds: normalizedAdmins,
      adminId: creatorId,
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
  ///
  /// Authorized ONLY for Group Admins of this group or Global App Admins
  /// (`UserRole.admin`).
  Future<void> updateChatGroup(ChatGroupModel updatedGroup) async {
    final previousGroup =
        state.chatGroups.where((g) => g.id == updatedGroup.id).firstOrNull;
    final canEdit = previousGroup?.canUserEditGroup(state.currentUser) ??
        state.currentUser.role.canManageGroups;
    if (!canEdit) return;

    final cleanMembers = updatedGroup.memberIds.toSet().toList();
    final cleanedCoAdmins = updatedGroup.groupAdminIds
        .where((id) => cleanMembers.contains(id))
        .toList();
    var resolvedAdminId = updatedGroup.adminId;
    var resolvedAdminName = updatedGroup.adminName;
    if (cleanMembers.isNotEmpty && !cleanMembers.contains(resolvedAdminId)) {
      resolvedAdminId = cleanedCoAdmins.isNotEmpty
          ? cleanedCoAdmins.first
          : cleanMembers.first;
      resolvedAdminName = state.members
              .where((m) => m.id == resolvedAdminId)
              .map((m) => m.name)
              .firstOrNull ??
          resolvedAdminName;
    }

    final normalizedAdmins = <String>{
      if (cleanMembers.contains(resolvedAdminId)) resolvedAdminId,
      ...cleanedCoAdmins,
    }.toList();

    final normalizedGroup = updatedGroup.copyWith(
      memberIds: cleanMembers,
      groupAdminIds: normalizedAdmins,
      adminId: resolvedAdminId,
      adminName: resolvedAdminName,
    );

    final updatedGroups = state.chatGroups
        .map((g) => g.id == normalizedGroup.id ? normalizedGroup : g)
        .toList();

    if (previousGroup != null) {
      final newlyAddedIds = normalizedGroup.memberIds
          .where(
            (id) =>
                id != state.currentUser.id &&
                !previousGroup.memberIds.contains(id),
          )
          .toList();
      if (newlyAddedIds.isNotEmpty) {
        pushNotification(
          title: 'تمت إضافتك لمجموعة "${normalizedGroup.name}" 💬',
          description:
              'قام ${state.currentUser.name} بإضافتك إلى مجموعة "${normalizedGroup.name}".',
          category: NotificationCategory.chat,
          tone: LmtNotificationTone.chatMessage,
          targetTabIndex: 1,
          targetGroupId: normalizedGroup.id,
          targetMemberIds: newlyAddedIds,
          excludedMemberIds: [state.currentUser.id],
        );
      }
    }

    emit(state.copyWith(chatGroups: updatedGroups));
    await persistState();
  }

  /// Grants or revokes Group Admin authority for [memberId] inside [groupId].
  ///
  /// Multiple members can hold Group Admin rights simultaneously alongside the
  /// creator/owner. If revoking from the primary owner (`adminId`) when other
  /// group admins exist, ownership advances to the next remaining admin.
  Future<void> setGroupMemberAdmin({
    required String groupId,
    required String memberId,
    required bool isAdmin,
  }) async {
    final group = state.chatGroups.where((g) => g.id == groupId).firstOrNull;
    if (group == null || !group.canUserEditGroup(state.currentUser)) return;
    if (!group.memberIds.contains(memberId)) return;

    final admins = List<String>.from(group.effectiveAdminIds);
    var nextOwnerId = group.adminId;
    var nextOwnerName = group.adminName;

    if (isAdmin) {
      if (!admins.contains(memberId)) {
        admins.add(memberId);
      }
    } else {
      final remainingOtherAdmins =
          admins.where((id) => id != memberId).toList();
      if (memberId == group.adminId && remainingOtherAdmins.isEmpty) {
        return; // Cannot leave primary group owner role empty while alone as admin
      }
      admins.remove(memberId);
      if (memberId == group.adminId && remainingOtherAdmins.isNotEmpty) {
        nextOwnerId = remainingOtherAdmins.first;
        nextOwnerName = state.members
                .where((m) => m.id == nextOwnerId)
                .map((m) => m.name)
                .firstOrNull ??
            nextOwnerName;
      }
    }

    final updatedGroup = group.copyWith(
      adminId: nextOwnerId,
      adminName: nextOwnerName,
      groupAdminIds: admins,
    );
    final updatedGroups =
        state.chatGroups.map((g) => g.id == groupId ? updatedGroup : g).toList();
    emit(state.copyWith(chatGroups: updatedGroups));
    await persistState();
  }

  /// Transfers primary group leadership to [newOwnerId]. When [stepDownSelf]
  /// is `true`, the current actor steps down as group admin so [newOwnerId]
  /// acts in their place ("بدالي").
  Future<void> transferGroupOwnership({
    required String groupId,
    required String newOwnerId,
    bool stepDownSelf = true,
  }) async {
    final group = state.chatGroups.where((g) => g.id == groupId).firstOrNull;
    if (group == null || !group.canUserEditGroup(state.currentUser)) return;
    if (!group.memberIds.contains(newOwnerId)) return;

    final nextOwnerName = state.members
            .where((m) => m.id == newOwnerId)
            .map((m) => m.name)
            .firstOrNull ??
        group.adminName;
    final actorId = state.currentUser.id;
    final nextAdmins = <String>{
      newOwnerId,
      ...group.effectiveAdminIds.where(
        (id) =>
            group.memberIds.contains(id) &&
            (!stepDownSelf || id != actorId || actorId == newOwnerId),
      ),
    }.toList();

    final updatedGroup = group.copyWith(
      adminId: newOwnerId,
      adminName: nextOwnerName,
      groupAdminIds: nextAdmins,
    );
    final updatedGroups =
        state.chatGroups.map((g) => g.id == groupId ? updatedGroup : g).toList();
    emit(state.copyWith(chatGroups: updatedGroups));
    await persistState();
  }

  /// Removes the active user from [groupId].
  ///
  /// When the leaving user is the primary group creator/owner (`adminId`),
  /// leadership automatically transfers with priority:
  /// 1. The first remaining Group Admin in `groupAdminIds`.
  /// 2. Otherwise the earliest added remaining member in `memberIds`.
  Future<void> leaveChatGroup(String groupId) async {
    final actor = state.currentUser;
    final group = state.chatGroups.where((g) => g.id == groupId).firstOrNull;
    if (group == null || !group.memberIds.contains(actor.id)) return;

    final remainingMembers =
        group.memberIds.where((id) => id != actor.id).toList();
    final remainingAdmins = group.effectiveAdminIds
        .where((id) => id != actor.id && remainingMembers.contains(id))
        .toList();

    late final ChatGroupModel updatedGroup;
    if (remainingMembers.isEmpty) {
      updatedGroup = group.copyWith(
        memberIds: const [],
        groupAdminIds: const [],
      );
    } else if (actor.id == group.adminId) {
      final successorId = remainingAdmins.isNotEmpty
          ? remainingAdmins.first
          : remainingMembers.first;
      final successorName = state.members
              .where((m) => m.id == successorId)
              .map((m) => m.name)
              .firstOrNull ??
          group.adminName;
      final nextAdmins = <String>{
        successorId,
        ...remainingAdmins,
      }.toList();
      updatedGroup = group.copyWith(
        memberIds: remainingMembers,
        adminId: successorId,
        adminName: successorName,
        groupAdminIds: nextAdmins,
      );
    } else {
      updatedGroup = group.copyWith(
        memberIds: remainingMembers,
        groupAdminIds: remainingAdmins,
      );
    }

    final updatedGroups =
        state.chatGroups.map((g) => g.id == groupId ? updatedGroup : g).toList();
    emit(
      state.copyWith(
        chatGroups: updatedGroups,
        clearSelectedChatGroup: state.selectedChatGroupId == groupId,
      ),
    );
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
    final rawPreview = replyTo == null
        ? null
        : (replyTo.content.trim().isNotEmpty
            ? replyTo.content.trim()
            : _messagePreviewText(replyTo.type, replyTo.content));
    final safePreview = rawPreview == null
        ? null
        : (rawPreview.length <= 1000
            ? rawPreview
            : rawPreview.substring(0, 1000));
    final safeReplySender = replyTo?.senderName.trim();
    final boundedReplySender =
        (safeReplySender == null || safeReplySender.isEmpty)
            ? null
            : (safeReplySender.length <= 120
                ? safeReplySender
                : safeReplySender.substring(0, 120));

    final message = ChatMessageModel(
      id: 'msg_${now.microsecondsSinceEpoch}_${++_outgoingMessageSeq}',
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
      replyToSenderName: boundedReplySender,
      replyToPreview: safePreview,
      seenBy: const [],
      sentAt: now,
    );

    pendingOutgoingMessages[message.id] = message;
    final updatedMessages = [...state.chatMessages, message];
    emit(state.copyWith(chatMessages: updatedMessages));

    AppNotificationModel? sentNotification;
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
        sentNotification = state.notifications.firstOrNull;
      }
    }

    await repository.persistLocalSnapshot(
      stateJson: state.toJson(),
      currentUserId: senderId,
    );
    await repository.sendChatMessageToCloud(
      message: message,
      notification: sentNotification,
    );
  }

  /// Marks all messages from other members inside [groupId] as seen by the
  /// active user when they actually enter the group conversation room.
  ///
  /// Never records a member as having seen their own sent messages.
  Future<void> markGroupMessagesSeen(
    String groupId, {
    Set<String>? onlyMessageIds,
  }) async {
    final group = state.chatGroups.where((g) => g.id == groupId).firstOrNull;
    final viewer = state.currentUser;
    if (group == null || !group.memberIds.contains(viewer.id)) return;

    final now = DateTime.now();
    var hasChanges = false;

    final updatedMessages = state.chatMessages.map((msg) {
      if (msg.groupId != groupId) return msg;
      if (onlyMessageIds != null && !onlyMessageIds.contains(msg.id)) {
        return msg;
      }

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
    final viewerReceipt = SeenStatusModel(
      memberId: viewer.id,
      memberName: viewer.name,
      avatarPath: viewer.avatarPath,
      timestamp: now,
      hasListened: false,
    );
    final changedMessages = updatedMessages
        .where(
          (m) =>
              m.groupId == groupId &&
              m.senderId != viewer.id &&
              m.seenBy.any(
                (s) => s.memberId == viewer.id && s.timestamp == now,
              ),
        )
        .toList();

    emit(state.copyWith(chatMessages: updatedMessages));
    await repository.persistLocalSnapshot(
      stateJson: state.toJson(),
      currentUserId: viewer.id,
    );
    await repository.markMessagesSeenInCloud(
      updatedMessages: changedMessages,
      viewerReceipt: viewerReceipt,
    );
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
    final safeForwardSource = (sourceGroup ?? 'Chat Group').trim();
    final boundedForwardSource = safeForwardSource.isEmpty
        ? 'Chat Group'
        : (safeForwardSource.length <= 150
            ? safeForwardSource
            : safeForwardSource.substring(0, 150));
    final forwarded = ChatMessageModel(
      id: 'msg_${now.microsecondsSinceEpoch}_${++_outgoingMessageSeq}',
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
      forwardedFromGroup: boundedForwardSource,
      seenBy: const [],
      sentAt: now,
    );

    pendingOutgoingMessages[forwarded.id] = forwarded;
    emit(state.copyWith(chatMessages: [...state.chatMessages, forwarded]));

    AppNotificationModel? sentNotification;
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
        sentNotification = state.notifications.firstOrNull;
      }
    }

    await repository.persistLocalSnapshot(
      stateJson: state.toJson(),
      currentUserId: senderId,
    );
    await repository.sendChatMessageToCloud(
      message: forwarded,
      notification: sentNotification,
    );
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
    if (pendingOutgoingMessages.containsKey(updated.id)) {
      pendingOutgoingMessages[updated.id] = updated;
    }
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

    pendingOutgoingMessages.remove(messageId);
    final updatedList =
        state.chatMessages.where((m) => m.id != messageId).toList();
    emit(state.copyWith(chatMessages: updatedList));
    await persistState();
    return true;
  }
}
