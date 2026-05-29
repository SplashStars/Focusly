// ─────────────────────────────────────────────────────────────────────────────
// Add/Edit Task Screen — visual date + time pickers (not natural language)
// Fixes Todoist complaint: "why can't it be a regular calendar to select from?"
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../providers/project_provider.dart';
import '../../models/project_model.dart';
import '../../theme/app_theme.dart';

class AddEditTaskScreen extends StatefulWidget {
  final TaskModel? task; // null = add mode, non-null = edit mode

  const AddEditTaskScreen({super.key, this.task});

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Priority _priority = Priority.medium;
  DateTime? _dueDate;
  DateTime? _reminderTime;
  Recurrence _recurrence = Recurrence.none;
  String? _selectedProjectId;
  bool _isSaving = false;

  // For subtasks
  final List<TextEditingController> _subtaskControllers = [];

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final t = widget.task!;
      _titleController.text = t.title;
      _descController.text = t.description ?? '';
      _priority = t.priority;
      _dueDate = t.dueDate;
      _reminderTime = t.reminderTime;
      _recurrence = t.recurrence;
      _selectedProjectId = t.projectId;

      for (final sub in t.subtasks) {
        _subtaskControllers.add(TextEditingController(text: sub.title));
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    for (final c in _subtaskControllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(_isEditing ? 'Edit Task' : 'New Task'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold)),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Save', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 16)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              _buildSectionLabel('Task Title *'),
              TextFormField(
                controller: _titleController,
                autofocus: !_isEditing,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'What needs to be done?',
                  prefixIcon: Icon(Icons.edit_outlined, color: AppColors.textMuted),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a task title' : null,
                maxLines: 2,
                minLines: 1,
              ),
              const SizedBox(height: 16),

              // Description
              _buildSectionLabel('Description (optional)'),
              TextFormField(
                controller: _descController,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Add more details...',
                  prefixIcon: Icon(Icons.notes_outlined, color: AppColors.textMuted),
                ),
                maxLines: 3,
                minLines: 1,
              ),
              const SizedBox(height: 20),

              // Priority
              _buildSectionLabel('Priority'),
              Row(
                children: Priority.values.map((p) => _PriorityButton(
                  priority: p,
                  isSelected: _priority == p,
                  onTap: () => setState(() => _priority = p),
                )).toList(),
              ),
              const SizedBox(height: 20),

              // Due Date
              _buildSectionLabel('Due Date'),
              _buildDatePicker(),
              const SizedBox(height: 16),

              // Reminder (FREE — unlike Todoist!)
              _buildSectionLabel('Reminder 🔔 (FREE)'),
              _buildReminderPicker(),
              const SizedBox(height: 16),

              // Recurrence
              _buildSectionLabel('Repeat'),
              _buildRecurrencePicker(),
              const SizedBox(height: 16),

              // Project
              _buildSectionLabel('Project'),
              _buildProjectPicker(context),
              const SizedBox(height: 20),

              // Subtasks
              _buildSectionLabel('Subtasks'),
              _buildSubtasks(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _dueDate ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 1)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
          builder: (context, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.gold,
                surface: AppColors.surface,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) setState(() => _dueDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _dueDate != null ? AppColors.primary : AppColors.surfaceHighlight,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              color: _dueDate != null ? AppColors.primary : AppColors.textMuted,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _dueDate != null
                    ? DateFormat('EEE, MMM d, yyyy').format(_dueDate!)
                    : 'No due date',
                style: TextStyle(
                  color: _dueDate != null ? AppColors.textPrimary : AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
            ),
            if (_dueDate != null)
              GestureDetector(
                onTap: () => setState(() => _dueDate = null),
                child: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderPicker() {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _reminderTime ?? (_dueDate ?? DateTime.now()),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
          builder: (context, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(primary: AppColors.gold, surface: AppColors.surface),
            ),
            child: child!,
          ),
        );
        if (date == null || !mounted) return;

        final time = await showTimePicker(
          context: context,
          initialTime: _reminderTime != null
              ? TimeOfDay.fromDateTime(_reminderTime!)
              : const TimeOfDay(hour: 9, minute: 0),
          builder: (context, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(primary: AppColors.gold, surface: AppColors.surface),
            ),
            child: child!,
          ),
        );
        if (time == null) return;

