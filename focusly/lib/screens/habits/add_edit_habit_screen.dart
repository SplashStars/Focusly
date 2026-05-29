// ─────────────────────────────────────────────────────────────────────────────
// Add/Edit Habit Screen
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/habit_model.dart';
import '../../providers/habit_provider.dart';
import '../../theme/app_theme.dart';

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
  String _frequency = 'daily';
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
      _frequency = h.frequency;
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
              ? const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold)))
              : TextButton(
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
              // Preview card
              _buildPreview(),
              const SizedBox(height: 20),

              // Name
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

              // Description
              _buildLabel('Description (optional)'),
              TextFormField(
                controller: _descController,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: const InputDecoration(hintText: 'More details about this habit...'),
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              // Color
              _buildLabel('Color'),
              _buildColorPicker(),
              const SizedBox(height: 20),

              // Icon
              _buildLabel('Icon'),
              _buildIconPicker(),
              const SizedBox(height: 20),

              // Frequency
              _buildLabel('Frequency'),
              Row(
                children: [
                  _FreqButton(label: 'Daily', value: 'daily', selected: _frequency == 'daily', onTap: () => setState(() => _frequency = 'daily')),
                  const SizedBox(width: 12),
                  _FreqButton(label: 'Weekly', value: 'weekly', selected: _frequency == 'weekly', onTap: () => setState(() => _frequency = 'weekly')),
                ],
              ),
              const SizedBox(height: 20),

              // Reminder
              _buildLabel('Daily Reminder 🔔 (FREE)'),
              _buildReminderPicker(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
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
                    const Text('🔥 0 day streak  ', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    Text(_frequency == 'daily' ? 'Daily' : 'Weekly',
                        style: TextStyle(fontSize: 12, color: Color(_selectedColor))),
                  ],
                ),
              ],
            ),
          ),
        ],
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
              border: Border.all(
                color: isSelected ? Color(_selectedColor) : AppColors.surfaceHighlight,
              ),
            ),
            child: Icon(
              entry.value,
              size: 20,
              color: isSelected ? Color(_selectedColor) : AppColors.textMuted,
            ),
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
        setState(() {
          _reminderTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
        });
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
                    ? 'Every day at ${DateFormat('h:mm a').format(_reminderTime!)}'
                    : 'No daily reminder',
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

      if (_isEditing) {
        final updated = widget.habit!.copyWith(
          name: _nameController.text.trim(),
          description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
          colorValue: _selectedColor,
          iconName: _selectedIcon,
          frequency: _frequency,
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
          frequency: _frequency,
          reminderTime: _reminderTime,
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

class _FreqButton extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _FreqButton({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withOpacity(0.2) : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppColors.primary : AppColors.surfaceHighlight),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
              color: selected ? AppColors.primary : AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
