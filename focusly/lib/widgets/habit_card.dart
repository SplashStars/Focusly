// ─────────────────────────────────────────────────────────────────────────────
// Habit Card Widget — habit with streak counter and completion ring
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import '../models/habit_model.dart';
import '../providers/habit_provider.dart';
import '../theme/app_theme.dart';

class HabitCard extends StatefulWidget {
  final HabitModel habit;
  final VoidCallback? onTap;

  const HabitCard({super.key, required this.habit, this.onTap});

  @override
  State<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<HabitCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Tick or untick any of the last seven days. Forgetting to tap on the day
  /// itself should not cost the user their streak, so the whole week is live.
  Future<void> _toggleDay(DateTime date) async {
    if (_isAnimating) return;

    final day = DateTime(date.year, date.month, date.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (day.isAfter(today)) {
      _flash('You cannot tick a day that has not happened yet',
          AppColors.textMuted);
      return;
    }

    _isAnimating = true;
    await _controller.forward();
    await _controller.reverse();
    if (!mounted) {
      _isAnimating = false;
      return;
    }

    final provider = context.read<HabitProvider>();
    final completed = await provider.toggleHabitOn(widget.habit.id, day);
    _isAnimating = false;
    if (!mounted) return;

    final isToday = day == today;
    final when = isToday ? '' : ' on ${DateFormat('EEEE').format(day)}';

    if (completed) {
      final streak = widget.habit.streakCount;
      final milestone = _milestoneFor(streak);
      _flash(
        milestone ??
            '\u{1f525} ${widget.habit.name} done$when! Keep it up!',
        AppColors.success,
      );
    } else {
      _flash('↩️ Marked as incomplete$when', AppColors.textMuted);
    }
  }

  /// Celebrate the streaks that actually feel like an achievement.
  String? _milestoneFor(int streak) {
    switch (streak) {
      case 7:
        return '\u{1f389} One full week of ${widget.habit.name}!';
      case 30:
        return '\u{1f3c6} 30 day streak — this is a real habit now.';
      case 100:
        return '\u{1f451} 100 days. Outstanding.';
      default:
        return null;
    }
  }

  void _flash(String message, Color colour) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: colour,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final habit = widget.habit;
    final isCompleted = habit.isCompletedToday;
    final last7 = habit.last7Days;
    final last7Dates = habit.last7Dates;
    final color = habit.color;

    return GestureDetector(
      onTap: widget.onTap ?? () => _toggleDay(DateTime.now()),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: isCompleted
              ? Border.all(color: color.withOpacity(0.5), width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            // Completion ring with icon inside
            AnimatedBuilder(
              animation: _scaleAnim,
              builder: (context, child) => Transform.scale(
                scale: _scaleAnim.value,
                child: child,
              ),
              child: GestureDetector(
                onTap: () => _toggleDay(DateTime.now()),
                child: CircularPercentIndicator(
                  radius: 32.0,
                  lineWidth: 4.0,
                  percent: habit.weeklyProgress,
                  center: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? color.withOpacity(0.2)
                          : AppColors.surfaceElevated,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      HabitIcons.getIcon(habit.iconName),
                      size: 22,
                      color: isCompleted ? color : AppColors.textMuted,
                    ),
                  ),
                  progressColor: color,
                  backgroundColor: color.withOpacity(0.15),
                  circularStrokeCap: CircularStrokeCap.round,
                  animation: true,
                  animationDuration: 600,
                ),
              ),
            ),

            const SizedBox(width: 14),

            // Habit info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + completion indicator
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          habit.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isCompleted ? color : AppColors.textPrimary,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                            decorationColor: color,
                          ),
                        ),
                      ),
                      if (isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check, size: 12, color: color),
                              const SizedBox(width: 3),
                              Text('Done', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Last 7 days dots
                  Row(
                    children: [
                      ...List.generate(7, (i) {
                        // Letters come from the real dates, so the row always
                        // lines up with the days it is actually showing.
                        const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        final date = last7Dates[i];
                        final done = last7[i];
                        final isToday = date.year == DateTime.now().year &&
                            date.month == DateTime.now().month &&
                            date.day == DateTime.now().day;

                        return Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _toggleDay(date),
                            child: Column(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: done
                                        ? color
                                        : AppColors.surfaceElevated,
                                    shape: BoxShape.circle,
                                    border: isToday
                                        ? Border.all(
                                            color: AppColors.gold, width: 1.5)
                                        : null,
                                  ),
                                  child: done
                                      ? const Icon(Icons.check,
                                          size: 10, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  letters[date.weekday - 1],
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: isToday
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: done
                                        ? color
                                        : isToday
                                            ? AppColors.gold
                                            : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const Spacer(),
                      // Streak counter
                      if (habit.streakCount > 0) ...[
                        Text('🔥', style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 3),
                        Text(
                          '${habit.streakCount}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gold,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '${habit.completedThisWeek} of ${habit.weeklyTarget} this week',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: habit.weeklyProgress,
                            minHeight: 4,
                            backgroundColor: AppColors.surfaceElevated,
                            valueColor: AlwaysStoppedAnimation(color),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
