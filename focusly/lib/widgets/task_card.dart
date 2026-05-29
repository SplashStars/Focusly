// ─────────────────────────────────────────────────────────────────────────────
// Task Card Widget — beautiful swipeable task card
// Swipe RIGHT → complete   |   Swipe LEFT → delete
// (Solves Todoist's accidental-completion complaint — needs deliberate swipe)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../models/project_model.dart';
import '../providers/task_provider.dart';
import '../providers/project_provider.dart';
import '../theme/app_theme.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback? onTap;
  final bool compact;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.read<TaskProvider>();
    final project = context.read<ProjectProvider>().getProjectById(task.projectId);

    return Slidable(
      key: ValueKey(task.id),
      // Swipe RIGHT → Complete (green) — deliberate action prevents accidents
      startActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) async {
              await taskProvider.completeTask(task.id);
            },
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            icon: Icons.check_circle_outline,
            label: 'Done',
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
          ),
        ],
      ),
      // Swipe LEFT → Delete (red)
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) async {
              _showDeleteConfirm(context, taskProvider);
            },
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: 'Delete',
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(
                color: task.priority.color,
                width: 4, // Priority strip on left edge
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Priority indicator dot
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: task.priority.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    // Task title
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontSize: compact ? 14 : 15,
                          fontWeight: FontWeight.w500,
                          color: task.isCompleted
                              ? AppColors.textMuted
                              : AppColors.textPrimary,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: AppColors.textMuted,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Swipe hint icon
                    const Icon(
                      Icons.swipe,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
                // Description preview
                if (task.description != null && task.description!.isNotEmpty && !compact) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 18),
                    child: Text(
                      task.description!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                // Bottom row: metadata chips
                Padding(
                  padding: const EdgeInsets.only(left: 18),
                  child: Row(
                    children: [
                      // Due date chip
                      if (task.dueDate != null) ...[
                        _MetaChip(
                          icon: Icons.calendar_today,
                          label: _formatDueDate(task.dueDate!),
                          color: task.isOverdue ? AppColors.error : AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                      ],
                      // Reminder chip
                      if (task.reminderTime != null) ...[
                        _MetaChip(
                          icon: Icons.notifications_outlined,
                          label: DateFormat('h:mm a').format(task.reminderTime!),
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 6),
                      ],
                      // Project chip
                      if (project != null) ...[
                        _MetaChip(
                          icon: Icons.circle,
                          label: project.name,
                          color: project.color,
                          iconSize: 8,
                        ),
                        const SizedBox(width: 6),
                      ],
                      // Subtask count
                      if (task.subtasks.isNotEmpty) ...[
                        _MetaChip(
                          icon: Icons.account_tree_outlined,
                          label:
                              '${task.subtasks.where((s) => s.isCompleted).length}/${task.subtasks.length}',
                          color: AppColors.textMuted,
                        ),
                      ],
                      const Spacer(),
                      // Priority label
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: task.priority.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          task.priority.label,
                          style: TextStyle(
                            fontSize: 10,
                            color: task.priority.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);
    final diff = taskDate.difference(today).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff < 0) return '${diff.abs()}d overdue';
    if (diff < 7) return DateFormat('EEE').format(date);
    return DateFormat('MMM d').format(date);
  }

  void _showDeleteConfirm(BuildContext context, TaskProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Task?', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          '"${task.title}" will be permanently deleted.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteTask(task.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double iconSize;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
    this.iconSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize, color: color),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}
