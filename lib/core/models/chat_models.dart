import 'package:equatable/equatable.dart';

import '../utils/app_assets.dart';
import 'user_role.dart';

/// Supported message content types inside a chatting group.
enum MessageType {
  text,
  voiceNote,
  image,
  video,
  file,
  sticker;

  /// Parses a [MessageType] from its string [value].
  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MessageType.text,
    );
  }
}

/// Tracks when a member has seen or listened to a chat message.
class SeenStatusModel extends Equatable {
  /// The unique ID of the member who viewed the message.
  final String memberId;

  /// The display name of the member.
  final String memberName;

  /// The avatar path of the member.
  final String avatarPath;

  /// The timestamp when the message was seen or listened to.
  final DateTime timestamp;

  /// Whether the member has listened to the voice note attachment.
  final bool hasListened;

  /// Creates a [SeenStatusModel].
  const SeenStatusModel({
    required this.memberId,
    required this.memberName,
    this.avatarPath = AppAssets.accountIcon,
    required this.timestamp,
    this.hasListened = false,
  });

  /// Creates a copy of this status with updated fields.
  SeenStatusModel copyWith({
    String? memberId,
    String? memberName,
    String? avatarPath,
    DateTime? timestamp,
    bool? hasListened,
  }) {
    return SeenStatusModel(
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      avatarPath: avatarPath ?? this.avatarPath,
      timestamp: timestamp ?? this.timestamp,
      hasListened: hasListened ?? this.hasListened,
    );
  }

  /// Serializes this status to a JSON map.
  Map<String, dynamic> toJson() => {
        'memberId': memberId,
        'memberName': memberName,
        'avatarPath': avatarPath,
        'timestamp': timestamp.toIso8601String(),
        'hasListened': hasListened,
      };

  /// Deserializes a [SeenStatusModel] from a JSON map.
  factory SeenStatusModel.fromJson(Map<String, dynamic> json) =>
      SeenStatusModel(
        memberId: json['memberId'] as String? ?? '',
        memberName: json['memberName'] as String? ?? '',
        avatarPath: json['avatarPath'] as String? ?? AppAssets.accountIcon,
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
        hasListened: json['hasListened'] as bool? ?? false,
      );

  @override
  List<Object?> get props =>
      [memberId, memberName, avatarPath, timestamp, hasListened];
}

/// Tracks an active member typing in a group chat (synced for other members).
class TypingMemberStatus extends Equatable {
  /// The chat group ID where typing is active.
  final String groupId;

  /// The typing member's ID.
  final String memberId;

  /// The typing member's display name.
  final String memberName;

  /// The typing member's circular avatar path.
  final String avatarPath;

  /// Timestamp of the latest typing heartbeat.
  final DateTime updatedAt;

  /// Creates a [TypingMemberStatus].
  const TypingMemberStatus({
    required this.groupId,
    required this.memberId,
    required this.memberName,
    this.avatarPath = AppAssets.accountIcon,
    required this.updatedAt,
  });

  /// Serializes this typing heartbeat to JSON.
  Map<String, dynamic> toJson() => {
        'id': '${groupId}_$memberId',
        'groupId': groupId,
        'memberId': memberId,
        'memberName': memberName,
        'avatarPath': avatarPath,
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// Deserializes a [TypingMemberStatus] from JSON.
  factory TypingMemberStatus.fromJson(Map<String, dynamic> json) =>
      TypingMemberStatus(
        groupId: json['groupId'] as String? ?? '',
        memberId: json['memberId'] as String? ?? '',
        memberName: json['memberName'] as String? ?? '',
        avatarPath: json['avatarPath'] as String? ?? AppAssets.accountIcon,
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );

  @override
  List<Object?> get props =>
      [groupId, memberId, memberName, avatarPath, updatedAt];
}

/// Represents an individual message inside a chatting group.
class ChatMessageModel extends Equatable {
  /// The unique identifier of the message.
  final String id;

