import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/lmt_models.dart';
import '../utils/app_assets.dart';
import '../utils/app_preferences.dart';
import 'lmt_repository.dart';

/// Temporary Cloud Firestore implementation of [LmtRepository] backed by an
/// offline-first local cache ([LmtLocalRepositoryImpl]) with real-time
/// multi-collection `.snapshots()` auto-sync across all connected devices.
class LmtFirestoreRepositoryImpl implements LmtRepository {
  /// Underlying local cache repository for instant offline-first startup and
  /// disconnected fallback.
  final LmtRepository localCache;

  LmtFirestoreRepositoryImpl({
    this.localCache = const LmtLocalRepositoryImpl(),
  });

  static const String _membersCol = 'members';
  static const String _memberAuthCol = 'member_auth';
  static const String _chatGroupsCol = 'chat_groups';
  static const String _chatMessagesCol = 'chat_messages';
  static const String _postsCol = 'posts';
  static const String _sharedFilesCol = 'shared_files';
  static const String _calendarEventsCol = 'calendar_events';
  static const String _notificationsCol = 'notifications';
  static const String _khelwaDaysCol = 'khelwa_days';
  static const String _chatTypingCol = 'chat_typing';
  static const String _teamConfigCol = 'team_config';
  static const String _brandingDocId = 'branding';

  static const Duration _remoteTimeout = Duration(seconds: 8);
  static const int _maxBatchOps = 400;

  /// Tracks serialized canonical JSON payloads (excluding `updatedByUid`) last
  /// seen or written per collection & doc ID.
  final Map<String, Map<String, String>> _lastSyncedDocs = {};

  /// Tracks document IDs actually delivered to or authored by the UI layer so
  /// concurrent remote additions are never deleted before reaching state.
  final Map<String, Set<String>> _deliveredDocIds = {};

  /// Live decoded doc maps per collection used by [watchLiveSnapshots].
  final Map<String, Map<String, Map<String, dynamic>>> _liveDocs = {};
  Map<String, dynamic>? _liveBrandingDoc;
  List<MemberModel> _localMemberFallback = const [];

  bool _persistInFlight = false;
  ({Map<String, dynamic> stateJson, String currentUserId})? _queuedPersist;
  Completer<void>? _persistIdleCompleter;
  Timer? _liveSyncDebounce;

  FirebaseFirestore? get _db =>
      Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null;

  Future<bool> _ensureAuthenticated() async {
    if (Firebase.apps.isEmpty) return false;
    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser != null) return true;
      await auth.signInAnonymously().timeout(_remoteTimeout);
      return auth.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  /// Ensures bounded string fields comply with `firestore.rules` (especially
  /// preventing legacy >500 char data URIs from aborting a batch).
  String _clampBoundedPath(dynamic raw, int maxLen, String fallback) {
    if (raw is! String || raw.trim().isEmpty) return fallback;
    final trimmed = raw.trim();
    return trimmed.length <= maxLen ? trimmed : fallback;
  }

  String _clampRequiredText(dynamic raw, int maxLen, String fallback) {
    if (raw is! String) return fallback;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return fallback;
    return trimmed.length <= maxLen ? trimmed : trimmed.substring(0, maxLen);
  }

  String? _clampNullableText(
    dynamic raw,
    int minLen,
    int maxLen, {
    bool allowEmpty = false,
  }) {
    if (raw == null) return null;
    if (raw is! String) return null;
    final trimmed = raw.trim();
    if (!allowEmpty && trimmed.length < minLen) return null;
    return trimmed.length <= maxLen ? trimmed : trimmed.substring(0, maxLen);
  }

  /// Strips volatile audit metadata (`updatedByUid`) so diffing compares actual
  /// domain payloads across users without rewriting untouched collections.
  String _canonicalDocJson(Map<String, dynamic> doc) {
    final copy = Map<String, dynamic>.from(doc)..remove('updatedByUid');
    return jsonEncode(copy);
  }

