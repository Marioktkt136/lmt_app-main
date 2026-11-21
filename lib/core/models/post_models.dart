import 'package:equatable/equatable.dart';

import '../utils/app_assets.dart';
import 'user_role.dart';

/// Categories of timeline posts supported in the L.M.T feed.
enum PostCategoryType {
  simple,
  poll,
  media;

  /// Parses a [PostCategoryType] from its string [value].
  static PostCategoryType fromString(String value) {
    return PostCategoryType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PostCategoryType.simple,
    );
  }
}

/// Represents a selectable voting option inside a poll post.
class PollOptionModel extends Equatable {
  /// The unique identifier of the option.
  final String id;

  /// The display text of the option.
  final String text;

  /// List of member IDs who voted for this option.
  final List<String> voterIds;

  /// Creates a [PollOptionModel].
  const PollOptionModel({
    required this.id,
    required this.text,
    this.voterIds = const [],
  });

  /// Creates a copy of this poll option with updated fields.
  PollOptionModel copyWith({
    String? id,
    String? text,
    List<String>? voterIds,
  }) {
    return PollOptionModel(
      id: id ?? this.id,
      text: text ?? this.text,
      voterIds: voterIds ?? this.voterIds,
    );
  }

  /// Serializes this poll option to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'voterIds': voterIds,
      };

  /// Deserializes a [PollOptionModel] from a JSON map.
  factory PollOptionModel.fromJson(Map<String, dynamic> json) =>
      PollOptionModel(
        id: json['id'] as String? ?? '',
        text: json['text'] as String? ?? '',
        voterIds: (json['voterIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );

  @override
  List<Object?> get props => [id, text, voterIds];
}

/// Represents a member's comment on a timeline post.
class PostCommentModel extends Equatable {
  /// The unique identifier of the comment.
  final String id;

  /// The member ID of the comment author.
  final String authorId;

  /// The display name of the comment author.
  final String authorName;

  /// The avatar path of the comment author.
  final String authorAvatar;

  /// The authorization role of the comment author.
  final UserRole authorRole;

  /// The text content of the comment.
  final String content;

  /// The timestamp when the comment was created.
  final DateTime createdAt;

  /// Creates a [PostCommentModel].
  const PostCommentModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatar = AppAssets.accountIcon,
    this.authorRole = UserRole.member,
    required this.content,
    required this.createdAt,
  });

  /// Serializes this comment to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'authorId': authorId,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'authorRole': authorRole.name,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
      };

  /// Deserializes a [PostCommentModel] from a JSON map.
  factory PostCommentModel.fromJson(Map<String, dynamic> json) =>
      PostCommentModel(
        id: json['id'] as String? ?? '',
        authorId: json['authorId'] as String? ?? '',
        authorName: json['authorName'] as String? ?? '',
        authorAvatar: json['authorAvatar'] as String? ?? AppAssets.accountIcon,
        authorRole:
            UserRole.fromString(json['authorRole'] as String? ?? 'member'),
        content: json['content'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );

  @override
  List<Object?> get props =>
      [id, authorId, authorName, authorRole, content, createdAt];
}

/// Represents a timeline announcement post (Simple, Poll, or Image/Video).
class PostModel extends Equatable {
  /// The unique identifier of the post.
  final String id;

  /// The member ID of the post creator.
  final String creatorId;

  /// The display name of the post creator.
  final String creatorName;

  /// The avatar path of the post creator.
  final String creatorAvatar;

  /// The authorization role of the post creator.
  final UserRole creatorRole;

  /// The committee of the post creator.
  final String creatorCommittee;

  /// The publication date and time of the post.
  final DateTime publishTime;

  /// The category type of the post.
  final PostCategoryType type;

  /// The main text content of the post.
  final String content;

  /// Optional image or media thumbnail path.
  final String? mediaPath;

  /// Whether the attached media is a video.
  final bool isVideo;

  /// Optional external video URL.
  final String? videoUrl;

  /// List of poll options if [type] is [PostCategoryType.poll].
  final List<PollOptionModel> pollOptions;

  /// List of member IDs who liked the post.
  final List<String> likedByIds;

