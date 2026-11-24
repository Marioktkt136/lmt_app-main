import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/cubit/lmt_cubit.dart';
import '../../../core/models/lmt_models.dart';
import '../../../core/utils/app_assets.dart';
import '../data/khelwa_repository.dart';

export '../../../core/cubit/lmt_cubit.dart';

/// Feature Cubit alias for the Daily Khelwa feature module.
typedef KhelwaCubit = LmtCubit;

/// Encapsulates Daily Khelwa Group Summary and Automatic 12:00 AM Midnight
/// End-of-Day attendance reporting.
mixin KhelwaCubitMixin on LmtBaseCubit {
  Timer? _khelwaEndOfDayTimer;

  KhelwaDayModel? _khelwaDayForKey(String dateKey) {
    for (final d in state.khelwaDays) {
      if (d.dateKey == dateKey) return d;
    }
    return null;
  }

  /// Returns ordered display names of everyone who took Khelwa on [date]
  /// (defaults to today) synced via Cloud Firestore `khelwa_days`.
  List<String> todayKhelwaAttendees([DateTime? date]) {
    final dateKey = KhelwaRepository.todayDateKey(date);
    final day = _khelwaDayForKey(dateKey);
    if (day == null || day.attendeeIds.isEmpty) {
      return day?.attendeeNames ?? const <String>[];
    }
    final result = <String>[];
    for (var i = 0; i < day.attendeeIds.length; i++) {
      final id = day.attendeeIds[i];
      final memberName =
          state.members.where((m) => m.id == id).map((m) => m.name).firstOrNull;
      final storedName =
          i < day.attendeeNames.length ? day.attendeeNames[i] : id;
      result.add(memberName ?? storedName);
    }
    return result;
  }

  /// Returns days elapsed since [userId] last took Khelwa (`0` = today,
  /// `1+` = not yet recorded today). Uses synced Firestore `khelwa_days`.
  int khelwaDaysDifferenceForUser(String userId, {DateTime? now}) {
    final ref = now ?? DateTime.now();
    final today = DateTime(ref.year, ref.month, ref.day);
    final todayKey = KhelwaRepository.todayDateKey(today);

    final todayRecord = _khelwaDayForKey(todayKey);
    if (todayRecord != null && todayRecord.attendeeIds.contains(userId)) {
      return 0;
    }

    DateTime? latestPastDate;
    for (final day in state.khelwaDays) {
      if (!day.attendeeIds.contains(userId)) continue;
      final parsed = day.parsedDate;
      if (parsed == null) continue;
      if (parsed.isAfter(today)) continue;
      if (latestPastDate == null || parsed.isAfter(latestPastDate)) {
        latestPastDate = parsed;
      }
    }

    if (latestPastDate == null) return 1;
    final diff = today.difference(latestPastDate).inDays;
    return diff <= 0 ? 1 : diff;
  }

  /// Records today's Khelwa check-in for the active user in BOTH local cache
  /// and Cloud Firestore (`khelwa_days/{todayKey}`) atomically.
  Future<void> recordTodayKhelwa() async {
    final now = DateTime.now();
    final todayKey = KhelwaRepository.todayDateKey(now);
    final user = state.currentUser;

    await const KhelwaRepository().record(userId: user.id, userName: user.name);

    final updatedDays = List<KhelwaDayModel>.from(state.khelwaDays);
    final idx = updatedDays.indexWhere((d) => d.dateKey == todayKey);
    if (idx == -1) {
      updatedDays.add(
        KhelwaDayModel(
          id: todayKey,
          dateKey: todayKey,
          attendeeIds: [user.id],
          attendeeNames: [user.name],
          updatedAt: now,
        ),
      );
    } else {
      final existing = updatedDays[idx];
      final ids = List<String>.from(existing.attendeeIds);
      final names = List<String>.from(existing.attendeeNames);
      final userIdx = ids.indexOf(user.id);
      if (userIdx == -1) {
        ids.add(user.id);
        names.add(user.name);
      } else if (userIdx < names.length) {
        names[userIdx] = user.name;
      }
      updatedDays[idx] = existing.copyWith(
        attendeeIds: ids,
        attendeeNames: names,
        updatedAt: now,
      );
    }

    emit(state.copyWith(khelwaDays: updatedDays));
    await repository.recordKhelwaCheckIn(
      dateKey: todayKey,
      memberId: user.id,
      memberName: user.name,
    );
    await persistState();
  }

  /// Clears today's Khelwa list across all devices (Administrator only).
  Future<void> resetTodayKhelwa() async {
    if (state.currentUser.role != UserRole.admin) return;
    final now = DateTime.now();
    final todayKey = KhelwaRepository.todayDateKey(now);

    await const KhelwaRepository().resetTodayAttendees();

    final updatedDays = List<KhelwaDayModel>.from(state.khelwaDays);
    final idx = updatedDays.indexWhere((d) => d.dateKey == todayKey);
    if (idx != -1) {
      updatedDays[idx] = updatedDays[idx].copyWith(
        attendeeIds: const [],
        attendeeNames: const [],
        updatedAt: now,
      );
    }
    emit(state.copyWith(khelwaDays: updatedDays));
    await repository.resetKhelwaDay(dateKey: todayKey);
    await persistState();
  }

  /// Schedules the automatic 12:00 AM midnight Khelwa report timer and catches
  /// up any completed past days whose 12:00 AM report was not yet posted.
  void scheduleEndOfDayKhelwaSummaryTimer() {
    _khelwaEndOfDayTimer?.cancel();
    unawaited(_syncMidnightKhelwaReportsOnStartup());

    final now = DateTime.now();
    // Exact 12:00 AM midnight at the end of today (00:00:00 of the next day)
    final nextMidnight = DateTime(now.year, now.month, now.day + 1, 0, 0, 0);
    final endedDay = DateTime(now.year, now.month, now.day);
    final delay = nextMidnight.difference(now);

    _khelwaEndOfDayTimer = Timer(delay, () async {
      await publishEndOfDayKhelwaReportForDate(endedDay);
      scheduleEndOfDayKhelwaSummaryTimer();
    });
  }

  /// Disposes the end-of-day Khelwa timer.
  void cancelKhelwaTimer() {
    _khelwaEndOfDayTimer?.cancel();
  }

  /// Ensures that today's report is NOT posted prematurely before 12:00 AM,
  /// and automatically posts any past completed day's Khelwa report that ended
  /// while the app was closed at 12:00 AM.
  Future<void> _syncMidnightKhelwaReportsOnStartup() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayKey = KhelwaRepository.todayDateKey(today);
    final todayMsgId = 'msg_khelwa_summary_$todayKey';

    // Remove any premature manual summary for today (since 12:00 AM hasn't arrived yet)
    if (state.chatMessages.any((m) => m.id == todayMsgId)) {
      final cleaned =
          state.chatMessages.where((m) => m.id != todayMsgId).toList();
      emit(state.copyWith(chatMessages: cleaned));
      await persistState();
    }

    // Check completed past days from BOTH Firestore khelwaDays & SharedPreferences
    final checkedKeys = <String>{};
    for (final day in state.khelwaDays) {
      final dateKey = day.dateKey;
      if (dateKey == todayKey || !checkedKeys.add(dateKey)) continue;
      final pastDate = day.parsedDate;
      if (pastDate != null && pastDate.isBefore(today)) {
        final summaryMsgId = 'msg_khelwa_summary_$dateKey';
        final alreadyPosted =
            state.chatMessages.any((m) => m.id == summaryMsgId);
        if (!alreadyPosted && day.attendeeNames.isNotEmpty) {
          await publishDailyKhelwaSummaryToGroup(
            attendeesNames: day.attendeeNames,
            forDate: pastDate,
          );
        }
      }
    }

    for (final key in prefs.getKeys()) {
      if (!key.startsWith(KhelwaRepository.attendeesKeyPrefix)) continue;
      final dateKey =
          key.substring(KhelwaRepository.attendeesKeyPrefix.length);
      if (dateKey == todayKey || !checkedKeys.add(dateKey)) continue;

      final parts = dateKey.split('-');
      if (parts.length != 3) continue;
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final day = int.tryParse(parts[2]);
      if (year == null || month == null || day == null) continue;

      final pastDate = DateTime(year, month, day);
      if (pastDate.isBefore(today)) {
        final summaryMsgId = 'msg_khelwa_summary_$dateKey';
        final alreadyPosted =
            state.chatMessages.any((m) => m.id == summaryMsgId);
        if (!alreadyPosted) {
          final attendees =
              prefs.getStringList(key) ?? const <String>[];
          if (attendees.isNotEmpty) {
            await publishDailyKhelwaSummaryToGroup(
              attendeesNames: attendees,
              forDate: pastDate,
            );
          }
        }
      }
    }
  }

  /// Automatically publishes the 12:00 AM midnight Khelwa attendance summary
  /// for the given completed [date] into `grp_khelwa`.
  Future<void> publishEndOfDayKhelwaReportForDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = KhelwaRepository.todayDateKey(date);
    final summaryMsgId = 'msg_khelwa_summary_$dateKey';
    final alreadyPosted = state.chatMessages.any((m) => m.id == summaryMsgId);
    if (alreadyPosted) return;

    final cloudAttendees = _khelwaDayForKey(dateKey)?.attendeeNames;
    final attendeesKey = '${KhelwaRepository.attendeesKeyPrefix}$dateKey';
    final localAttendees =
        prefs.getStringList(attendeesKey) ?? const <String>[];
    final mergedAttendees = <String>{
      ...?cloudAttendees,
      ...localAttendees,
    }.toList();

    await publishDailyKhelwaSummaryToGroup(
      attendeesNames: mergedAttendees,
      forDate: date,
    );
  }

  /// Publishes a day's Khelwa attendance list automatically (authored by the
  /// system bot, not by any individual user) in `grp_khelwa` ("جروب الخلوة اليومية 🙏").
  Future<void> publishDailyKhelwaSummaryToGroup({
    required List<String> attendeesNames,
    DateTime? forDate,
  }) async {
    final date = forDate ?? DateTime.now();
    final dateKey = KhelwaRepository.todayDateKey(date);
    final displayDate =
        '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
    final summaryMsgId = 'msg_khelwa_summary_$dateKey';

    final numberedList = attendeesNames.isEmpty
        ? '• لم يسجل أحد الخلوة في هذا اليوم.'
        : attendeesNames
            .asMap()
            .entries
            .map((e) => '${e.key + 1}. ${e.value} ✅')
            .join('\n');

    final summaryContent = '''
🕛 تقرير الخلوة اليومية التلقائي (12:00 AM) — ($displayDate) 🙏📖
━━━━━━━━━━━━━━━━━━━━━━
أسماء الأعضاء الذين أخذوا الخلوة في هذا اليوم:
$numberedList
━━━━━━━━━━━━━━━━━━━━━━
🌟 إجمالي من أخذوا الخلوة: ${attendeesNames.length}
ربنا يبارك خلوتكم ويثبتكم في كلمته دائماً! #تغيروا_2026''';

    final existingIdx =
        state.chatMessages.indexWhere((m) => m.id == summaryMsgId);
    final updatedMessages = List<ChatMessageModel>.from(state.chatMessages);

    final midnightTimestamp = DateTime(
      date.year,
      date.month,
      date.day + 1,
      0,
      0,
      0,
    );

    final summaryMessage = ChatMessageModel(
      id: summaryMsgId,
      groupId: 'grp_khelwa',
      senderId: 'system_auto_khelwa',
      senderName: 'النظام التلقائي - الخلوة اليومية 🕛🙏',
      senderAvatar: AppAssets.prayIcon,
      senderRole: UserRole.admin,
      type: MessageType.text,
      content: summaryContent,
      seenBy: const [],
      sentAt: midnightTimestamp.isAfter(DateTime.now())
          ? DateTime.now()
          : midnightTimestamp,
    );

    if (existingIdx != -1) {
      updatedMessages[existingIdx] = summaryMessage;
    } else {
      updatedMessages.add(summaryMessage);
    }

    emit(state.copyWith(chatMessages: updatedMessages));

    final khelwaGroup =
        state.chatGroups.where((g) => g.id == 'grp_khelwa').firstOrNull;
    pushNotification(
      id: 'notif_khelwa_summary_$dateKey',
      title: 'جروب الخلوة اليومية 🙏',
      description:
          'تم نشر التقرير اليومي التلقائي لمن أخذوا الخلوة ($displayDate) - الإجمالي: ${attendeesNames.length}',
      category: NotificationCategory.chat,
      targetTabIndex: 1,
      targetGroupId: 'grp_khelwa',
      targetMemberIds: khelwaGroup?.memberIds ?? const [],
    );

    await persistState();
  }
}