  /// Strips sensitive credentials before storing member directory records in
  /// Firestore and attaches the current anonymous auth UID for auditability.
  Map<String, dynamic> _prepareDocForCloud(
    Map<String, dynamic> raw,
    String uid, {
    bool isMemberCollection = false,
  }) {
    final copy = Map<String, dynamic>.from(raw);
    if (isMemberCollection) {
      copy.remove('password');
      copy.remove('passwordHash');
      copy.remove('passwordSalt');
      copy['avatarPath'] =
          _clampBoundedPath(copy['avatarPath'], 500, AppAssets.accountIcon);
    } else {
      if (copy.containsKey('senderAvatar')) {
        copy['senderAvatar'] = _clampBoundedPath(
          copy['senderAvatar'],
          500,
          AppAssets.accountIcon,
        );
      }
      if (copy.containsKey('senderName')) {
        copy['senderName'] =
            _clampRequiredText(copy['senderName'], 120, 'L.M.T Member');
      }
      if (copy.containsKey('creatorAvatar')) {
        copy['creatorAvatar'] = _clampBoundedPath(
          copy['creatorAvatar'],
          500,
          AppAssets.accountIcon,
        );
      }
      if (copy.containsKey('creatorName')) {
        copy['creatorName'] =
            _clampRequiredText(copy['creatorName'], 120, 'L.M.T Member');
      }
      if (copy.containsKey('imagePath')) {
        copy['imagePath'] = _clampBoundedPath(
          copy['imagePath'],
          500,
          AppAssets.appLogo,
        );
      }
      if (copy['attachmentPath'] is String &&
          (copy['attachmentPath'] as String).length > 1000) {
        copy['attachmentPath'] = AppAssets.postIcon;
      }
      if (copy['mediaPath'] is String &&
          (copy['mediaPath'] as String).length > 1000) {
        copy['mediaPath'] = null;
      }
      if (copy['localFilePath'] is String &&
          (copy['localFilePath'] as String).length > 1000) {
        copy['localFilePath'] = null;
      }
      if (copy.containsKey('replyToPreview')) {
        copy['replyToPreview'] = _clampNullableText(
          copy['replyToPreview'],
          0,
          1000,
          allowEmpty: true,
        );
      }
      if (copy.containsKey('replyToSenderName')) {
        copy['replyToSenderName'] =
            _clampNullableText(copy['replyToSenderName'], 1, 120);
      }
      if (copy.containsKey('forwardedFromGroup')) {
        copy['forwardedFromGroup'] =
            _clampNullableText(copy['forwardedFromGroup'], 1, 150);
      }
      if (copy.containsKey('fileSize')) {
        copy['fileSize'] = _clampNullableText(copy['fileSize'], 1, 50);
      }
      if (copy['content'] is String) {
        final contentStr = copy['content'] as String;
        final isChatMessage = copy.containsKey('groupId') && copy.containsKey('type');
        final typeStr = copy['type'] as String? ?? 'text';
        if (isChatMessage && typeStr == 'text' && contentStr.trim().isEmpty) {
          copy['content'] = ' ';
        } else if (contentStr.length > 5000) {
          copy['content'] = contentStr.substring(0, 5000);
        }
      }
      if (copy['seenBy'] is List) {
        final msgSenderId = (copy['senderId'] as String? ?? '').trim();
        final cleanedSeen = <Map<String, dynamic>>[];
        final seenMemberIds = <String>{};
        for (final entry in (copy['seenBy'] as List).whereType<Map>()) {
          final seen = Map<String, dynamic>.from(entry);
          final mid = _clampNullableText(seen['memberId'], 1, 64);
          if (mid == null || mid == msgSenderId || !seenMemberIds.add(mid)) {
            continue;
          }
          seen['memberId'] = mid;
          seen['memberName'] =
              _clampRequiredText(seen['memberName'], 120, 'L.M.T Member');
          seen['avatarPath'] = _clampBoundedPath(
            seen['avatarPath'],
            500,
            AppAssets.accountIcon,
          );
          if (seen['timestamp'] is! String ||
              (seen['timestamp'] as String).length < 19) {
            seen['timestamp'] = DateTime.now().toIso8601String();
          }
          seen['hasListened'] = seen['hasListened'] == true;
          cleanedSeen.add(seen);
          if (cleanedSeen.length >= 500) break;
        }
        copy['seenBy'] = cleanedSeen;
      }
      if (copy['reactions'] is Map) {
        final cleanedReactions = <String, List<String>>{};
        (copy['reactions'] as Map).forEach((k, v) {
          final key = k.toString().trim();
          if (key.isEmpty || key.length > 16 || cleanedReactions.length >= 50) {
            return;
          }
          if (v is List) {
            final names = v
                .map((e) => e.toString().trim())
                .where((s) => s.isNotEmpty)
                .map((s) => s.length <= 120 ? s : s.substring(0, 120))
                .take(200)
                .toList();
            if (names.isNotEmpty) {
              cleanedReactions[key] = names;
            }
          }
        });
        copy['reactions'] = cleanedReactions;
      }
      if (copy['comments'] is List) {
        final cleanedComments = <Map<String, dynamic>>[];
        for (final entry in (copy['comments'] as List).whereType<Map>()) {
          final c = Map<String, dynamic>.from(entry);
          c['id'] = _clampRequiredText(c['id'], 64, 'cmt_${cleanedComments.length}');
          c['authorId'] = _clampRequiredText(c['authorId'], 64, 'LMT-2026-001');
          c['authorName'] = _clampRequiredText(c['authorName'], 120, 'L.M.T Member');
          c['authorAvatar'] = _clampBoundedPath(
            c['authorAvatar'],
            500,
            AppAssets.accountIcon,
          );
          c['content'] = _clampRequiredText(c['content'], 2000, '💬');
          cleanedComments.add(c);
          if (cleanedComments.length >= 500) break;
        }
        copy['comments'] = cleanedComments;
      }
    }
    copy['updatedByUid'] = uid;
    return copy;
  }

  /// Prepares credential records for the separate `member_auth` collection so
  /// account passwords stay synced across devices and readable in Firestore.
  List<Map<String, dynamic>> _prepareMemberAuthDocs(
    List<dynamic>? items,
    String uid,
  ) {
    if (items == null) return const [];
    final previousAuth = _lastSyncedDocs[_memberAuthCol] ?? const {};
    final result = <Map<String, dynamic>>[];

    for (final raw in items.whereType<Map>()) {
      final map = raw.cast<String, dynamic>();
      final id = (map['id'] as String? ?? '').trim();
      if (id.isEmpty) continue;
      final username =
          (map['username'] as String? ?? '').trim().toLowerCase();
      var password = map['password'] as String? ?? '';

      if (password.isEmpty) {
        final prevJson = previousAuth[id];
        if (prevJson != null) {
          try {
            final prev = jsonDecode(prevJson) as Map<String, dynamic>;
            password = prev['password'] as String? ?? '';
          } catch (_) {}
        }
      }

      if (password.isEmpty) continue;
      result.add({
        'id': id,
        'memberId': id,
        'username': username,
        'password': password,
        'updatedByUid': uid,
      });
    }
    return result;
  }

  List<Map<String, dynamic>> _prepareCollectionDocs(
    List<dynamic>? items,
    String uid, {
    bool isMemberCollection = false,
  }) {
    if (items == null) return const [];
    return items.whereType<Map>().map((raw) {
      return _prepareDocForCloud(
        raw.cast<String, dynamic>(),
        uid,
        isMemberCollection: isMemberCollection,
      );
    }).toList();
  }

  void _recordSnapshotPayloads(
    String collectionName,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final encodedMap = <String, String>{};
    final rawMap = <String, Map<String, dynamic>>{};
    for (final doc in docs) {
      final data = {...doc.data(), 'id': doc.id};
      encodedMap[doc.id] = _canonicalDocJson(data);
      rawMap[doc.id] = data;
    }
    _lastSyncedDocs[collectionName] = encodedMap;
    _liveDocs[collectionName] = rawMap;
  }

  /// Unions incoming `seenBy` receipts from remote live docs into a local
  /// chat message document so concurrent Seen writes across devices never wipe
  /// another member's receipt.
  Map<String, dynamic> _mergeRemoteSeenReceiptsIntoMessage(
    String msgId,
    Map<String, dynamic> localDoc,
  ) {
    final remoteDoc = _liveDocs[_chatMessagesCol]?[msgId];
    if (remoteDoc == null) return localDoc;
    final remoteSeen = remoteDoc['seenBy'];
    if (remoteSeen is! List || remoteSeen.isEmpty) return localDoc;

    final senderId = (localDoc['senderId'] as String? ?? '').trim();
    final mergedById = <String, Map<String, dynamic>>{};

    void ingest(dynamic rawList) {
      if (rawList is! List) return;
      for (final item in rawList.whereType<Map>()) {
        final map = Map<String, dynamic>.from(item);
        final memberId = (map['memberId'] as String? ?? '').trim();
        if (memberId.isEmpty || memberId == senderId) continue;
        final prev = mergedById[memberId];
        if (prev == null) {
          mergedById[memberId] = map;
        } else {
          final listened =
              (prev['hasListened'] == true) || (map['hasListened'] == true);
          mergedById[memberId] = {...prev, ...map, 'hasListened': listened};
        }
      }
    }

    ingest(remoteSeen);
    ingest(localDoc['seenBy']);
    final updated = Map<String, dynamic>.from(localDoc);
    updated['seenBy'] = mergedById.values.take(500).toList();
    return updated;
  }

