// ─────────────────────────────────────────────────────────────────────────────
// DaySelector — reusable week-day picker widget
// Usage: DaySelector(selectedDays: _days, accentColor: color, onChanged: (days) => setState(() => _days = days))
// Days use DateTime.weekday convention: 1=Mon, 2=Tue … 7=Sun
// v1.1.0
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class DaySelector extends StatelessWidget {
  final List<int> selectedDays; // 1=Mon … 7=Sun; empty = every day
  final Color accentColor;
  final ValueChanged<List<int>> onChanged;

  const DaySelector({
    super.key,
    required this.selectedDays,
    required this.accentColor,
    required this.onChanged,
  });

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _fullLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  // weekday numbers: 1=Mon … 7=Sun
  static const _weekdays = [1, 2, 3, 4, 5, 6, 7];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick presets row
        Row(
          children: [
            _PresetChip(
              label: 'Every day',
              selected: selectedDays.isEmpty,
              color: accentColor,
              onTap: () => onChanged([]),
            ),
            const SizedBox(width: 8),
            _PresetChip(
              label: 'Weekdays',
              selected: _isWeekdays,
              color: accentColor,
              onTap: () => onChanged([1, 2, 3, 4, 5]),
            ),
            const SizedBox(width: 8),
            _PresetChip(
              label: 'Weekends',
              selected: _isWeekends,
              color: accentColor,
              onTap: () => onChanged([6, 7]),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Day toggle buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (i) {
            final day = _weekdays[i];
            final isSelected = selectedDays.isEmpty || selectedDays.contains(day);
            final isExplicit = selectedDays.contains(day);
            // When selectedDays is empty (every day), show all as active but
            // in a slightly different style to signal "all" vs explicit selection
            return _DayButton(
              label: _labels[i],
              fullLabel: _fullLabels[i],
              isSelected: isExplicit,
              isAllDays: selectedDays.isEmpty,
              accentColor: accentColor,
              onTap: () {
                final next = List<int>.from(selectedDays);
                if (selectedDays.isEmpty) {
                  // Was "every day" — now explicitly deselect this one day
                  next.addAll([1, 2, 3, 4, 5, 6, 7]);
                  next.remove(day);
                } else if (next.contains(day)) {
                  next.remove(day);
                  if (next.isEmpty) {
                    // All deselected → reset to every day
                    onChanged([]);
                    return;
                  }
                } else {
                  next.add(day);
                  next.sort();
                  if (next.length == 7) {
                    // All selected → treat as "every day"
                    onChanged([]);
                    return;
                  }
                }
                next.sort();
                onChanged(next);
              },
            );
          }),
        ),
      ],
    );
  }

  bool get _isWeekdays {
    if (selectedDays.length != 5) return false;
    return [1, 2, 3, 4, 5].every(selectedDays.contains);
  }

  bool get _isWeekends {
    if (selectedDays.length != 2) return false;
    return [6, 7].every(selectedDays.contains);
  }
}

class _DayButton extends StatelessWidget {
  final String label;
  final String fullLabel;
  final bool isSelected;
  final bool isAllDays;
  final Color accentColor;
  final VoidCallback onTap;

  const _DayButton({
    required this.label,
    required this.fullLabel,
    required this.isSelected,
    required this.isAllDays,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = isSelected || isAllDays;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active
              ? (isAllDays && !isSelected
                  ? accentColor.withOpacity(0.25)
                  : accentColor.withOpacity(0.85))
              : AppColors.surface,
          border: Border.all(
            color: active ? accentColor : AppColors.surfaceHighlight,
            width: active ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: accentColor.withOpacity(0.35), blurRadius: 8)]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              color: active ? Colors.white : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : AppColors.surfaceHighlight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: selected ? color : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
