import 'package:shared_preferences/shared_preferences.dart';

/// Immutable result of loading or recording Khelwa data.
class KhelwaSnapshot {
  /// Days elapsed since the user last took Khelwa (0 = taken today).
  final int daysDifference;

  /// Date (midnight) of the last Khelwa.
  final DateTime lastKhelwaDate;

  /// Names of everybody who took Khelwa today.
  final List<String> todayAttendees;

  /// Creates a [KhelwaSnapshot].
  const KhelwaSnapshot({
    required this.daysDifference,
    required this.lastKhelwaDate,
    required this.todayAttendees,
  });
}

/// Local (SharedPreferences) storage for the Daily Khelwa feature.
///
/// Keeps persistence out of widgets. Storage keys are unchanged from the
/// original implementation so existing user data keeps working.
class KhelwaRepository {
  /// Prefix of the per-user "last Khelwa date" key.
  static const String khelwaKeyPrefix = 'last_khelwa_date';

  /// Prefix of the per-day attendees list key.
  static const String attendeesKeyPrefix = 'khelwa_attendees_';

  /// Creates a [KhelwaRepository].
  const KhelwaRepository();

  /// Returns today's date as `yyyy-MM-dd`.
  static String todayDateKey([DateTime? date]) {
    final d = date ?? DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  String _userKey(String userId) => '${khelwaKeyPrefix}_$userId';

  /// Loads the day counter and today's attendees for the given user.
  ///
  /// On first use the baseline is set to yesterday so the counter starts at 1.
  /// If the user already took Khelwa today, their name is ensured in the list.
  Future<KhelwaSnapshot> load({
    required String userId,
    required String userName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userKey = _userKey(userId);
    final attendeesKey = '$attendeesKeyPrefix${todayDateKey()}';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    String? savedDate =
        prefs.getString(userKey) ?? prefs.getString(khelwaKeyPrefix);
    if (savedDate == null) {
      savedDate = today.subtract(const Duration(days: 1)).toIso8601String();
      await prefs.setString(userKey, savedDate);
    }

    final parsed = DateTime.parse(savedDate);
    final lastDate = DateTime(parsed.year, parsed.month, parsed.day);
    final diff = today.difference(lastDate).inDays;
    final safeDiff = diff < 0 ? 0 : diff;

    final attendees = List<String>.from(
      prefs.getStringList(attendeesKey) ?? const <String>[],
    );
    if (safeDiff == 0 && !attendees.contains(userName)) {
      attendees.add(userName);
      await prefs.setStringList(attendeesKey, attendees);
    }

    return KhelwaSnapshot(
      daysDifference: safeDiff,
      lastKhelwaDate: lastDate,
      todayAttendees: attendees,
    );
  }

  /// Records that the user took Khelwa now and returns the updated snapshot.
  Future<KhelwaSnapshot> record({
    required String userId,
    required String userName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final attendeesKey = '$attendeesKeyPrefix${todayDateKey(now)}';

    await prefs.setString(_userKey(userId), now.toIso8601String());
    await prefs.setString(khelwaKeyPrefix, now.toIso8601String());

    final attendees = List<String>.from(
      prefs.getStringList(attendeesKey) ?? const <String>[],
    );
    if (!attendees.contains(userName)) attendees.add(userName);
    await prefs.setStringList(attendeesKey, attendees);

    return KhelwaSnapshot(
      daysDifference: 0,
      lastKhelwaDate: DateTime(now.year, now.month, now.day),
      todayAttendees: attendees,
    );
  }
}