  Future<void> _commitCollectionSafely({
    required FirebaseFirestore db,
    required String collectionName,
    required List<Map<String, dynamic>> docs,
  }) async {
    try {
      await _commitCollectionDiff(
        db: db,
        collectionName: collectionName,
        docs: docs,
      );
    } catch (e) {
      debugPrint('Firestore sync error [$collectionName]: $e');
    }
  }

  Future<void> _commitCollectionDiff({
    required FirebaseFirestore db,
    required String collectionName,
    required List<Map<String, dynamic>> docs,
  }) async {
    final colRef = db.collection(collectionName);
    final previousMap = _lastSyncedDocs[collectionName] ?? const {};
    final deliveredIds = _deliveredDocIds[collectionName] ?? const <String>{};
    final previousRawMap = _liveDocs[collectionName] ?? const {};
    final nextMap = <String, String>{};
    final nextRawMap = <String, Map<String, dynamic>>{};
    final ops = <({String id, bool isDelete, Map<String, dynamic>? data})>[];

    for (final raw in docs) {
      final id = raw['id'] as String?;
      if (id == null || id.trim().isEmpty) continue;
      final data = collectionName == _chatMessagesCol
          ? _mergeRemoteSeenReceiptsIntoMessage(id, raw)
          : raw;
      final canonical = _canonicalDocJson(data);
      nextMap[id] = canonical;
      nextRawMap[id] = data;
      if (previousMap[id] != canonical) {
        ops.add((id: id, isDelete: false, data: data));
      }
    }

    // Only delete documents that were actually delivered into the client UI
    // state and intentionally removed locally — NEVER delete remote docs that
    // arrived asynchronously before LmtCubit consumed the live snapshot.
    for (final entry in previousMap.entries) {
      final staleId = entry.key;
      if (!nextMap.containsKey(staleId)) {
        if (deliveredIds.contains(staleId)) {
          ops.add((id: staleId, isDelete: true, data: null));
        } else {
          nextMap[staleId] = entry.value;
          final raw = previousRawMap[staleId];
          if (raw != null) {
            nextRawMap[staleId] = raw;
          }
        }
      }
    }

    final succeededIds = <String>{};
    final failedIds = <String>{};

    for (var i = 0; i < ops.length; i += _maxBatchOps) {
      final slice = ops.sublist(i, (i + _maxBatchOps).clamp(0, ops.length));
      try {
        final batch = db.batch();
        for (final op in slice) {
          if (op.isDelete) {
            batch.delete(colRef.doc(op.id));
          } else {
            batch.set(colRef.doc(op.id), op.data!);
          }
        }
        await batch.commit().timeout(_remoteTimeout);
        for (final op in slice) {
          succeededIds.add(op.id);
        }
      } catch (batchErr) {
        debugPrint(
          'Firestore batch fallback [$collectionName] (${slice.length} ops): $batchErr',
        );
        for (final op in slice) {
          try {
            if (op.isDelete) {
              await colRef.doc(op.id).delete().timeout(_remoteTimeout);
            } else {
              await colRef.doc(op.id).set(op.data!).timeout(_remoteTimeout);
            }
            succeededIds.add(op.id);
          } catch (singleErr) {
            failedIds.add(op.id);
            debugPrint(
              'Firestore single-doc error [$collectionName/${op.id}]: $singleErr',
            );
          }
        }
      }
    }

    for (final fid in failedIds) {
      if (previousMap.containsKey(fid)) {
        nextMap[fid] = previousMap[fid]!;
        final prevRaw = previousRawMap[fid];
        if (prevRaw != null) {
          nextRawMap[fid] = prevRaw;
        }
      } else {
        nextMap.remove(fid);
        nextRawMap.remove(fid);
      }
    }

    // Re-absorb any remote docs pushed by watchCollection while batch.commit
    // was awaiting network, provided this commit did not intentionally delete them.
    final latestLive = _liveDocs[collectionName] ?? const {};
    final latestSynced = _lastSyncedDocs[collectionName] ?? const {};
    for (final entry in latestLive.entries) {
      final id = entry.key;
      if (!nextRawMap.containsKey(id) && !succeededIds.contains(id)) {
        nextRawMap[id] = entry.value;
        final synced = latestSynced[id];
        if (synced != null) {
          nextMap[id] = synced;
        }
      }
    }

    _lastSyncedDocs[collectionName] = nextMap;
    _liveDocs[collectionName] = nextRawMap;
    _deliveredDocIds[collectionName] = nextRawMap.keys.toSet();
  }

  Future<void> _syncBrandingDoc(
    FirebaseFirestore db, {
    required String sloganOfYear,
    required String verseOfYear,
    required String uid,
  }) async {
    try {
      final payload = <String, dynamic>{
        'sloganOfYear': sloganOfYear,
        'verseOfYear': verseOfYear,
        'updatedByUid': uid,
      };
      final encoded = jsonEncode(payload);
      final previous = _lastSyncedDocs[_teamConfigCol]?[_brandingDocId];
      if (previous == encoded) return;

      await db
          .collection(_teamConfigCol)
          .doc(_brandingDocId)
          .set(payload)
          .timeout(_remoteTimeout);
      _lastSyncedDocs[_teamConfigCol] = {_brandingDocId: encoded};
      _liveBrandingDoc = payload;
    } catch (e) {
      debugPrint('Firestore branding sync error: $e');
    }
  }

