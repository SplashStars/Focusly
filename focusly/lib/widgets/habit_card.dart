// ─────────────────────────────────────────────────────────────────────────────
// Habit Card Widget — habit with streak counter and completion ring
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
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

  Future<void> _toggle() async {
    if (_isAnimating) return;
    _isAnimating = true;

    // Play animation
    await _controller.forward();
    await _controller.reverse();

    if (!mounted) return;

    final provider = context.read<HabitProvider>();
    final completed = await provider.toggleHabitToday(widget.habit.id);

    _isAnimating = false;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            completed
                ? '🔥 ${widget.habit.name} done! Keep it up!'
                : '↩️ Marked as incomplete',
          ),
          backgroundColor: completed ? AppColors.success : AppColors.textMuted,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final habit = widget.habit;
    final isCompleted = habit.isCompletedToday;
    final weekRate = habit.weeklyCompletionRate;
    final last7 = habit.last7Days;
    final color = habit.color;

    return GestureDetector(
      onTap: widget.onTap ?? _toggle,
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
                onTap: _toggle,
                child: CircularPercentIndicator(
                  radius: 32.0,
                  lineWidth: 4.0,
                  percent: weekRate,
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
                        final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: Column(
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: last7[i] ? color : AppColors.surfaceElevated,
                                  shape: BoxShape.circle,
                                ),
                                child: last7[i]
                                    ? Icon(Icons.check, size: 10, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                days[i],
                                style: TextStyle(
                                  fontSize: 9,
                                  color: last7[i] ? color : AppColors.textMuted,
                                ),
                              ),
                            ],
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
