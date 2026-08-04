// ─────────────────────────────────────────────────────────────────────────────
// Focus Service — persists Pomodoro / Deep Work session statistics
// Stores per-day session counts and total focused minutes in SharedPreferences.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FocusService extends ChangeNotifier {
  static const _kSessionsPrefix = 'focus_sessions_';
  static const _kMinutesPrefix = 'focus_minutes_';

  int _sessionsToday = 0;
  int _minutesToday = 0;

  int get sessionsToday => _sessionsToday;
  int get minutesToday => _minutesToday;

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Load today's totals from disk.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _dayKey(DateTime.now());
    _sessionsToday = prefs.getInt('$_kSessionsPrefix$key') ?? 0;
    _minutesToday = prefs.getInt('$_kMinutesPrefix$key') ?? 0;
    notifyListeners();
  }

  /// Record a completed focus session of [minutes] length.
  Future<void> recordSession(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _dayKey(DateTime.now());

    _sessionsToday = (prefs.getInt('$_kSessionsPrefix$key') ?? 0) + 1;
    _minutesToday = (prefs.getInt('$_kMinutesPrefix$key') ?? 0) + minutes;

    await prefs.setInt('$_kSessionsPrefix$key', _sessionsToday);
    await prefs.setInt('$_kMinutesPrefix$key', _minutesToday);
    notifyListeners();
  }

  /// Total focused minutes for a specific day (used by the Reports screen).
  Future<int> minutesOn(DateTime day) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_kMinutesPrefix${_dayKey(day)}') ?? 0;
  }

  /// Total focused minutes across the last 7 days.
  Future<int> minutesThisWeek() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    var total = 0;
    for (var i = 0; i < 7; i++) {
      total += prefs.getInt('$_kMinutesPrefix${_dayKey(now.subtract(Duration(days: i)))}') ?? 0;
    }
    return total;
  }

  /// Total number of focus sessions across the last 7 days.
  Future<int> sessionsThisWeek() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    var total = 0;
    for (var i = 0; i < 7; i++) {
      total += prefs.getInt('$_kSessionsPrefix${_dayKey(now.subtract(Duration(days: i)))}') ?? 0;
    }
    return total;
  }
}