  Future<LmtRepositorySnapshot> _assembleSnapshot({
    required LmtRepositorySnapshot fallback,
  }) async {
    final membersMap = _liveDocs[_membersCol] ?? const {};
    final authMap = _liveDocs[_memberAuthCol] ?? const {};
    final groupsMap = _liveDocs[_chatGroupsCol] ?? const {};
    final messagesMap = _liveDocs[_chatMessagesCol] ?? const {};
    final postsMap = _liveDocs[_postsCol] ?? const {};
    final filesMap = _liveDocs[_sharedFilesCol] ?? const {};
    final eventsMap = _liveDocs[_calendarEventsCol] ?? const {};
    final notifsMap = _liveDocs[_notificationsCol] ?? const {};
    final khelwaDaysMap = _liveDocs[_khelwaDaysCol] ?? const {};

    final localMemberMap = <String, MemberModel>{
      for (final m in _localMemberFallback) m.id: m,
      for (final m in fallback.members) m.id: m,
    };

    final members = membersMap.entries.map((entry) {
      final data = Map<String, dynamic>.from(entry.value);
      data['id'] ??= entry.key;
      final auth = authMap[entry.key];
      final localMember = localMemberMap[entry.key];
      final authPassword = auth?['password'] as String? ?? '';
      if (authPassword.isNotEmpty) {
        data['password'] = authPassword;
      } else {
        final localPassword = localMember?.password ?? '';
        if (localPassword.isNotEmpty) {
          data['password'] = localPassword;
        } else if (entry.key == 'LMT-2026-001') {
          data['password'] = 'password123';
        } else {
          data['password'] = '';
        }
      }
      data.remove('passwordHash');
      data.remove('passwordSalt');
      return MemberModel.fromJson(data);
    }).toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    final chatGroups = groupsMap.values
        .map(ChatGroupModel.fromJson)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final chatMessages = messagesMap.values
        .map(ChatMessageModel.fromJson)
        .toList()
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));

    final posts = postsMap.values.map(PostModel.fromJson).toList()
      ..sort((a, b) => b.publishTime.compareTo(a.publishTime));

    final sharedFiles = filesMap.values
        .map(SharedFileModel.fromJson)
        .toList()
      ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

    final calendarEvents = eventsMap.values
        .map(CalendarEventModel.fromJson)
        .toList()
      ..sort((a, b) => a.eventDateTime.compareTo(b.eventDateTime));

    final notifications = notifsMap.values
        .map(AppNotificationModel.fromJson)
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    final khelwaDays = khelwaDaysMap.values
        .map(KhelwaDayModel.fromJson)
        .toList()
      ..sort((a, b) => b.dateKey.compareTo(a.dateKey));

    final brandingData = _liveBrandingDoc;
    final sloganOfYear =
        (brandingData?['sloganOfYear'] as String?) ?? fallback.sloganOfYear;
    final verseOfYear =
        (brandingData?['verseOfYear'] as String?) ?? fallback.verseOfYear;

    if (brandingData != null) {
      await AppPreferences.setSloganOfYear(sloganOfYear);
      await AppPreferences.setVerseOfYear(verseOfYear);
    }

    final savedUserId = await AppPreferences.getCurrentUserId();
    final isLoggedIn = await AppPreferences.isLoggedIn();
    final matchedSaved = (savedUserId != null && savedUserId.isNotEmpty)
        ? members.where((m) => m.id == savedUserId).firstOrNull
        : null;
    if (isLoggedIn &&
        savedUserId != null &&
        savedUserId.isNotEmpty &&
        members.isNotEmpty &&
        matchedSaved == null) {
      await AppPreferences.clearLogin();
    }

    final currentUser = matchedSaved ??
        members.where((m) => m.id == fallback.currentUser.id).firstOrNull ??
        (members.isNotEmpty ? members.first : fallback.currentUser);

    await localCache.persistSnapshot(
      stateJson: {
        'sloganOfYear': sloganOfYear,
        'verseOfYear': verseOfYear,
        'currentUser': currentUser.toJson(),
        'members': members.map((e) => e.toJson()).toList(),
        'chatGroups': chatGroups.map((e) => e.toJson()).toList(),
        'chatMessages': chatMessages.map((e) => e.toJson()).toList(),
        'posts': posts.map((e) => e.toJson()).toList(),
        'sharedFiles': sharedFiles.map((e) => e.toJson()).toList(),
        'calendarEvents': calendarEvents.map((e) => e.toJson()).toList(),
        'notifications': notifications.map((e) => e.toJson()).toList(),
        'khelwaDays': khelwaDays.map((e) => e.toJson()).toList(),
      },
      currentUserId: matchedSaved?.id ?? '',
    );

    _deliveredDocIds[_membersCol] = membersMap.keys.toSet();
    _deliveredDocIds[_memberAuthCol] = authMap.keys.toSet();
    _deliveredDocIds[_chatGroupsCol] = groupsMap.keys.toSet();
    _deliveredDocIds[_chatMessagesCol] = messagesMap.keys.toSet();
    _deliveredDocIds[_postsCol] = postsMap.keys.toSet();
    _deliveredDocIds[_sharedFilesCol] = filesMap.keys.toSet();
    _deliveredDocIds[_calendarEventsCol] = eventsMap.keys.toSet();
    _deliveredDocIds[_notificationsCol] = notifsMap.keys.toSet();
    _deliveredDocIds[_khelwaDaysCol] = khelwaDaysMap.keys.toSet();

    return LmtRepositorySnapshot(
      biometricEnabled: fallback.biometricEnabled,
      sloganOfYear: sloganOfYear,
      verseOfYear: verseOfYear,
      currentUser: currentUser,
      members: members.isEmpty ? fallback.members : members,
      chatGroups: chatGroups.isEmpty ? fallback.chatGroups : chatGroups,
      chatMessages: chatMessages,
      posts: posts,
      sharedFiles: sharedFiles,
      calendarEvents: calendarEvents,
      notifications: notifications,
      khelwaDays: khelwaDays,
    );
  }

  Future<List<MemberModel>> _seedInitialCollectionsIfEmpty(
    FirebaseFirestore db,
    LmtRepositorySnapshot seedSource,
    String uid,
  ) async {
    final seedMembers = seedSource.members;
    final serializedMembers = seedMembers.map((e) => e.toJson()).toList();

    await _commitCollectionSafely(
      db: db,
      collectionName: _membersCol,
      docs: _prepareCollectionDocs(
        serializedMembers,
        uid,
        isMemberCollection: true,
      ),
    );
    await _commitCollectionSafely(
      db: db,
      collectionName: _memberAuthCol,
      docs: _prepareMemberAuthDocs(serializedMembers, uid),
    );
    await _commitCollectionSafely(
      db: db,
      collectionName: _chatGroupsCol,
      docs: _prepareCollectionDocs(
        seedSource.chatGroups.map((e) => e.toJson()).toList(),
        uid,
      ),
    );
    await _commitCollectionSafely(
      db: db,
      collectionName: _chatMessagesCol,
      docs: _prepareCollectionDocs(
        seedSource.chatMessages.map((e) => e.toJson()).toList(),
        uid,
      ),
    );
    await _commitCollectionSafely(
      db: db,
      collectionName: _postsCol,
      docs: _prepareCollectionDocs(
        seedSource.posts.map((e) => e.toJson()).toList(),
        uid,
      ),
    );
    await _commitCollectionSafely(
      db: db,
      collectionName: _sharedFilesCol,
      docs: _prepareCollectionDocs(
        seedSource.sharedFiles.map((e) => e.toJson()).toList(),
        uid,
      ),
    );
    await _commitCollectionSafely(
      db: db,
      collectionName: _calendarEventsCol,
      docs: _prepareCollectionDocs(
        seedSource.calendarEvents.map((e) => e.toJson()).toList(),
        uid,
      ),
    );
    await _commitCollectionSafely(
      db: db,
      collectionName: _notificationsCol,
      docs: _prepareCollectionDocs(
        seedSource.notifications.map((e) => e.toJson()).toList(),
        uid,
      ),
    );
    await _syncBrandingDoc(
      db,
      sloganOfYear: seedSource.sloganOfYear,
      verseOfYear: seedSource.verseOfYear,
      uid: uid,
    );
    return seedMembers;
  }

  @override
  Future<LmtRepositorySnapshot> loadSnapshot() async {
    final local = await localCache.loadSnapshot();
    _localMemberFallback = local.members;
    final db = _db;
    if (db == null) return local;

    final authed = await _ensureAuthenticated();
    if (!authed) return local;

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

      final membersSnap =
          await db.collection(_membersCol).get().timeout(_remoteTimeout);

      // First run against an empty Firestore database: seed initial collections.
      if (membersSnap.docs.isEmpty) {
        final seededMembers =
            await _seedInitialCollectionsIfEmpty(db, local, uid);
        final savedUserId = await AppPreferences.getCurrentUserId();
        final isLoggedIn = await AppPreferences.isLoggedIn();
        final matchedSaved = (savedUserId != null && savedUserId.isNotEmpty)
            ? seededMembers.where((m) => m.id == savedUserId).firstOrNull
            : null;
        if (isLoggedIn &&
            savedUserId != null &&
            savedUserId.isNotEmpty &&
            matchedSaved == null) {
          await AppPreferences.clearLogin();
        }
        final updatedCurrent = matchedSaved ??
            seededMembers
                .where((m) => m.id == local.currentUser.id)
                .firstOrNull ??
            (seededMembers.isNotEmpty
                ? seededMembers.first
                : local.currentUser);
        await localCache.persistSnapshot(
          stateJson: {
            'sloganOfYear': local.sloganOfYear,
            'verseOfYear': local.verseOfYear,
            'currentUser': updatedCurrent.toJson(),
            'members': seededMembers.map((e) => e.toJson()).toList(),
            'chatGroups': local.chatGroups.map((e) => e.toJson()).toList(),
            'chatMessages': local.chatMessages.map((e) => e.toJson()).toList(),
            'posts': local.posts.map((e) => e.toJson()).toList(),
            'sharedFiles': local.sharedFiles.map((e) => e.toJson()).toList(),
            'calendarEvents':
                local.calendarEvents.map((e) => e.toJson()).toList(),
            'notifications':
                local.notifications.map((e) => e.toJson()).toList(),
          },
          currentUserId: matchedSaved?.id ?? '',
        );
        return LmtRepositorySnapshot(
          biometricEnabled: local.biometricEnabled,
          sloganOfYear: local.sloganOfYear,
          verseOfYear: local.verseOfYear,
          currentUser: updatedCurrent,
          members: seededMembers,
          chatGroups: local.chatGroups,
          chatMessages: local.chatMessages,
          posts: local.posts,
          sharedFiles: local.sharedFiles,
          calendarEvents: local.calendarEvents,
          notifications: local.notifications,
        );
      }

      final snaps = await Future.wait([
        db.collection(_memberAuthCol).get().timeout(_remoteTimeout),
        db.collection(_chatGroupsCol).get().timeout(_remoteTimeout),
        db.collection(_chatMessagesCol).get().timeout(_remoteTimeout),
        db.collection(_postsCol).get().timeout(_remoteTimeout),
        db.collection(_sharedFilesCol).get().timeout(_remoteTimeout),
        db.collection(_calendarEventsCol).get().timeout(_remoteTimeout),
        db.collection(_notificationsCol).get().timeout(_remoteTimeout),
        db.collection(_khelwaDaysCol).get().timeout(_remoteTimeout),
      ]);

      final memberAuthSnap = snaps[0];
      final groupsSnap = snaps[1];
      final messagesSnap = snaps[2];
      final postsSnap = snaps[3];
      final filesSnap = snaps[4];
      final eventsSnap = snaps[5];
      final notifsSnap = snaps[6];
      final khelwaDaysSnap = snaps[7];

      final brandingSnap = await db
          .collection(_teamConfigCol)
          .doc(_brandingDocId)
          .get()
          .timeout(_remoteTimeout);

      if (!_persistInFlight) {
        _recordSnapshotPayloads(_membersCol, membersSnap.docs);
        _recordSnapshotPayloads(_memberAuthCol, memberAuthSnap.docs);
        _recordSnapshotPayloads(_chatGroupsCol, groupsSnap.docs);
        _recordSnapshotPayloads(_chatMessagesCol, messagesSnap.docs);
        _recordSnapshotPayloads(_postsCol, postsSnap.docs);
        _recordSnapshotPayloads(_sharedFilesCol, filesSnap.docs);
        _recordSnapshotPayloads(_calendarEventsCol, eventsSnap.docs);
        _recordSnapshotPayloads(_notificationsCol, notifsSnap.docs);
        _recordSnapshotPayloads(_khelwaDaysCol, khelwaDaysSnap.docs);

        final brandingData = brandingSnap.data();
        if (brandingData != null) {
          _lastSyncedDocs[_teamConfigCol] = {
            _brandingDocId: jsonEncode(brandingData),
          };
          _liveBrandingDoc = Map<String, dynamic>.from(brandingData);
        }
      }

      final assembled = await _assembleSnapshot(fallback: local);
      return await _recoverUnsyncedLocalSeenReceipts(assembled, local: local);
    } catch (_) {
      return local;
    }
  }

  Future<LmtRepositorySnapshot> _recoverUnsyncedLocalSeenReceipts(
    LmtRepositorySnapshot remote, {
    required LmtRepositorySnapshot local,
  }) async {
    final viewer = remote.currentUser;
    if (local.currentUser.id != viewer.id) return remote;
    final isLoggedIn = await AppPreferences.isLoggedIn();
    if (!isLoggedIn) return remote;

    final localByMsgId = <String, ChatMessageModel>{
      for (final m in local.chatMessages) m.id: m,
    };
    final toFlush = <ChatMessageModel>[];
    SeenStatusModel? flushReceipt;
    var changed = false;

    final mergedMessages = remote.chatMessages.map((remoteMsg) {
      if (remoteMsg.senderId == viewer.id) return remoteMsg;
      final localMsg = localByMsgId[remoteMsg.id];
      if (localMsg == null) return remoteMsg;
      if (remoteMsg.sentAt.difference(localMsg.sentAt).abs() >
          const Duration(seconds: 2)) {
        return remoteMsg;
      }
      final localReceipt =
          localMsg.seenBy.where((s) => s.memberId == viewer.id).firstOrNull;
      if (localReceipt == null) return remoteMsg;

      final remoteIdx =
          remoteMsg.seenBy.indexWhere((s) => s.memberId == viewer.id);
      if (remoteIdx == -1) {
        changed = true;
        final updated = remoteMsg.copyWith(
          seenBy: [...remoteMsg.seenBy, localReceipt],
        );
        toFlush.add(updated);
        flushReceipt ??= localReceipt;
        return updated;
      }
      if (localReceipt.hasListened && !remoteMsg.seenBy[remoteIdx].hasListened) {
        changed = true;
        final existing = remoteMsg.seenBy[remoteIdx];
        final nextSeen = List<SeenStatusModel>.from(remoteMsg.seenBy);
        nextSeen[remoteIdx] = SeenStatusModel(
          memberId: existing.memberId,
          memberName: existing.memberName,
          avatarPath: existing.avatarPath,
          timestamp: existing.timestamp,
          hasListened: true,
        );
        return remoteMsg.copyWith(seenBy: nextSeen);
      }
      return remoteMsg;
    }).toList();

    if (toFlush.isNotEmpty && flushReceipt != null) {
      unawaited(
        markMessagesSeenInCloud(
          updatedMessages: toFlush,
          viewerReceipt: flushReceipt!,
        ),
      );
    }

    if (!changed) return remote;
    return LmtRepositorySnapshot(
      biometricEnabled: remote.biometricEnabled,
      sloganOfYear: remote.sloganOfYear,
      verseOfYear: remote.verseOfYear,
      currentUser: remote.currentUser,
      members: remote.members,
      chatGroups: remote.chatGroups,
      chatMessages: mergedMessages,
      posts: remote.posts,
      sharedFiles: remote.sharedFiles,
      calendarEvents: remote.calendarEvents,
      notifications: remote.notifications,
      khelwaDays: remote.khelwaDays,
    );
  }

  @override
  Future<void> persistSnapshot({
    required Map<String, dynamic> stateJson,
    required String currentUserId,
  }) async {
    final db = _db;
    if (db == null) {
      await localCache.persistSnapshot(
        stateJson: stateJson,
        currentUserId: currentUserId,
      );
      return;
    }

    if (_persistInFlight) {
      // Never drop concurrent writes: coalesce and flush right after the current
      // Firestore batch completes.
      _queuedPersist = (stateJson: stateJson, currentUserId: currentUserId);
      await localCache.persistSnapshot(
        stateJson: stateJson,
        currentUserId: currentUserId,
      );
      await _persistIdleCompleter?.future;
      return;
    }

    // Lock live remote echoes IMMEDIATELY before any async local write so
    // optimistic local additions (posts/polls, events, files) can never be
    // wiped by an in-flight stream tick during local caching.
    _persistInFlight = true;
    _liveSyncDebounce?.cancel();
    _persistIdleCompleter = Completer<void>();

    try {
      await localCache.persistSnapshot(
        stateJson: stateJson,
        currentUserId: currentUserId,
      );
      var nextWrite = (stateJson: stateJson, currentUserId: currentUserId);
      while (true) {
        await _flushSinglePersist(db, nextWrite.stateJson);
        final pending = _queuedPersist;
        _queuedPersist = null;
        if (pending == null) break;
        nextWrite = pending;
      }
    } finally {
      _persistInFlight = false;
      _persistIdleCompleter?.complete();
      _persistIdleCompleter = null;
    }
  }

  Future<void> _flushSinglePersist(
    FirebaseFirestore db,
    Map<String, dynamic> stateJson,
  ) async {
    try {
      final authed = await _ensureAuthenticated();
      if (!authed) return;
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

      await Future.wait([
        _commitCollectionSafely(
          db: db,
          collectionName: _membersCol,
          docs: _prepareCollectionDocs(
            stateJson['members'] as List<dynamic>?,
            uid,
            isMemberCollection: true,
          ),
        ),
        _commitCollectionSafely(
          db: db,
          collectionName: _memberAuthCol,
          docs: _prepareMemberAuthDocs(
            stateJson['members'] as List<dynamic>?,
            uid,
          ),
        ),
        _commitCollectionSafely(
          db: db,
          collectionName: _chatGroupsCol,
          docs: _prepareCollectionDocs(
            stateJson['chatGroups'] as List<dynamic>?,
            uid,
          ),
        ),
        _commitCollectionSafely(
          db: db,
          collectionName: _chatMessagesCol,
          docs: _prepareCollectionDocs(
            stateJson['chatMessages'] as List<dynamic>?,
            uid,
          ),
        ),
        _commitCollectionSafely(
          db: db,
          collectionName: _postsCol,
          docs: _prepareCollectionDocs(
            stateJson['posts'] as List<dynamic>?,
            uid,
          ),
        ),
        _commitCollectionSafely(
          db: db,
          collectionName: _sharedFilesCol,
          docs: _prepareCollectionDocs(
            stateJson['sharedFiles'] as List<dynamic>?,
            uid,
          ),
        ),
        _commitCollectionSafely(
          db: db,
          collectionName: _calendarEventsCol,
          docs: _prepareCollectionDocs(
            stateJson['calendarEvents'] as List<dynamic>?,
            uid,
          ),
        ),
        _commitCollectionSafely(
          db: db,
          collectionName: _notificationsCol,
          docs: _prepareCollectionDocs(
            stateJson['notifications'] as List<dynamic>?,
            uid,
          ),
        ),
      ]);

      final slogan = stateJson['sloganOfYear'] as String?;
      final verse = stateJson['verseOfYear'] as String?;
      if (slogan != null && verse != null) {
        await _syncBrandingDoc(
          db,
          sloganOfYear: slogan,
          verseOfYear: verse,
          uid: uid,
        );
      }
    } catch (e) {
      debugPrint('Firestore flushSinglePersist error: $e');
    }
  }

  @override
  Stream<LmtRepositorySnapshot> watchLiveSnapshots() {
    final db = _db;
    if (db == null) return const Stream.empty();

    late StreamController<LmtRepositorySnapshot> controller;
    final subs = <StreamSubscription<dynamic>>[];
    var emitting = false;
    var dirty = false;

    Future<void> emitCombined() async {
      if (controller.isClosed) return;
      if (_persistInFlight) {
        dirty = true;
        return;
      }
      if (emitting) {
        dirty = true;
        return;
      }
      emitting = true;
      try {
        do {
          dirty = false;
          if (_persistInFlight) break;
          final local = await localCache.loadSnapshot();
          if (_persistInFlight || controller.isClosed) break;
          final assembled = await _assembleSnapshot(fallback: local);
          if (!_persistInFlight && !controller.isClosed) {
            controller.add(assembled);
          }
        } while (dirty && !controller.isClosed);
      } catch (e) {
        debugPrint('Firestore watchLiveSnapshots assemble error: $e');
      } finally {
        emitting = false;
      }
    }

    void scheduleEmit() {
      _liveSyncDebounce?.cancel();
      _liveSyncDebounce = Timer(const Duration(milliseconds: 60), emitCombined);
    }

    void watchCollection(String collectionName) {
      final sub = db.collection(collectionName).snapshots().listen(
        (snap) {
          // Ignore local optimistic cache echo while this device is committing.
          if (snap.metadata.hasPendingWrites && _persistInFlight) return;
          _recordSnapshotPayloads(collectionName, snap.docs);
          scheduleEmit();
        },
        onError: (Object e) {
          debugPrint('Firestore watch [$collectionName] error: $e');
        },
      );
      subs.add(sub);
    }

    controller = StreamController<LmtRepositorySnapshot>.broadcast(
      onListen: () {
        _ensureAuthenticated().then((authed) {
          if (!authed || controller.isClosed) return;
          watchCollection(_membersCol);
          watchCollection(_memberAuthCol);
          watchCollection(_chatGroupsCol);
          watchCollection(_chatMessagesCol);
          watchCollection(_postsCol);
          watchCollection(_sharedFilesCol);
          watchCollection(_calendarEventsCol);
          watchCollection(_notificationsCol);
          watchCollection(_khelwaDaysCol);

          subs.add(
            db
                .collection(_teamConfigCol)
                .doc(_brandingDocId)
                .snapshots()
                .listen(
              (docSnap) {
                if (docSnap.metadata.hasPendingWrites && _persistInFlight) {
                  return;
                }
                final data = docSnap.data();
                if (data != null) {
                  _lastSyncedDocs[_teamConfigCol] = {
                    _brandingDocId: jsonEncode(data),
                  };
                  _liveBrandingDoc = Map<String, dynamic>.from(data);
                  scheduleEmit();
                }
              },
              onError: (Object e) {
                debugPrint('Firestore watch branding error: $e');
              },
            ),
          );
        });
      },
      onCancel: () {
        _liveSyncDebounce?.cancel();
        for (final sub in subs) {
          sub.cancel();
        }
        subs.clear();
      },
    );

    return controller.stream;
  }

  @override
  Future<void> recordKhelwaCheckIn({
    required String dateKey,
    required String memberId,
    required String memberName,
  }) async {
    final db = _db;
    if (db == null) return;
    try {
      final authed = await _ensureAuthenticated();
      if (!authed) return;
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final docRef = db.collection(_khelwaDaysCol).doc(dateKey);

      await db.runTransaction((tx) async {
        final snap = await tx.get(docRef);
        final existing = snap.data();
        final ids = existing == null
            ? <String>[]
            : List<String>.from(
                (existing['attendeeIds'] as List<dynamic>? ?? const [])
                    .map((e) => e.toString()),
              );
        final names = existing == null
            ? <String>[]
            : List<String>.from(
                (existing['attendeeNames'] as List<dynamic>? ?? const [])
                    .map((e) => e.toString()),
              );

        final idx = ids.indexOf(memberId);
        if (idx == -1) {
          ids.add(memberId);
          names.add(memberName);
        } else if (idx < names.length) {
          names[idx] = memberName;
        }

        final payload = <String, dynamic>{
          'id': dateKey,
          'dateKey': dateKey,
          'attendeeIds': ids,
          'attendeeNames': names,
          'updatedAt': DateTime.now().toIso8601String(),
          'updatedByUid': uid,
        };
        tx.set(docRef, payload);
        _lastSyncedDocs[_khelwaDaysCol] ??= {};
        _liveDocs[_khelwaDaysCol] ??= {};
        _lastSyncedDocs[_khelwaDaysCol]![dateKey] = jsonEncode(payload);
        _liveDocs[_khelwaDaysCol]![dateKey] = payload;
      }).timeout(_remoteTimeout);
    } catch (e) {
      debugPrint('Firestore recordKhelwaCheckIn error: $e');
    }
  }

  @override
  Future<void> resetKhelwaDay({required String dateKey}) async {
    final db = _db;
    if (db == null) return;
    try {
      final authed = await _ensureAuthenticated();
      if (!authed) return;
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final docRef = db.collection(_khelwaDaysCol).doc(dateKey);
      final payload = <String, dynamic>{
        'id': dateKey,
        'dateKey': dateKey,
        'attendeeIds': const <String>[],
        'attendeeNames': const <String>[],
        'updatedAt': DateTime.now().toIso8601String(),
        'updatedByUid': uid,
      };
      await docRef.set(payload).timeout(_remoteTimeout);
      _lastSyncedDocs[_khelwaDaysCol] ??= {};
      _liveDocs[_khelwaDaysCol] ??= {};
      _lastSyncedDocs[_khelwaDaysCol]![dateKey] = jsonEncode(payload);
      _liveDocs[_khelwaDaysCol]![dateKey] = payload;
    } catch (e) {
      debugPrint('Firestore resetKhelwaDay error: $e');
    }
  }

  @override
  Future<void> setGroupTypingStatus({
    required String groupId,
    required MemberModel member,
    required bool isTyping,
  }) async {
    final db = _db;
    if (db == null) return;
    try {
      final authed = await _ensureAuthenticated();
      if (!authed) return;
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final docId = '${groupId}_${member.id}';
      final docRef = db.collection(_chatTypingCol).doc(docId);
      if (isTyping) {
        await docRef.set({
          'id': docId,
          'groupId': groupId,
          'memberId': member.id,
          'memberName': member.name,
          'avatarPath': _clampBoundedPath(
            member.avatarPath,
            500,
            AppAssets.accountIcon,
          ),
          'updatedAt': DateTime.now().toIso8601String(),
          'updatedByUid': uid,
        }).timeout(_remoteTimeout);
      } else {
        await docRef.delete().timeout(_remoteTimeout);
      }
    } catch (_) {}
  }

  @override
  Stream<List<TypingMemberStatus>> watchGroupTyping(String groupId) {
    final db = _db;
    if (db == null) return const Stream.empty();
    return db
        .collection(_chatTypingCol)
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => TypingMemberStatus.fromJson(d.data()))
              .toList(),
        );
  }

  @override
  Stream<List<AppNotificationModel>> watchNotifications() {
    final db = _db;
    if (db == null) return const Stream.empty();
    return db.collection(_notificationsCol).snapshots().map((snap) {
      final list = snap.docs
          .map((d) => AppNotificationModel.fromJson({...d.data(), 'id': d.id}))
          .toList()
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
      return list;
    });
  }

  @override
  Future<void> sendChatMessageToCloud({
    required ChatMessageModel message,
    AppNotificationModel? notification,
  }) async {
    final db = _db;
    if (db == null) return;
    try {
      final authed = await _ensureAuthenticated();
      if (!authed) return;
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

      final msgPayload = _prepareDocForCloud(message.toJson(), uid);
      _liveDocs[_chatMessagesCol] ??= {};
      _deliveredDocIds[_chatMessagesCol] ??= {};
      _liveDocs[_chatMessagesCol]![message.id] = msgPayload;
      _deliveredDocIds[_chatMessagesCol]!.add(message.id);

      final writes = <Future<void>>[
        db
            .collection(_chatMessagesCol)
            .doc(message.id)
            .set(msgPayload)
            .timeout(_remoteTimeout)
            .then((_) {
          _lastSyncedDocs[_chatMessagesCol] ??= {};
          _lastSyncedDocs[_chatMessagesCol]![message.id] =
              _canonicalDocJson(msgPayload);
        }),
      ];

      if (notification != null) {
        final notifPayload = _prepareDocForCloud(notification.toJson(), uid);
        _liveDocs[_notificationsCol] ??= {};
        _deliveredDocIds[_notificationsCol] ??= {};
        _liveDocs[_notificationsCol]![notification.id] = notifPayload;
        _deliveredDocIds[_notificationsCol]!.add(notification.id);
        writes.add(
          db
              .collection(_notificationsCol)
              .doc(notification.id)
              .set(notifPayload)
              .timeout(_remoteTimeout)
              .then((_) {
            _lastSyncedDocs[_notificationsCol] ??= {};
            _lastSyncedDocs[_notificationsCol]![notification.id] =
                _canonicalDocJson(notifPayload);
          }),
        );
      }

      await Future.wait(writes);
    } catch (e) {
      debugPrint('Firestore sendChatMessageToCloud error: $e');
    }
  }

  @override
  Future<void> markMessagesSeenInCloud({
    required List<ChatMessageModel> updatedMessages,
    required SeenStatusModel viewerReceipt,
  }) async {
    final db = _db;
    if (db == null || updatedMessages.isEmpty) return;
    try {
      final authed = await _ensureAuthenticated();
      if (!authed) return;
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final safeReceipt = <String, dynamic>{
        'memberId': _clampRequiredText(viewerReceipt.memberId, 64, 'viewer'),
        'memberName':
            _clampRequiredText(viewerReceipt.memberName, 120, 'L.M.T Member'),
        'avatarPath': _clampBoundedPath(
          viewerReceipt.avatarPath,
          500,
          AppAssets.accountIcon,
        ),
        'timestamp': viewerReceipt.timestamp.toIso8601String(),
        'hasListened': viewerReceipt.hasListened,
      };

      final targets = updatedMessages
          .where((m) => m.senderId != viewerReceipt.memberId)
          .toList(growable: false);
      if (targets.isEmpty) return;

      const int chunkSize = 10;
      for (var i = 0; i < targets.length; i += chunkSize) {
        final chunk = targets.sublist(
          i,
          (i + chunkSize) > targets.length ? targets.length : (i + chunkSize),
        );
        await Future.wait(
          chunk.map((msg) async {
            final docRef = db.collection(_chatMessagesCol).doc(msg.id);
            Map<String, dynamic>? committedPayload;
            await db.runTransaction((tx) async {
              final snap = await tx.get(docRef);
              if (!snap.exists) {
                final fullPayload = _prepareDocForCloud(msg.toJson(), uid);
                tx.set(docRef, fullPayload);
                committedPayload = fullPayload;
                return;
              }

              final current = Map<String, dynamic>.from(snap.data() ?? const {});
              final merged = _mergeRemoteSeenReceiptsIntoMessage(msg.id, {
                ...current,
                'seenBy': [
                  ...(current['seenBy'] as List<dynamic>? ?? const []),
                  safeReceipt,
                ],
              });
              final sanitized = _prepareDocForCloud(
                {...current, 'seenBy': merged['seenBy']},
                uid,
              );
              tx.set(docRef, sanitized);
              committedPayload = sanitized;
            }).timeout(_remoteTimeout);

            final payload = committedPayload;
            if (payload != null) {
              _lastSyncedDocs[_chatMessagesCol] ??= {};
              _liveDocs[_chatMessagesCol] ??= {};
              _deliveredDocIds[_chatMessagesCol] ??= {};
              _lastSyncedDocs[_chatMessagesCol]![msg.id] =
                  _canonicalDocJson(payload);
              _liveDocs[_chatMessagesCol]![msg.id] = payload;
              _deliveredDocIds[_chatMessagesCol]!.add(msg.id);
            }
          }),
        );
      }
    } catch (e) {
      debugPrint('Firestore markMessagesSeenInCloud error: $e');
    }
  }

  @override
  Future<void> persistLocalSnapshot({
    required Map<String, dynamic> stateJson,
    required String currentUserId,
  }) async {
    await localCache.persistSnapshot(
      stateJson: stateJson,
      currentUserId: currentUserId,
    );
  }

  @override
  Future<void> clearCachedState() async {
    await localCache.clearCachedState();
  }
}
