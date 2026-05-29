// ─────────────────────────────────────────────────────────────────────────────
// Task Provider — manages all task state for the app
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../database/database_helper.dart';
import '../services/notification_service.dart';

class TaskProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  final _notif = NotificationService.instance;
  static final _uuid = Uuid();

  List<TaskModel> _tasks = [];
  List<TaskModel> _todayTasks = [];
  String? _filterProjectId;
  bool _isLoading = false;

  List<TaskModel> get tasks => _tasks;
  List<TaskModel> get todayTasks => _todayTasks;
  String? get filterProjectId => _filterProjectId;
  bool get isLoading => _isLoading;

  /// Filter tasks by project
  void setProjectFilter(String? projectId) {
    _filterProjectId = projectId;
    loadTasks();
  }

  /// Load all tasks (and today's tasks separately)
  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners();

    _tasks = await _db.getTasks(projectId: _filterProjectId);
    _todayTasks = await _db.getTodayTasks();

    _isLoading = false;
    notifyListeners();
  }

  /// Add a new task (added to TOP of list — fixes Todoist complaint)
  Future<void> addTask({
    required String title,
    String? description,
    String? projectId,
    Priority priority = Priority.medium,
    DateTime? dueDate,
    DateTime? reminderTime,
    Recurrence recurrence = Recurrence.none,
    String? parentTaskId,
  }) async {
    // Sort order: use current highest + 1 so new tasks appear at top
    final maxOrder = _tasks.isEmpty ? 0 : _tasks.map((t) => t.sortOrder).reduce((a, b) => a > b ? a : b);

    final task = TaskModel(
      id: _uuid.v4(),
      title: title,
      description: description,
      projectId: projectId,
      priority: priority,
      dueDate: dueDate,
      reminderTime: reminderTime,
      recurrence: recurrence,
      parentTaskId: parentTaskId,
      sortOrder: maxOrder + 1,
      createdAt: DateTime.now(),
    );

    await _db.insertTask(task);

    // Schedule reminder if set (FREE for all users!)
    if (reminderTime != null) {
      await _notif.scheduleTaskReminder(
        taskId: task.id,
        taskTitle: title,
        reminderTime: reminderTime,
        description: description,
      );
    }

    await loadTasks();
  }

  /// Update an existing task
  Future<void> updateTask(TaskModel task) async {
    await _db.updateTask(task);

    // Re-schedule notification if reminder changed
    await _notif.cancelTaskReminder(task.id);
    if (task.reminderTime != null && !task.isCompleted) {
      await _notif.scheduleTaskReminder(
        taskId: task.id,
        taskTitle: task.title,
        reminderTime: task.reminderTime!,
        description: task.description,
      );
    }

    await loadTasks();
  }

  /// Mark a task as complete (with optional recurring task handling)
  Future<void> completeTask(String id) async {
    final task = _tasks.firstWhere(
      (t) => t.id == id,
      orElse: () => _todayTasks.firstWhere((t) => t.id == id),
    );

    await _db.completeTask(id);
    await _notif.cancelTaskReminder(id);

    // Handle recurring tasks — create the next occurrence
    if (task.recurrence != Recurrence.none && task.dueDate != null) {
      DateTime? nextDue;

      switch (task.recurrence) {
        case Recurrence.daily:
          nextDue = task.dueDate!.add(const Duration(days: 1));
          break;
        case Recurrence.weekly:
          nextDue = task.dueDate!.add(const Duration(days: 7));
          break;
        case Recurrence.monthly:
          nextDue = DateTime(
            task.dueDate!.year,
            task.dueDate!.month + 1,
            task.dueDate!.day,
          );
          break;
        case Recurrence.afterCompletion: // "X days after completion" — users requested this!
          nextDue = DateTime.now().add(const Duration(days: 1));
          break;
        case Recurrence.none:
          break;
      }

      if (nextDue != null) {
        await addTask(
          title: task.title,
          description: task.description,
          projectId: task.projectId,
          priority: task.priority,
          dueDate: nextDue,
          reminderTime: task.reminderTime != null
              ? DateTime(nextDue.year, nextDue.month, nextDue.day,
                  task.reminderTime!.hour, task.reminderTime!.minute)
              : null,
          recurrence: task.recurrence,
        );
        return; // loadTasks() called by addTask
      }
    }

    await loadTasks();
  }

  /// Delete a task
  Future<void> deleteTask(String id) async {
    await _notif.cancelTaskReminder(id);
    await _db.deleteTask(id);
    await loadTasks();
  }

  /// Count incomplete tasks due today
  int get todayTaskCount => _todayTasks.length;

  /// Count completed tasks today
  Future<int> getCompletedTodayCount() async {
    final tasks = await _db.getTasks(includeCompleted: true);
    final today = DateTime.now();
    return tasks.where((t) =>
      t.completedAt != null &&
      t.completedAt!.year == today.year &&
      t.completedAt!.month == today.month &&
      t.completedAt!.day == today.day
    ).length;
  }
}