  /// The ID of the group where this message was sent.
  final String groupId;

  /// The ID of the member who sent the message.
  final String senderId;

  /// The display name of the sender.
  final String senderName;

  /// The avatar path of the sender.
  final String senderAvatar;

  /// The authorization role of the sender.
  final UserRole senderRole;

  /// The content type of the message.
  final MessageType type;

  /// The text content or caption of the message.
  final String content;

  /// Optional path to an attached image, file, or sticker.
  final String? attachmentPath;

  /// Optional human-readable file size for file attachments.
  final String? fileSize;

  /// Optional duration in seconds for voice notes.
  final int? voiceDurationSeconds;

  /// Optional ID of the message being replied to.
  final String? replyToMessageId;

  /// Optional sender name of the message being replied to.
  final String? replyToSenderName;

  /// Optional text preview of the message being replied to.
  final String? replyToPreview;

  /// Optional source group name if the message was forwarded.
  final String? forwardedFromGroup;

  /// Whether the message text has been edited by its sender.
  final bool isEdited;

  /// Map of emoji reactions to lists of member names who reacted.
  final Map<String, List<String>> reactions;

  /// List of members who have seen or listened to this message.
  final List<SeenStatusModel> seenBy;

  /// The timestamp when the message was sent.
  final DateTime sentAt;

  /// Creates a [ChatMessageModel].
  const ChatMessageModel({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar = AppAssets.accountIcon,
    this.senderRole = UserRole.member,
    this.type = MessageType.text,
    required this.content,
    this.attachmentPath,
    this.fileSize,
    this.voiceDurationSeconds,
    this.replyToMessageId,
    this.replyToSenderName,
    this.replyToPreview,
    this.forwardedFromGroup,
    this.isEdited = false,
    this.reactions = const {},
    this.seenBy = const [],
    required this.sentAt,
  });

  /// Creates a copy of this message with updated fields.
  ChatMessageModel copyWith({
    String? id,
    String? groupId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    UserRole? senderRole,
    MessageType? type,
    String? content,
    String? attachmentPath,
    String? fileSize,
    int? voiceDurationSeconds,
    String? replyToMessageId,
    String? replyToSenderName,
    String? replyToPreview,
    String? forwardedFromGroup,
    bool? isEdited,
    Map<String, List<String>>? reactions,
    List<SeenStatusModel>? seenBy,
    DateTime? sentAt,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      senderRole: senderRole ?? this.senderRole,
      type: type ?? this.type,
      content: content ?? this.content,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      fileSize: fileSize ?? this.fileSize,
      voiceDurationSeconds: voiceDurationSeconds ?? this.voiceDurationSeconds,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToSenderName: replyToSenderName ?? this.replyToSenderName,
      replyToPreview: replyToPreview ?? this.replyToPreview,
      forwardedFromGroup: forwardedFromGroup ?? this.forwardedFromGroup,
      isEdited: isEdited ?? this.isEdited,
      reactions: reactions ?? this.reactions,
      seenBy: seenBy ?? this.seenBy,
      sentAt: sentAt ?? this.sentAt,
    );
  }

  /// Serializes this message to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'groupId': groupId,
        'senderId': senderId,
        'senderName': senderName,
        'senderAvatar': senderAvatar,
        'senderRole': senderRole.name,
        'type': type.name,
        'content': content,
        'attachmentPath': attachmentPath,
        'fileSize': fileSize,
        'voiceDurationSeconds': voiceDurationSeconds,
        'replyToMessageId': replyToMessageId,
        'replyToSenderName': replyToSenderName,
        'replyToPreview': replyToPreview,
        'forwardedFromGroup': forwardedFromGroup,
        'isEdited': isEdited,
        'reactions': reactions,
        'seenBy': seenBy.map((e) => e.toJson()).toList(),
        'sentAt': sentAt.toIso8601String(),
      };

