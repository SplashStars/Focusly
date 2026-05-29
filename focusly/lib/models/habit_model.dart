// ─────────────────────────────────────────────────────────────────────────────
// Habit Model — daily habits with streaks (users specifically requested this!)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HabitModel {
  final String id;
  String name;
  String? description;
  int colorValue;       // Stored as int (ARGB)
  String iconName;      // Material icon name string
  String frequency;     // 'daily' or 'weekly'
  DateTime? reminderTime;
  int streakCount;      // Current streak
  int bestStreak;       // All-time best
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
    this.reminderTime,
    this.streakCount = 0,
    this.bestStreak = 0,
    this.sortOrder = 0,
    required this.createdAt,
    this.completedDates = const [],
  });

  Color get color => Color(colorValue);

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

  /// Calculate this week's completion (Mon–today or Mon–Sun)
  double get weeklyCompletionRate {
    final now = DateTime.now();
    // Find Monday of this week
    final monday = now.subtract(Duration(days: now.weekday - 1));
    int daysToCount = now.weekday; // 1=Mon ... 7=Sun
    int completed = 0;
    for (int i = 0; i < daysToCount; i++) {
      final day = monday.add(Duration(days: i));
      if (isCompletedOn(day)) completed++;
    }
    return daysToCount > 0 ? completed / daysToCount : 0.0;
  }

  /// Get the last 7 days completion status
  List<bool> get last7Days {
    return List.generate(7, (i) {
      final day = DateTime.now().subtract(Duration(days: 6 - i));
      return isCompletedOn(day);
    });
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': colorValue,
      'icon_name': iconName,
      'frequency': frequency,
      'reminder_time': reminderTime?.toIso8601String(),
      'streak_count': streakCount,
      'best_streak': bestStreak,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory HabitModel.fromMap(Map<String, dynamic> map) {
    return HabitModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      colorValue: map['color'] as int,
      iconName: map['icon_name'] as String? ?? 'star',
      frequency: map['frequency'] as String? ?? 'daily',
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
      reminderTime: clearReminder ? null : (reminderTime ?? this.reminderTime),
      streakCount: streakCount ?? this.streakCount,
      bestStreak: bestStreak ?? this.bestStreak,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      completedDates: completedDates ?? this.completedDates,
    );
  }
}

/// Predefined icons for habits (user picks one when creating)
class HabitIcons {
  static const Map<String, IconData> icons = {
    'fitness_center': Icons.fitness_center,
    'self_improvement': Icons.self_improvement,
    'menu_book': Icons.menu_book,
    'water_drop': Icons.water_drop,
    'bedtime': Icons.bedtime,
    'directions_run': Icons.directions_run,
    'restaurant': Icons.restaurant_menu,
    'favorite': Icons.favorite,
    'psychology': Icons.psychology,
    'school': Icons.school,
    'music_note': Icons.music_note,
    'brush': Icons.brush,
    'code': Icons.code,
    'local_cafe': Icons.local_cafe,
    'nature': Icons.nature,
    'star': Icons.star,
  };

  static IconData getIcon(String name) {
    return icons[name] ?? Icons.star;
  }
}

/// Predefined colors for habits
class HabitColors {
  static const List<int> colorValues = [
    0xFF7C3AED, // Purple
    0xFF2563EB, // Blue
    0xFF059669, // Emerald
    0xFFDC2626, // Red
    0xFFD97706, // Amber
    0xFFDB2777, // Pink
    0xFF0891B2, // Cyan
    0xFF65A30D, // Lime
    0xFF9333EA, // Fuchsia
    0xFF0D9488, // Teal
  ];
}
