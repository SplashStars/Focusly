// ─────────────────────────────────────────────────────────────────────────────
// Add/Edit Habit Screen
// v1.1.0: Replaced simple Daily/Weekly toggle with DaySelector widget
//         so users can tap exactly which days they want the habit active
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/habit_model.dart';
import '../../providers/habit_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/day_selector.dart';

class AddEditHabitScreen extends StatefulWidget {
  final HabitModel? habit;

  const AddEditHabitScreen({super.key, this.habit});

  @override
  State<AddEditHabitScreen> createState() => _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends State<AddEditHabitScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _selectedColor = HabitColors.colorValues[0];
  String _selectedIcon = 'star';
  List<int> _targetDays = []; // empty = every day
  DateTime? _reminderTime;
  bool _isSaving = false;

  bool get _isEditing => widget.habit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final h = widget.habit!;
      _nameController.text = h.name;
      _descController.text = h.description ?? '';
      _selectedColor = h.colorValue;
      _selectedIcon = h.iconName;
      _targetDays = List<int>.from(h.targetDays);
      _reminderTime = h.reminderTime;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(_isEditing ? 'Edit Habit' : 'New Habit'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                  ),
                )
              : TextButton(
                  onPressed: _save,
                  child: const Text(
                    'Save',
                    style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 16),
                  ),
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
              _buildPreview(),
              const SizedBox(height: 20),

              _buildLabel('Habit Name *'),
              TextFormField(
                controller: _nameController,
                autofocus: !_isEditing,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(hintText: 'e.g. Morning Workout, Read 20 pages...'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a habit name' : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              _buildLabel('Description (optional)'),
              TextFormField(
                controller: _descController,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: const InputDecoration(hintText: 'More details about this habit...'),
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              _buildLabel('Color'),
              _buildColorPicker(),
              const SizedBox(height: 20),

              _buildLabel('Icon'),
              _buildIconPicker(),
              const SizedBox(height: 24),

              // ── NEW: Days of the week selector ──────────────────────────
              _buildLabel('Active Days'),
              _buildScheduleSection(),
              const SizedBox(height: 24),

              _buildLabel('Daily Reminder \u{1F514}'),
              _buildReminderPicker(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final sorted = List<int>.from(_targetDays)..sort();
    final scheduleLabel = _targetDays.isEmpty
        ? 'Every day'
        : sorted.map((d) => ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d - 1]).join(' · ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(_selectedColor).withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Color(_selectedColor).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(HabitIcons.getIcon(_selectedIcon), color: Color(_selectedColor), size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameController.text.isEmpty ? 'Habit Preview' : _nameController.text,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('\u{1F525} 0 day streak  ', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    Text(scheduleLabel, style: TextStyle(fontSize: 12, color: Color(_selectedColor))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: DaySelector(
        selectedDays: _targetDays,
        accentColor: Color(_selectedColor),
        onChanged: (days) => setState(() => _targetDays = days),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
    );
  }

  Widget _buildColorPicker() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: HabitColors.colorValues.map((c) {
        final isSelected = _selectedColor == c;
        return GestureDetector(
          onTap: () => setState(() => _selectedColor = c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Color(c),
              shape: BoxShape.circle,
              border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
              boxShadow: isSelected ? [BoxShadow(color: Color(c).withOpacity(0.5), blurRadius: 8, spreadRadius: 2)] : null,
            ),
            child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIconPicker() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: HabitIcons.icons.length,
      itemBuilder: (context, index) {
        final entry = HabitIcons.icons.entries.elementAt(index);
        final isSelected = _selectedIcon == entry.key;
        return GestureDetector(
          onTap: () => setState(() => _selectedIcon = entry.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? Color(_selectedColor).withOpacity(0.2) : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSelected ? Color(_selectedColor) : AppColors.surfaceHighlight),
            ),
            child: Icon(entry.value, size: 20, color: isSelected ? Color(_selectedColor) : AppColors.textMuted),
          ),
        );
      },
    );
  }

  Widget _buildReminderPicker() {
    return GestureDetector(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: _reminderTime != null
              ? TimeOfDay.fromDateTime(_reminderTime!)
              : const TimeOfDay(hour: 8, minute: 0),
          builder: (context, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(primary: AppColors.gold, surface: AppColors.surface),
            ),
            child: child!,
          ),
        );
        if (time == null) return;
        final now = DateTime.now();
        setState(() => _reminderTime = DateTime(now.year, now.month, now.day, time.hour, time.minute));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _reminderTime != null ? AppColors.gold : AppColors.surfaceHighlight),
        ),
        child: Row(
          children: [
            Icon(Icons.alarm, color: _reminderTime != null ? AppColors.gold : AppColors.textMuted, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _reminderTime != null
                    ? 'Reminder at ${DateFormat('h:mm a').format(_reminderTime!)}'
                    : 'No reminder',
                style: TextStyle(color: _reminderTime != null ? AppColors.textPrimary : AppColors.textMuted, fontSize: 14),
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final provider = context.read<HabitProvider>();
      final frequency = _targetDays.isEmpty ? 'daily' : 'custom';

      if (_isEditing) {
        final updated = widget.habit!.copyWith(
          name: _nameController.text.trim(),
          description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
          colorValue: _selectedColor,
          iconName: _selectedIcon,
          frequency: frequency,
          targetDays: _targetDays,
          reminderTime: _reminderTime,
          clearReminder: _reminderTime == null,
        );
        await provider.updateHabit(updated);
      } else {
        await provider.addHabit(
          name: _nameController.text.trim(),
          description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
          colorValue: _selectedColor,
          iconName: _selectedIcon,
          frequency: frequency,
          targetDays: _targetDays,
          reminderTime: _reminderTime,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving habit: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