  /// Deserializes a [ChatMessageModel] from a JSON map.
  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final rawReactions = json['reactions'] as Map<String, dynamic>? ?? {};
    final parsedReactions = <String, List<String>>{};
    rawReactions.forEach((key, value) {
      if (value is List) {
        parsedReactions[key] = value.map((e) => e.toString()).toList();
      }
    });

    return ChatMessageModel(
      id: json['id'] as String? ?? '',
      groupId: json['groupId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      senderName: json['senderName'] as String? ?? '',
      senderAvatar: json['senderAvatar'] as String? ?? AppAssets.accountIcon,
      senderRole: UserRole.fromString(json['senderRole'] as String? ?? 'member'),
      type: MessageType.fromString(json['type'] as String? ?? 'text'),
      content: json['content'] as String? ?? '',
      attachmentPath: json['attachmentPath'] as String?,
      fileSize: json['fileSize'] as String?,
      voiceDurationSeconds: json['voiceDurationSeconds'] as int?,
      replyToMessageId: json['replyToMessageId'] as String?,
      replyToSenderName: json['replyToSenderName'] as String?,
      replyToPreview: json['replyToPreview'] as String?,
      forwardedFromGroup: json['forwardedFromGroup'] as String?,
      isEdited: json['isEdited'] as bool? ?? false,
      reactions: parsedReactions,
      seenBy: (json['seenBy'] as List<dynamic>?)
              ?.map((e) => SeenStatusModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      sentAt: DateTime.tryParse(json['sentAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        groupId,
        senderId,
        senderName,
        type,
        content,
        attachmentPath,
        fileSize,
        voiceDurationSeconds,
        replyToMessageId,
        forwardedFromGroup,
        isEdited,
        reactions,
        seenBy,
        sentAt,
      ];
}

/// Represents a chatting group with its members, image, creator, and pin state.
class ChatGroupModel extends Equatable {
  /// The unique identifier of the group.
  final String id;

  /// The display title of the group.
  final String name;

  /// A brief description of the group's purpose.
  final String description;

  /// The asset or local file path for the group's avatar image.
  final String imagePath;

  /// List of member IDs participating in this group.
  final List<String> memberIds;

  /// The member ID of the group creator/administrator.
  final String adminId;

  /// The display name of the group creator/administrator.
  final String adminName;

  /// Whether this group is pinned to the top of the groups query.
  final bool isPinned;

  /// The creation timestamp of the group.
  final DateTime createdAt;

  /// Creates a [ChatGroupModel].
  const ChatGroupModel({
    required this.id,
    required this.name,
    required this.description,
    this.imagePath = AppAssets.actIcon,
    required this.memberIds,
    required this.adminId,
    required this.adminName,
    this.isPinned = false,
    required this.createdAt,
  });

  /// Creates a copy of this group with updated fields.
  ChatGroupModel copyWith({
    String? id,
    String? name,
    String? description,
    String? imagePath,
    List<String>? memberIds,
    String? adminId,
    String? adminName,
    bool? isPinned,
    DateTime? createdAt,
  }) {
    return ChatGroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      memberIds: memberIds ?? this.memberIds,
      adminId: adminId ?? this.adminId,
      adminName: adminName ?? this.adminName,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Serializes this group to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'imagePath': imagePath,
        'memberIds': memberIds,
        'adminId': adminId,
        'adminName': adminName,
        'isPinned': isPinned,
        'createdAt': createdAt.toIso8601String(),
      };

  /// Deserializes a [ChatGroupModel] from a JSON map.
  factory ChatGroupModel.fromJson(Map<String, dynamic> json) => ChatGroupModel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        imagePath: json['imagePath'] as String? ?? AppAssets.actIcon,
        memberIds: (json['memberIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        adminId: json['adminId'] as String? ?? 'LMT-001',
        adminName: json['adminName'] as String? ?? 'Admin',
        isPinned: json['isPinned'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        imagePath,
        memberIds,
        adminId,
        adminName,
        isPinned,
        createdAt,
      ];
}
