import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/lmt_models.dart';
import '../utils/app_preferences.dart';
import 'lmt_repository.dart';

/// Temporary Cloud Firestore implementation of [LmtRepository] backed by an
/// offline-first local cache ([LmtLocalRepositoryImpl]).
///
/// Later, when migrating to the C# ASP.NET Core & SQL Server backend, swap the
/// registration in `lib/core/di/injection_container.dart` with an API-backed
/// [LmtRepository] without changing any Cubits or UI widgets.
class LmtFirestoreRepositoryImpl implements LmtRepository {
  /// Underlying local cache repository for instant offline-first startup and
  /// disconnected fallback.
  final LmtRepository localCache;

  LmtFirestoreRepositoryImpl({this.localCache = const LmtLocalRepositoryImpl()});

  static const String _membersCol = 'members';
  static const String _memberAuthCol = 'member_auth';
  static const String _chatGroupsCol = 'chat_groups';
  static const String _chatMessagesCol = 'chat_messages';
  static const String _postsCol = 'posts';
  static const String _sharedFilesCol = 'shared_files';
  static const String _calendarEventsCol = 'calendar_events';
  static const String _notificationsCol = 'notifications';
  static const String _chatTypingCol = 'chat_typing';
  static const String _teamConfigCol = 'team_config';
  static const String _brandingDocId = 'branding';

  static const Duration _remoteTimeout = Duration(seconds: 6);
  static const int _maxBatchOps = 400;

