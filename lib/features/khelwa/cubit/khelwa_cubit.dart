import 'dart:async';

import '../../../core/cubit/lmt_cubit.dart';
import '../../../core/models/lmt_models.dart';
import '../../../core/utils/app_assets.dart';

export '../../../core/cubit/lmt_cubit.dart';

/// Feature Cubit alias for the Daily Khelwa feature module.
typedef KhelwaCubit = LmtCubit;

/// Encapsulates Daily Khelwa Group Summary and End-of-Day attendance reporting.
mixin KhelwaCubitMixin on LmtBaseCubit {
  Timer? _khelwaEndOfDayTimer;

  /// Schedules the automatic end-of-day (11:59 PM) Khelwa report timer.
  void scheduleEndOfDayKhelwaSummaryTimer() {
    _khelwaEndOfDayTimer?.cancel();
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 0);
    final delay = endOfDay.isAfter(now)
        ? endOfDay.difference(now)
        : const Duration(hours: 24);

    _khelwaEndOfDayTimer = Timer(delay, () async {
      await publishEndOfDayKhelwaReportIfNeeded();
      scheduleEndOfDayKhelwaSummaryTimer();
    });
  }

  /// Disposes the end-of-day Khelwa timer.
  void cancelKhelwaTimer() {
    _khelwaEndOfDayTimer?.cancel();
  }

  /// Publishes or updates today's Khelwa attendance list in the dedicated
  /// `grp_khelwa` ("جروب الخلوة اليومية 🙏") chat group.
  Future<void> publishDailyKhelwaSummaryToGroup({
    required List<String> attendeesNames,
    DateTime? forDate,
  }) async {
    final date = forDate ?? DateTime.now();
    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final displayDate =
        '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
    final summaryMsgId = 'msg_khelwa_summary_$dateKey';

    final numberedList = attendeesNames.isEmpty
        ? '• لم يسجل أحد الخلوة اليوم حتى الآن.'
        : attendeesNames
            .asMap()
            .entries
            .map((e) => '${e.key + 1}. ${e.value} ✅')
            .join('\n');

    final summaryContent = '''
📋 تقرير وقائمة الخلوة اليومية ($displayDate) 🙏📖
━━━━━━━━━━━━━━━━━━━━━━
أسماء الأعضاء الذين أخذوا الخلوة اليوم:
$numberedList
━━━━━━━━━━━━━━━━━━━━━━
🌟 إجمالي من أخذوا الخلوة اليوم: ${attendeesNames.length}
ربنا يبارك خلوتكم ويثبتكم في كلمته دائماً! #تغيروا_2026''';

    final existingIdx =
        state.chatMessages.indexWhere((m) => m.id == summaryMsgId);
    final updatedMessages = List<ChatMessageModel>.from(state.chatMessages);

    final summaryMessage = ChatMessageModel(
      id: summaryMsgId,
      groupId: 'grp_khelwa',
      senderId: state.currentUser.id,
      senderName: 'متابعة الخلوة اليومية 🙏',
      senderAvatar: AppAssets.prayIcon,
      senderRole: UserRole.admin,
      type: MessageType.text,
      content: summaryContent,
      seenBy: [
        SeenStatusModel(
          memberId: state.currentUser.id,
          memberName: state.currentUser.name,
          avatarPath: state.currentUser.avatarPath,
          timestamp: DateTime.now(),
        ),
      ],
      sentAt: DateTime.now(),
    );

    if (existingIdx != -1) {
      updatedMessages[existingIdx] = summaryMessage;
    } else {
      updatedMessages.add(summaryMessage);
    }

    emit(state.copyWith(chatMessages: updatedMessages));
    await persistState();
  }

  /// Publishes the end-of-day Khelwa report if not yet posted for today.
  Future<void> publishEndOfDayKhelwaReportIfNeeded() async {
    final now = DateTime.now();
    final dateKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final summaryMsgId = 'msg_khelwa_summary_$dateKey';
    final alreadyPosted = state.chatMessages.any((m) => m.id == summaryMsgId);
    if (!alreadyPosted) {
      await publishDailyKhelwaSummaryToGroup(
        attendeesNames: [state.currentUser.name],
        forDate: now,
      );
    }
  }
}