  /// List of comments on the post.
  final List<PostCommentModel> comments;

  /// Creates a [PostModel].
  const PostModel({
    required this.id,
    required this.creatorId,
    required this.creatorName,
    this.creatorAvatar = AppAssets.accountIcon,
    this.creatorRole = UserRole.member,
    this.creatorCommittee = 'Artistic Committee',
    required this.publishTime,
    required this.type,
    required this.content,
    this.mediaPath,
    this.isVideo = false,
    this.videoUrl,
    this.pollOptions = const [],
    this.likedByIds = const [],
    this.comments = const [],
  });

  /// Total number of votes cast across all options in this poll.
  int get totalPollVotes =>
      pollOptions.fold(0, (sum, option) => sum + option.voterIds.length);

  /// Creates a copy of this post with updated fields.
  PostModel copyWith({
    String? id,
    String? creatorId,
    String? creatorName,
    String? creatorAvatar,
    UserRole? creatorRole,
    String? creatorCommittee,
    DateTime? publishTime,
    PostCategoryType? type,
    String? content,
    String? mediaPath,
    bool? isVideo,
    String? videoUrl,
    List<PollOptionModel>? pollOptions,
    List<String>? likedByIds,
    List<PostCommentModel>? comments,
  }) {
    return PostModel(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      creatorAvatar: creatorAvatar ?? this.creatorAvatar,
      creatorRole: creatorRole ?? this.creatorRole,
      creatorCommittee: creatorCommittee ?? this.creatorCommittee,
      publishTime: publishTime ?? this.publishTime,
      type: type ?? this.type,
      content: content ?? this.content,
      mediaPath: mediaPath ?? this.mediaPath,
      isVideo: isVideo ?? this.isVideo,
      videoUrl: videoUrl ?? this.videoUrl,
      pollOptions: pollOptions ?? this.pollOptions,
      likedByIds: likedByIds ?? this.likedByIds,
      comments: comments ?? this.comments,
    );
  }

  /// Serializes this post to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'creatorId': creatorId,
        'creatorName': creatorName,
        'creatorAvatar': creatorAvatar,
        'creatorRole': creatorRole.name,
        'creatorCommittee': creatorCommittee,
        'publishTime': publishTime.toIso8601String(),
        'type': type.name,
        'content': content,
        'mediaPath': mediaPath,
        'isVideo': isVideo,
        'videoUrl': videoUrl,
        'pollOptions': pollOptions.map((e) => e.toJson()).toList(),
        'likedByIds': likedByIds,
        'comments': comments.map((e) => e.toJson()).toList(),
      };

  /// Deserializes a [PostModel] from a JSON map.
  factory PostModel.fromJson(Map<String, dynamic> json) => PostModel(
        id: json['id'] as String? ?? '',
        creatorId: json['creatorId'] as String? ?? '',
        creatorName: json['creatorName'] as String? ?? '',
        creatorAvatar:
            json['creatorAvatar'] as String? ?? AppAssets.accountIcon,
        creatorRole:
            UserRole.fromString(json['creatorRole'] as String? ?? 'member'),
        creatorCommittee:
            json['creatorCommittee'] as String? ?? 'Artistic Committee',
        publishTime: DateTime.tryParse(json['publishTime'] as String? ?? '') ??
            DateTime.now(),
        type: PostCategoryType.fromString(json['type'] as String? ?? 'simple'),
        content: json['content'] as String? ?? '',
        mediaPath: json['mediaPath'] as String?,
        isVideo: json['isVideo'] as bool? ?? false,
        videoUrl: json['videoUrl'] as String?,
        pollOptions: (json['pollOptions'] as List<dynamic>?)
                ?.map(
                    (e) => PollOptionModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        likedByIds: (json['likedByIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        comments: (json['comments'] as List<dynamic>?)
                ?.map((e) =>
                    PostCommentModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  @override
  List<Object?> get props => [
        id,
        creatorId,
        creatorName,
        publishTime,
        type,
        content,
        mediaPath,
        isVideo,
        videoUrl,
        pollOptions,
        likedByIds,
        comments,
      ];
}