  /// Tracks the serialized payload last synced per collection and document ID so
  /// only modified/new/deleted documents are written to Firestore.
  final Map<String, Map<String, String>> _lastSyncedDocs = {};
  bool _isSyncing = false;

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
    final map = <String, String>{};
    for (final doc in docs) {
      map[doc.id] = jsonEncode(doc.data());
    }
    _lastSyncedDocs[collectionName] = map;
  }

  Future<void> _commitCollectionDiff({
    required FirebaseFirestore db,
    required String collectionName,
    required List<Map<String, dynamic>> docs,
  }) async {
    final colRef = db.collection(collectionName);
    final previousMap = _lastSyncedDocs[collectionName] ?? const {};
    final nextMap = <String, String>{};
    final operations = <void Function(WriteBatch)>[];

    for (final data in docs) {
      final id = data['id'] as String?;
      if (id == null || id.trim().isEmpty) continue;
      final encoded = jsonEncode(data);
      nextMap[id] = encoded;
      if (previousMap[id] != encoded) {
        operations.add((batch) => batch.set(colRef.doc(id), data));
      }
    }

    for (final staleId in previousMap.keys) {
      if (!nextMap.containsKey(staleId)) {
        operations.add((batch) => batch.delete(colRef.doc(staleId)));
      }
    }

    for (var i = 0; i < operations.length; i += _maxBatchOps) {
      final batch = db.batch();
      final end = (i + _maxBatchOps).clamp(0, operations.length);
      for (var j = i; j < end; j++) {
        operations[j](batch);
      }
      await batch.commit().timeout(_remoteTimeout);
    }

    _lastSyncedDocs[collectionName] = nextMap;
  }

  Future<void> _syncBrandingDoc(
    FirebaseFirestore db, {
    required String sloganOfYear,
    required String verseOfYear,
    required String uid,
  }) async {
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
  }

  Future<List<MemberModel>> _seedInitialCollectionsIfEmpty(
    FirebaseFirestore db,
    LmtRepositorySnapshot seedSource,
    String uid,
  ) async {
    final seedMembers = seedSource.members;
    final serializedMembers = seedMembers.map((e) => e.toJson()).toList();

    await _commitCollectionDiff(
      db: db,
      collectionName: _membersCol,
      docs: _prepareCollectionDocs(
        serializedMembers,
        uid,
        isMemberCollection: true,
      ),
    );
    await _commitCollectionDiff(
      db: db,
      collectionName: _memberAuthCol,
      docs: _prepareMemberAuthDocs(serializedMembers, uid),
    );
    await _commitCollectionDiff(
      db: db,
      collectionName: _chatGroupsCol,
      docs: _prepareCollectionDocs(
        seedSource.chatGroups.map((e) => e.toJson()).toList(),
        uid,
      ),
    );
    await _commitCollectionDiff(
      db: db,
      collectionName: _chatMessagesCol,
      docs: _prepareCollectionDocs(
        seedSource.chatMessages.map((e) => e.toJson()).toList(),
        uid,
      ),
    );
    await _commitCollectionDiff(
      db: db,
      collectionName: _postsCol,
      docs: _prepareCollectionDocs(
        seedSource.posts.map((e) => e.toJson()).toList(),
        uid,
      ),
    );
    await _commitCollectionDiff(
      db: db,
      collectionName: _sharedFilesCol,
      docs: _prepareCollectionDocs(
        seedSource.sharedFiles.map((e) => e.toJson()).toList(),
        uid,
      ),
    );
    await _commitCollectionDiff(
      db: db,
      collectionName: _calendarEventsCol,
      docs: _prepareCollectionDocs(
        seedSource.calendarEvents.map((e) => e.toJson()).toList(),
        uid,
      ),
    );
    await _commitCollectionDiff(
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

      final memberAuthSnap =
          await db.collection(_memberAuthCol).get().timeout(_remoteTimeout);
      final groupsSnap =
          await db.collection(_chatGroupsCol).get().timeout(_remoteTimeout);
      final messagesSnap =
          await db.collection(_chatMessagesCol).get().timeout(_remoteTimeout);
      final postsSnap =
          await db.collection(_postsCol).get().timeout(_remoteTimeout);
      final filesSnap =
          await db.collection(_sharedFilesCol).get().timeout(_remoteTimeout);
      final eventsSnap =
          await db.collection(_calendarEventsCol).get().timeout(_remoteTimeout);
      final notifsSnap =
          await db.collection(_notificationsCol).get().timeout(_remoteTimeout);
      final brandingSnap = await db
          .collection(_teamConfigCol)
          .doc(_brandingDocId)
          .get()
          .timeout(_remoteTimeout);

      _recordSnapshotPayloads(_membersCol, membersSnap.docs);
      _recordSnapshotPayloads(_memberAuthCol, memberAuthSnap.docs);
      _recordSnapshotPayloads(_chatGroupsCol, groupsSnap.docs);
      _recordSnapshotPayloads(_chatMessagesCol, messagesSnap.docs);
      _recordSnapshotPayloads(_postsCol, postsSnap.docs);
      _recordSnapshotPayloads(_sharedFilesCol, filesSnap.docs);
      _recordSnapshotPayloads(_calendarEventsCol, eventsSnap.docs);
      _recordSnapshotPayloads(_notificationsCol, notifsSnap.docs);

      final authMap = <String, Map<String, dynamic>>{
        for (final doc in memberAuthSnap.docs) doc.id: doc.data(),
      };
      final localMemberMap = <String, MemberModel>{
        for (final m in local.members) m.id: m,
      };
      final members = membersSnap.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] ??= doc.id;
        final auth = authMap[doc.id];
        final localMember = localMemberMap[doc.id];
        final authPassword = auth?['password'] as String? ?? '';
        if (authPassword.isNotEmpty) {
          data['password'] = authPassword;
        } else {
          final localPassword = localMember?.password ?? '';
          if (localPassword.isNotEmpty) {
            data['password'] = localPassword;
          } else if (doc.id == 'LMT-2026-001') {
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

      final chatGroups = groupsSnap.docs
          .map((d) => ChatGroupModel.fromJson({...d.data(), 'id': d.id}))
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      final chatMessages = messagesSnap.docs
          .map((d) => ChatMessageModel.fromJson({...d.data(), 'id': d.id}))
          .toList()
        ..sort((a, b) => a.sentAt.compareTo(b.sentAt));

      final posts = postsSnap.docs
          .map((d) => PostModel.fromJson({...d.data(), 'id': d.id}))
          .toList()
        ..sort((a, b) => b.publishTime.compareTo(a.publishTime));

      final sharedFiles = filesSnap.docs
          .map((d) => SharedFileModel.fromJson({...d.data(), 'id': d.id}))
          .toList()
        ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

      final calendarEvents = eventsSnap.docs
          .map((d) => CalendarEventModel.fromJson({...d.data(), 'id': d.id}))
          .toList()
        ..sort((a, b) => a.eventDateTime.compareTo(b.eventDateTime));

      final notifications = notifsSnap.docs
          .map((d) => AppNotificationModel.fromJson({...d.data(), 'id': d.id}))
          .toList()
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

      final brandingData = brandingSnap.data();
      if (brandingData != null) {
        _lastSyncedDocs[_teamConfigCol] = {
          _brandingDocId: jsonEncode(brandingData),
        };
      }
      final sloganOfYear =
          (brandingData?['sloganOfYear'] as String?) ?? local.sloganOfYear;
      final verseOfYear =
          (brandingData?['verseOfYear'] as String?) ?? local.verseOfYear;

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
          matchedSaved == null) {
        // The locally remembered account was deleted remotely: invalidate session
        // rather than silently substituting members.first (Admin).
        await AppPreferences.clearLogin();
      }

      final currentUser = matchedSaved ??
          members.where((m) => m.id == local.currentUser.id).firstOrNull ??
          (members.isNotEmpty ? members.first : local.currentUser);

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
        },
        currentUserId: matchedSaved?.id ?? '',
      );

      return LmtRepositorySnapshot(
        biometricEnabled: local.biometricEnabled,
        sloganOfYear: sloganOfYear,
        verseOfYear: verseOfYear,
        currentUser: currentUser,
        members: members.isEmpty ? local.members : members,
        chatGroups: chatGroups.isEmpty ? local.chatGroups : chatGroups,
        chatMessages: chatMessages,
        posts: posts,
        sharedFiles: sharedFiles,
        calendarEvents: calendarEvents,
        notifications: notifications,
      );
    } catch (_) {
      return local;
    }
  }

  @override
  Future<void> persistSnapshot({
    required Map<String, dynamic> stateJson,
    required String currentUserId,
  }) async {
    await localCache.persistSnapshot(
      stateJson: stateJson,
      currentUserId: currentUserId,
    );

    final db = _db;
    if (db == null || _isSyncing) return;

    _isSyncing = true;
    try {
      final authed = await _ensureAuthenticated();
      if (!authed) return;
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

      await _commitCollectionDiff(
        db: db,
        collectionName: _membersCol,
        docs: _prepareCollectionDocs(
          stateJson['members'] as List<dynamic>?,
          uid,
          isMemberCollection: true,
        ),
      );
      await _commitCollectionDiff(
        db: db,
        collectionName: _memberAuthCol,
        docs: _prepareMemberAuthDocs(
          stateJson['members'] as List<dynamic>?,
          uid,
        ),
      );
      await _commitCollectionDiff(
        db: db,
        collectionName: _chatGroupsCol,
        docs: _prepareCollectionDocs(
          stateJson['chatGroups'] as List<dynamic>?,
          uid,
        ),
      );
      await _commitCollectionDiff(
        db: db,
        collectionName: _chatMessagesCol,
        docs: _prepareCollectionDocs(
          stateJson['chatMessages'] as List<dynamic>?,
          uid,
        ),
      );
      await _commitCollectionDiff(
        db: db,
        collectionName: _postsCol,
        docs: _prepareCollectionDocs(
          stateJson['posts'] as List<dynamic>?,
          uid,
        ),
      );
      await _commitCollectionDiff(
        db: db,
        collectionName: _sharedFilesCol,
        docs: _prepareCollectionDocs(
          stateJson['sharedFiles'] as List<dynamic>?,
          uid,
        ),
      );
      await _commitCollectionDiff(
        db: db,
        collectionName: _calendarEventsCol,
        docs: _prepareCollectionDocs(
          stateJson['calendarEvents'] as List<dynamic>?,
          uid,
        ),
      );
      await _commitCollectionDiff(
        db: db,
        collectionName: _notificationsCol,
        docs: _prepareCollectionDocs(
          stateJson['notifications'] as List<dynamic>?,
          uid,
        ),
      );

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
    } catch (_) {
      // Keep local persistence resilient even when offline or restricted.
    } finally {
      _isSyncing = false;
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
          'avatarPath': member.avatarPath,
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
  Future<void> clearCachedState() async {
    await localCache.clearCachedState();
  }
}