        setState(() {
          _reminderTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _reminderTime != null ? AppColors.gold : AppColors.surfaceHighlight,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.notifications_outlined,
              color: _reminderTime != null ? AppColors.gold : AppColors.textMuted,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _reminderTime != null
                    ? DateFormat('EEE, MMM d · h:mm a').format(_reminderTime!)
                    : 'Set reminder (tap to choose date & time)',
                style: TextStyle(
                  color: _reminderTime != null ? AppColors.textPrimary : AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
            ),
            if (_reminderTime != null)
              GestureDetector(
                onTap: () => setState(() => _reminderTime = null),
                child: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurrencePicker() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Recurrence>(
          value: _recurrence,
          isExpanded: true,
          dropdownColor: AppColors.surfaceElevated,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          icon: const Icon(Icons.expand_more, color: AppColors.textMuted),
          items: Recurrence.values.map((r) => DropdownMenuItem(
            value: r,
            child: Row(
              children: [
                Icon(Icons.repeat, size: 18, color: _recurrence == r ? AppColors.primary : AppColors.textMuted),
                const SizedBox(width: 10),
                Text(r.label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
              ],
            ),
          )).toList(),
          onChanged: (v) => setState(() => _recurrence = v!),
        ),
      ),
    );
  }

  Widget _buildProjectPicker(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, provider, _) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceHighlight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _selectedProjectId,
              isExpanded: true,
              dropdownColor: AppColors.surfaceElevated,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              icon: const Icon(Icons.expand_more, color: AppColors.textMuted),
              hint: const Row(
                children: [
                  Icon(Icons.folder_outlined, size: 18, color: AppColors.textMuted),
                  SizedBox(width: 10),
                  Text('No project', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                ],
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('No project', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ...provider.projects.map((p) => DropdownMenuItem<String?>(
                  value: p.id,
                  child: Row(
                    children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: p.color, shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Text(p.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                    ],
                  ),
                )),
              ],
              onChanged: (v) => setState(() => _selectedProjectId = v),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubtasks() {
    return Column(
      children: [
        ..._subtaskControllers.asMap().entries.map((entry) {
          final i = entry.key;
          final controller = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.subdirectory_arrow_right, size: 18, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Subtask ${i + 1}',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                  onPressed: () => setState(() {
                    _subtaskControllers.removeAt(i).dispose();
                  }),
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: () => setState(() => _subtaskControllers.add(TextEditingController())),
          icon: const Icon(Icons.add, size: 16, color: AppColors.textSecondary),
          label: const Text('Add subtask', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final provider = context.read<TaskProvider>();
    final title = _titleController.text.trim();

    try {
      if (_isEditing) {
        final updated = widget.task!.copyWith(
          title: title,
          description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
          priority: _priority,
          dueDate: _dueDate,
          reminderTime: _reminderTime,
          recurrence: _recurrence,
          projectId: _selectedProjectId,
          clearDueDate: _dueDate == null,
          clearReminder: _reminderTime == null,
          clearProject: _selectedProjectId == null,
        );
        await provider.updateTask(updated);
      } else {
        await provider.addTask(
          title: title,
          description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
          priority: _priority,
          dueDate: _dueDate,
          reminderTime: _reminderTime,
          recurrence: _recurrence,
          projectId: _selectedProjectId,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _PriorityButton extends StatelessWidget {
  final Priority priority;
  final bool isSelected;
  final VoidCallback onTap;

  const _PriorityButton({required this.priority, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? priority.color.withOpacity(0.2) : AppColors.surface,
            border: Border.all(
              color: isSelected ? priority.color : AppColors.surfaceHighlight,
              width: isSelected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(Icons.flag, color: isSelected ? priority.color : AppColors.textMuted, size: 18),
              const SizedBox(height: 4),
              Text(
                priority.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                  color: isSelected ? priority.color : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
