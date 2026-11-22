import '../../../core/cubit/lmt_cubit.dart';
import '../../../core/models/lmt_models.dart';

export '../../../core/cubit/lmt_cubit.dart';

/// Feature Cubit alias for the Chatting Room feature module.
typedef ChatCubit = LmtCubit;

/// Encapsulates Chatting Room groups, pinning, messages, voice notes, stickers,
/// reactions, forwarding, editing, and deletion logic.
mixin ChatCubitMixin on LmtBaseCubit {
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

    final newGroup = ChatGroupModel(
      id: 'grp_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      description: description.trim(),
      imagePath: imagePath,
      memberIds: memberIds.isEmpty
          ? state.members.map((m) => m.id).toList()
          : memberIds,
      adminId: state.currentUser.id,
      adminName: state.currentUser.name,
      isPinned: false,
      createdAt: DateTime.now(),
    );

    final updatedGroups = [newGroup, ...state.chatGroups];
    pushNotification(
      title: 'تمت إضافتك لمجموعة جديدة 💬',
      description:
          'قام ${state.currentUser.name} بإنشاء مجموعة "${newGroup.name}" وإضافتك إليها.',
      category: NotificationCategory.chat,
      targetTabIndex: 1,
      targetGroupId: newGroup.id,
      targetMemberIds: newGroup.memberIds,
    );

    emit(state.copyWith(chatGroups: updatedGroups));
    await persistState();
  }

  /// Updates an existing chat group's details and notifies ONLY newly added
  /// members (not existing members).
  Future<void> updateChatGroup(ChatGroupModel updatedGroup) async {
    if (!state.currentUser.role.canManageGroups) return;
    final previousGroup =
        state.chatGroups.where((g) => g.id == updatedGroup.id).firstOrNull;

    final updatedGroups = state.chatGroups
        .map((g) => g.id == updatedGroup.id ? updatedGroup : g)
        .toList();

    if (previousGroup != null) {
      final newlyAddedIds = updatedGroup.memberIds
          .where((id) => !previousGroup.memberIds.contains(id))
          .toList();
      if (newlyAddedIds.isNotEmpty) {
        pushNotification(
          title: 'تمت إضافتك لمجموعة "${updatedGroup.name}" 💬',
          description:
              'قام ${state.currentUser.name} بإضافتك إلى مجموعة "${updatedGroup.name}".',
          category: NotificationCategory.chat,
          targetTabIndex: 1,
          targetGroupId: updatedGroup.id,
          targetMemberIds: newlyAddedIds,
        );
      }
    }

    emit(state.copyWith(chatGroups: updatedGroups));
    await persistState();
  }

  /// Deletes a chat group and its associated messages.
  Future<void> deleteChatGroup(String groupId) async {
    if (!state.currentUser.role.canManageGroups) return;
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
    final initialSeen = [
      SeenStatusModel(
        memberId: state.currentUser.id,
        memberName: state.currentUser.name,
        avatarPath: state.currentUser.avatarPath,
        timestamp: now,
        hasListened: type == MessageType.voiceNote,
      ),
      ...state.members
          .where((m) => m.id != state.currentUser.id)
          .take(2)
          .map(
            (m) => SeenStatusModel(
              memberId: m.id,
              memberName: m.name,
              avatarPath: m.avatarPath,
              timestamp: now.add(const Duration(seconds: 5)),
              hasListened: type == MessageType.voiceNote,
            ),
          ),
    ];

    final message = ChatMessageModel(
      id: 'msg_${now.millisecondsSinceEpoch}',
      groupId: groupId,
      senderId: state.currentUser.id,
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
      seenBy: initialSeen,
      sentAt: now,
    );

    final updatedMessages = [...state.chatMessages, message];
    emit(state.copyWith(chatMessages: updatedMessages));

    final group = state.chatGroups.where((g) => g.id == groupId).firstOrNull;
    if (group != null) {
      final preview = _messagePreviewText(type, content);
      pushNotification(
        title: '${group.name} 💬',
        description: '${state.currentUser.name}: $preview',
        category: NotificationCategory.chat,
        targetTabIndex: 1,
        targetGroupId: groupId,
        targetMemberIds: group.memberIds,
      );
    }

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

  /// Toggles an emoji reaction on a chat message.
  Future<void> toggleMessageReaction({
    required String messageId,
    required String emoji,
  }) async {
    final userName = state.currentUser.name;
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
      }

      return msg.copyWith(reactions: updatedReactions);
    }).toList();

    emit(state.copyWith(chatMessages: updatedMessages));
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
    final forwarded = ChatMessageModel(
      id: 'msg_${now.millisecondsSinceEpoch}',
      groupId: targetGroupId,
      senderId: state.currentUser.id,
      senderName: state.currentUser.name,
      senderAvatar: state.currentUser.avatarPath,
      senderRole: state.currentUser.role,
      type: message.type,
      content: message.content,
      attachmentPath: message.attachmentPath,
      fileSize: message.fileSize,
      voiceDurationSeconds: message.voiceDurationSeconds,
      forwardedFromGroup: sourceGroup ?? 'Chat Group',
      seenBy: [
        SeenStatusModel(
          memberId: state.currentUser.id,
          memberName: state.currentUser.name,
          avatarPath: state.currentUser.avatarPath,
          timestamp: now,
          hasListened: message.type == MessageType.voiceNote,
        ),
      ],
      sentAt: now,
    );

    emit(state.copyWith(chatMessages: [...state.chatMessages, forwarded]));

    final targetGroup =
        state.chatGroups.where((g) => g.id == targetGroupId).firstOrNull;
    if (targetGroup != null) {
      pushNotification(
        title: '${targetGroup.name} 💬',
        description:
            'قام ${state.currentUser.name} بإعادة توجيه رسالة: ${_messagePreviewText(message.type, message.content)}',
        category: NotificationCategory.chat,
        targetTabIndex: 1,
        targetGroupId: targetGroupId,
        targetMemberIds: targetGroup.memberIds,
      );
    }

    await persistState();
  }

  /// Edits a chat message (allowed only by the original sender).
  Future<bool> editChatMessage({
    required String messageId,
    required String newContent,
  }) async {
    final index = state.chatMessages.indexWhere((m) => m.id == messageId);
    if (index == -1) return false;

    final msg = state.chatMessages[index];
    if (msg.senderId != state.currentUser.id) {
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

  /// Deletes a chat message (allowed only by the group admin or original sender).
  Future<bool> deleteChatMessage({
    required String messageId,
    required String groupId,
  }) async {
    final index = state.chatMessages.indexWhere((m) => m.id == messageId);
    if (index == -1) return false;

    final msg = state.chatMessages[index];
    final group = state.chatGroups.where((g) => g.id == groupId).firstOrNull;
    final isSender = msg.senderId == state.currentUser.id;
    final isGroupAdmin = group?.adminId == state.currentUser.id ||
        state.currentUser.role == UserRole.admin;

    if (!isSender && !isGroupAdmin) {
      return false;
    }

    final updatedList =
        state.chatMessages.where((m) => m.id != messageId).toList();
    emit(state.copyWith(chatMessages: updatedList));
    await persistState();
    return true;
  }
}
