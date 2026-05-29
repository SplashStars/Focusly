// ─────────────────────────────────────────────────────────────────────────────
// Notification Service — FREE reminders for all users (Todoist charges for this!)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  /// Call this once in main.dart before the app starts
  Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (response) {
        // Handle notification tap — can navigate to the task/habit
      },
    );

    // Create notification channel for Android
    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    // Task reminders channel
    await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
      'task_reminders',
      'Task Reminders',
      description: 'Reminders for your tasks',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    ));

    // Habit reminders channel
    await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
      'habit_reminders',
      'Habit Reminders',
      description: 'Daily reminders for your habits',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    ));
  }

  /// Request notification permissions (needed on Android 13+)
  Future<bool> requestPermissions() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final granted = await androidPlugin?.requestNotificationsPermission();
    return granted ?? false;
  }

  /// Schedule a one-time task reminder
  Future<void> scheduleTaskReminder({
    required String taskId,
    required String taskTitle,
    required DateTime reminderTime,
    String? description,
  }) async {
    if (reminderTime.isBefore(DateTime.now())) return;

    // Use a hash of the ID as the notification int ID
    final notifId = taskId.hashCode.abs() % 100000;

    await _plugin.zonedSchedule(
      notifId,
      '⏰ Task Reminder',
      taskTitle,
      tz.TZDateTime.from(reminderTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          'Task Reminders',
          channelDescription: 'Reminders for your tasks',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(description ?? taskTitle),
          color: const Color(0xFF7C3AED), // Purple
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Schedule a daily recurring habit reminder
  Future<void> scheduleHabitReminder({
    required String habitId,
    required String habitName,
    required DateTime reminderTime,
  }) async {
    final notifId = (habitId.hashCode.abs() % 100000) + 200000;

    await _plugin.zonedSchedule(
      notifId,
      '🔥 Habit Check-in',
      "Don't break your streak! Time for: $habitName",
      _nextInstanceOfTime(reminderTime.hour, reminderTime.minute),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_reminders',
          'Habit Reminders',
          channelDescription: 'Daily reminders for your habits',
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFFF59E0B), // Gold
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily at this time
    );
  }

  /// Cancel a specific notification
  Future<void> cancelTaskReminder(String taskId) async {
    final notifId = taskId.hashCode.abs() % 100000;
    await _plugin.cancel(notifId);
  }

  Future<void> cancelHabitReminder(String habitId) async {
    final notifId = (habitId.hashCode.abs() % 100000) + 200000;
    await _plugin.cancel(notifId);
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Helper: next occurrence of a specific time today or tomorrow
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
