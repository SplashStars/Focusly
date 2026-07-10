// ─────────────────────────────────────────────────────────────────────────────
// Habit Provider — manages habit state and streaks
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/habit_model.dart';
import '../database/database_helper.dart';
import '../services/notification_service.dart';

class HabitProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  final _notif = NotificationService.instance;
  static final _uuid = Uuid();

  List<HabitModel> _habits = [];
  bool _isLoading = false;

  List<HabitModel> get habits => _habits;
  bool get isLoading => _isLoading;

  /// Count of habits completed today
  int get completedTodayCount => _habits.where((h) => h.isCompletedToday).length;

  /// Total habits count
  int get totalCount => _habits.length;

  Future<void> loadHabits() async {
    _isLoading = true;
    notifyListeners();

    _habits = await _db.getHabits();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addHabit({
    required String name,
    String? description,
    required int colorValue,
    required String iconName,
    String frequency = 'daily',
    List<int> targetDays = const [],
    DateTime? reminderTime,
  }) async {
    final habit = HabitModel(
      id: _uuid.v4(),
      name: name,
      description: description,
      colorValue: colorValue,
      iconName: iconName,
      frequency: frequency,
      targetDays: targetDays,
      reminderTime: reminderTime,
      sortOrder: _habits.length,
      createdAt: DateTime.now(),
    );

    await _db.insertHabit(habit);

    if (reminderTime != null) {
      await _notif.scheduleHabitReminder(
        habitId: habit.id,
        habitName: name,
        reminderTime: reminderTime,
      );
    }

    await loadHabits();
  }

  Future<void> updateHabit(HabitModel habit) async {
    await _db.updateHabit(habit);

    await _notif.cancelHabitReminder(habit.id);
    if (habit.reminderTime != null) {
      await _notif.scheduleHabitReminder(
        habitId: habit.id,
        habitName: habit.name,
        reminderTime: habit.reminderTime!,
      );
    }

    await loadHabits();
  }

  Future<void> deleteHabit(String id) async {
    await _notif.cancelHabitReminder(id);
    await _db.deleteHabit(id);
    await loadHabits();
  }

  /// Toggle completion for today — returns true if now completed
  Future<bool> toggleHabitToday(String habitId) async {
    final completed = await _db.toggleHabitCompletion(habitId);
    await loadHabits();
    return completed;
  }
}
