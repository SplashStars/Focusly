// ─────────────────────────────────────────────────────────────────────────────
// Task Model — represents a single task or subtask
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

/// Priority levels for tasks
enum Priority {
  high(1, 'High', Color(0xFFEF4444)),
  medium(2, 'Medium', Color(0xFFF59E0B)),
  low(3, 'Low', Color(0xFF10B981));

  final int value;
  final String label;
  final Color color;

  const Priority(this.value, this.label, this.color);

  static Priority fromValue(int value) {
    return Priority.values.firstWhere((p) => p.value == value, orElse: () => Priority.medium);
  }
}

/// Recurrence options for tasks
enum Recurrence {
  none('none', 'No repeat'),
  daily('daily', 'Every day'),
  weekly('weekly', 'Every week'),
  monthly('monthly', 'Every month'),
  afterCompletion('after_completion', 'After completion'); // Todoist users requested this!

  final String value;
  final String label;

  const Recurrence(this.value, this.label);

  static Recurrence fromValue(String value) {
    return Recurrence.values.firstWhere((r) => r.value == value, orElse: () => Recurrence.none);
  }
}

class TaskModel {
  final String id;
  String title;
  String? description;
  String? projectId;
  Priority priority;
  DateTime? dueDate;
  DateTime? reminderTime;
  bool isCompleted;
  String? parentTaskId;   // for subtasks
  int sortOrder;          // tasks added to TOP (fixes Todoist complaint)
  DateTime createdAt;
  DateTime? completedAt;
  Recurrence recurrence;
  List<TaskModel> subtasks; // loaded separately

  TaskModel({
    required this.id,
    required this.title,
    this.description,
    this.projectId,
    this.priority = Priority.medium,
    this.dueDate,
    this.reminderTime,
    this.isCompleted = false,
    this.parentTaskId,
    this.sortOrder = 0,
    required this.createdAt,
    this.completedAt,
    this.recurrence = Recurrence.none,
    this.subtasks = const [],
  });

  /// Convert to a map for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'project_id': projectId,
      'priority': priority.value,
      'due_date': dueDate?.toIso8601String(),
      'reminder_time': reminderTime?.toIso8601String(),
      'is_completed': isCompleted ? 1 : 0,
      'parent_task_id': parentTaskId,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'recurrence': recurrence.value,
    };
  }

  /// Create from a SQLite map
  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      projectId: map['project_id'] as String?,
      priority: Priority.fromValue(map['priority'] as int),
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date'] as String) : null,
      reminderTime: map['reminder_time'] != null ? DateTime.parse(map['reminder_time'] as String) : null,
      isCompleted: (map['is_completed'] as int) == 1,
      parentTaskId: map['parent_task_id'] as String?,
      sortOrder: map['sort_order'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      completedAt: map['completed_at'] != null ? DateTime.parse(map['completed_at'] as String) : null,
      recurrence: Recurrence.fromValue(map['recurrence'] as String? ?? 'none'),
    );
  }

  /// Check if task is due today
  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  /// Check if task is overdue
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  /// Create a copy with modified fields (useful for Provider updates)
  TaskModel copyWith({
    String? title,
    String? description,
    String? projectId,
    Priority? priority,
    DateTime? dueDate,
    DateTime? reminderTime,
    bool? isCompleted,
    Recurrence? recurrence,
    int? sortOrder,
    bool clearDueDate = false,
    bool clearReminder = false,
    bool clearProject = false,
  }) {
    return TaskModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      projectId: clearProject ? null : (projectId ?? this.projectId),
      priority: priority ?? this.priority,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      reminderTime: clearReminder ? null : (reminderTime ?? this.reminderTime),
      isCompleted: isCompleted ?? this.isCompleted,
      parentTaskId: parentTaskId,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      completedAt: isCompleted == true ? DateTime.now() : completedAt,
      recurrence: recurrence ?? this.recurrence,
      subtasks: subtasks,
    );
  }
}
