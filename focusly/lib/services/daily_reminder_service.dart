// ─────────────────────────────────────────────────────────────────────────────
// Daily Reminder Service — the one standing nudge that brings people back.
//
// Focusly already had per-task and per-habit reminders, but those only fire if
// the user remembers to set them on each item. Nothing reopened the app on its
// own, which is the whole problem for a *daily* planner. This schedules a
// single repeating notification at a time the user picks.
//
// Defaults to ON at 08:00 so it works for people who never open Settings.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import '../services/locale_controller.dart';

class DailyReminderService extends ChangeNotifier {
  static const _kEnabled = 'daily_reminder_enabled';
  static const _kHour = 'daily_reminder_hour';
  static const _kMinute = 'daily_reminder_minute';

  static const int defaultHour = 8;
  static const int defaultMinute = 0;

  bool _enabled = true;
  int _hour = defaultHour;
  int _minute = defaultMinute;
  bool _loaded = false;

  bool get enabled => _enabled;
  bool get isLoaded => _loaded;
  TimeOfDay get time => TimeOfDay(hour: _hour, minute: _minute);

  /// "08:00" / "19:30" — 24h so it reads the same in every locale.
  String get timeLabel =>
      '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}';

  /// Load saved settings and make sure the OS actually has the alarm queued.
  /// Called on every launch, which also repairs the schedule after a reboot,
  /// an app update, or the user clearing data.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_kEnabled) ?? true;
    _hour = prefs.getInt(_kHour) ?? defaultHour;
    _minute = prefs.getInt(_kMinute) ?? defaultMinute;
    _loaded = true;

    await _apply();
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, value);
    await _apply();
    notifyListeners();
  }

  Future<void> setTime(TimeOfDay value) async {
    _hour = value.hour;
    _minute = value.minute;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kHour, _hour);
    await prefs.setInt(_kMinute, _minute);
    // Changing the time while the reminder is off just stores the preference.
    await _apply();
    notifyListeners();
  }

  Future<void> _apply() async {
    final notifications = NotificationService.instance;
    if (!_enabled) {
      await notifications.cancelDailyPlan();
      return;
    }
    final copy = _copyFor(_hour);
    await notifications.scheduleDailyPlan(
      hour: _hour,
      minute: _minute,
      title: copy.title,
      body: copy.body,
    );
  }

  /// Morning reminders ask you to plan; evening ones ask you to review.
  /// Same nudge either way, but the wording has to match the hour or it reads
  /// as nonsense to anyone who sets it for 9pm.
  _ReminderCopy _copyFor(int hour) {
    if (hour < 12) {
      return _ReminderCopy(
        L10n.t.planYourDay,
        L10n.t.aCoupleOfMinutesNowAnd,
      );
    }
    if (hour < 17) {
      return _ReminderCopy(
        L10n.t.howIsTodayGoing,
        L10n.t.checkOffWhatYouHaveFinished,
      );
    }
    return _ReminderCopy(
      L10n.t.wrapUpYourDay,
      L10n.t.tickOffTodaySWinsKeep,
    );
  }
}

class _ReminderCopy {
  final String title;
  final String body;
  const _ReminderCopy(this.title, this.body);
}
