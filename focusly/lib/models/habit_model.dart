// ─────────────────────────────────────────────────────────────────────────────
// Habit Model — daily habits with streaks
// v1.1.0: Added targetDays — user can pick specific days of the week
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HabitModel {
  final String id;
  String name;
  String? description;
  int colorValue;         // Stored as int (ARGB)
  String iconName;        // Material icon name string
  String frequency;       // 'daily' or 'custom'
  List<int> targetDays;   // 1=Mon, 2=Tue … 7=Sun  (empty = every day)
  DateTime? reminderTime;
  int streakCount;        // Current streak
  int bestStreak;         // All-time best
  int sortOrder;
  DateTime createdAt;
  List<DateTime> completedDates; // dates this habit was done

  HabitModel({
    required this.id,
    required this.name,
    this.description,
    required this.colorValue,
    required this.iconName,
    this.frequency = 'daily',
    this.targetDays = const [],
    this.reminderTime,
    this.streakCount = 0,
    this.bestStreak = 0,
    this.sortOrder = 0,
    required this.createdAt,
    this.completedDates = const [],
  });

  Color get color => Color(colorValue);

  /// Is this habit active on a given weekday? (1=Mon…7=Sun)
  bool isActiveOnWeekday(int weekday) {
    if (targetDays.isEmpty) return true; // empty = every day
    return targetDays.contains(weekday);
  }

  bool get isActiveToday => isActiveOnWeekday(DateTime.now().weekday);

  /// Check if habit was completed today
  bool get isCompletedToday {
    final now = DateTime.now();
    return completedDates.any((date) =>
        date.year == now.year && date.month == now.month && date.day == now.day);
  }

  /// Check if habit was completed on a specific day
  bool isCompletedOn(DateTime day) {
    return completedDates.any((date) =>
        date.year == day.year && date.month == day.month && date.day == day.day);
  }

  /// This week's completion rate (only counts active days)
  double get weeklyCompletionRate {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    int activeDays = 0;
    int completed = 0;
    for (int i = 0; i < now.weekday; i++) {
      final day = monday.add(Duration(days: i));
      if (isActiveOnWeekday(day.weekday)) {
        activeDays++;
        if (isCompletedOn(day)) completed++;
      }
    }
    return activeDays > 0 ? completed / activeDays : 0.0;
  }

  /// Get the last 7 days completion status
  List<bool> get last7Days {
    return List.generate(7, (i) {
      final day = DateTime.now().subtract(Duration(days: 6 - i));
      return isCompletedOn(day);
    });
  }

  /// Human-readable schedule label
  String get scheduleLabel {
    if (targetDays.isEmpty) return 'Every day';
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sorted = List<int>.from(targetDays)..sort();
    return sorted.map((d) => dayNames[d - 1]).join(' · ');
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': colorValue,
      'icon_name': iconName,
      'frequency': frequency,
      'target_days': targetDays.isEmpty ? null : targetDays.join(','),
      'reminder_time': reminderTime?.toIso8601String(),
      'streak_count': streakCount,
      'best_streak': bestStreak,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory HabitModel.fromMap(Map<String, dynamic> map) {
    // Parse target_days from comma-separated string e.g. "1,3,5"
    List<int> parsedDays = [];
    final raw = map['target_days'];
    if (raw != null && raw.toString().isNotEmpty) {
      parsedDays = raw
          .toString()
          .split(',')
          .map((s) => int.tryParse(s.trim()) ?? 0)
          .where((d) => d >= 1 && d <= 7)
          .toList();
    }

    return HabitModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      colorValue: map['color'] as int,
      iconName: map['icon_name'] as String? ?? 'star',
      frequency: map['frequency'] as String? ?? 'daily',
      targetDays: parsedDays,
      reminderTime: map['reminder_time'] != null
          ? DateTime.parse(map['reminder_time'] as String)
          : null,
      streakCount: map['streak_count'] as int? ?? 0,
      bestStreak: map['best_streak'] as int? ?? 0,
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  HabitModel copyWith({
    String? name,
    String? description,
    int? colorValue,
    String? iconName,
    String? frequency,
    List<int>? targetDays,
    DateTime? reminderTime,
    int? streakCount,
    int? bestStreak,
    int? sortOrder,
    List<DateTime>? completedDates,
    bool clearReminder = false,
  }) {
    return HabitModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      colorValue: colorValue ?? this.colorValue,
      iconName: iconName ?? this.iconName,
      frequency: frequency ?? this.frequency,
      targetDays: targetDays ?? this.targetDays,
      reminderTime: clearReminder ? null : (reminderTime ?? this.reminderTime),
      streakCount: streakCount ?? this.streakCount,
      bestStreak: bes