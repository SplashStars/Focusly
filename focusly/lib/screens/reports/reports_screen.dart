// ─────────────────────────────────────────────────────────────────────────────
// Reports Screen — Weekly progress analytics
// Completion rate, daily bar chart, habits kept, active streaks, focus time.
// All figures are computed from the local SQLite database — no cloud, no mock data.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/habit_provider.dart';
import '../../models/task_model.dart';
import '../../models/habit_model.dart';
import '../../database/database_helper.dart';
import '../../services/focus_service.dart';

/// The reporting windows offered on this screen.
enum ReportPeriod {
  weekly('Weekly'),
  monthly('Monthly'),
  yearly('Yearly');

  final String label;
  const ReportPeriod(this.label);
}

/// One column of the completions chart.
class _Bucket {
  final String label;
  final int count;
  const _Bucket(this.label, this.count);
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _loading = true;
  ReportPeriod _period = ReportPeriod.weekly;
  List<TaskModel> _allTasks = [];
  int _focusMinutesWeek = 0;
  int _focusSessionsWeek = 0;

  /// Monday of the current week, normalised to midnight.
  DateTime get _weekStart {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }

  /// First day of the selected reporting window, at midnight.
  DateTime get _periodStart {
    final now = DateTime.now();
    switch (_period) {
      case ReportPeriod.weekly:
        return _weekStart;
      case ReportPeriod.monthly:
        return DateTime(now.year, now.month, 1);
      case ReportPeriod.yearly:
        return DateTime(now.year, 1, 1);
    }
  }

  /// Exclusive end of the selected reporting window.
  DateTime get _periodEnd {
    final now = DateTime.now();
    switch (_period) {
      case ReportPeriod.weekly:
        return _weekStart.add(const Duration(days: 7));
      case ReportPeriod.monthly:
        return DateTime(now.year, now.month + 1, 1);
      case ReportPeriod.yearly:
        return DateTime(now.year + 1, 1, 1);
    }
  }

  /// Completion dates (day precision) falling inside the selected window.
  List<DateTime> get _completionDates {
    final start = _periodStart;
    final end = _periodEnd;
    final out = <DateTime>[];
    for (final t in _allTasks) {
      final c = t.completedAt;
      if (c == null) continue;
      final d = DateTime(c.year, c.month, c.day);
      if (!d.isBefore(start) && d.isBefore(end)) out.add(d);
    }
    return out;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final tasks = await DatabaseHelper.instance.getTasks(includeCompleted: true);
    final focus = context.read<FocusService>();
    final mins = await focus.minutesThisWeek();
    final sessions = await focus.sessionsThisWeek();

    if (!mounted) return;
    setState(() {
      _allTasks = tasks;
      _focusMinutesWeek = mins;
      _focusSessionsWeek = sessions;
      _loading = false;
    });
  }

  // ── Derived metrics ────────────────────────────────────────────────────────

  /// Chart columns for the selected window: days for weekly, weeks for
  /// monthly, months for yearly.
  List<_Bucket> get _buckets {
    final start = _periodStart;
    final dates = _completionDates;

    switch (_period) {
      case ReportPeriod.weekly:
        const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
        final counts = List<int>.filled(7, 0);
        for (final d in dates) {
          final i = d.difference(start).inDays;
          if (i >= 0 && i < 7) counts[i]++;
        }
        return List.generate(7, (i) => _Bucket(labels[i], counts[i]));

      case ReportPeriod.monthly:
        final weeks = (_periodEnd.difference(start).inDays / 7).ceil();
        final counts = List<int>.filled(weeks, 0);
        for (final d in dates) {
          final i = d.difference(start).inDays ~/ 7;
          if (i >= 0 && i < weeks) counts[i]++;
        }
        return List.generate(weeks, (i) => _Bucket('W${i + 1}', counts[i]));

      case ReportPeriod.yearly:
        const labels = [
          'J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'
        ];
        final counts = List<int>.filled(12, 0);
        for (final d in dates) {
          counts[d.month - 1]++;
        }
        return List.generate(12, (i) => _Bucket(labels[i], counts[i]));
    }
  }

  /// Index of the column covering today, so it can be highlighted.
  int get _currentBucket {
    final now = DateTime.now();
    switch (_period) {
      case ReportPeriod.weekly:
        return now.weekday - 1;
      case ReportPeriod.monthly:
        return DateTime(now.year, now.month, now.day)
                .difference(_periodStart)
                .inDays ~/
            7;
      case ReportPeriod.yearly:
        return now.month - 1;
    }
  }

  int get _completedInPeriod => _completionDates.length;

  /// Tasks that were due inside the window, regardless of completion.
  int get _dueInPeriod {
    final start = _periodStart;
    final end = _periodEnd;
    return _allTasks.where((t) {
      final d = t.dueDate;
      if (d == null) return false;
      return !d.isBefore(start) && d.isBefore(end);
    }).length;
  }

  int get _completionRate {
    // Denominator is everything that was on the plate this week: tasks that were
    // due, plus anything completed that had no due date. Avoids a misleading
    // 0% when the user completes ad-hoc tasks.
    final denominator =
        _dueInPeriod > _completedInPeriod ? _dueInPeriod : _completedInPeriod;
    if (denominator == 0) return 0;
    return ((_completedInPeriod / denominator) * 100).round();
  }

  /// A simple 0-100 productivity score blending tasks, habits and focus time.
  int _productivityScore(List<HabitModel> habits) {
    final taskPart = _completionRate * 0.5;
    final habitPart = habits.isEmpty
        ? 0.0
        : (habits.map((h) => h.weeklyCompletionRate).reduce((a, b) => a + b) /
                habits.length) *
            100 *
            0.3;
    // 10 hours of focus in a week maxes out this component.
    final focusPart = (_focusMinutesWeek / 600).clamp(0.0, 1.0) * 100 * 0.2;
    return (taskPart + habitPart + focusPart).round().clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                onRefresh: _load,
                color: AppColors.primary,
                backgroundColor: AppColors.surface,
                child: Consumer<HabitProvider>(
                  builder: (context, habitProvider, _) {
                    final habits = habitProvider.habits;
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 16),
                          _buildPeriodSelector(),
                          const SizedBox(height: 20),
                          _buildScoreCard(habits),
                          const SizedBox(height: 16),
                          _buildSummaryGrid(habits),
                          const SizedBox(height: 24),
                          _buildSectionTitle(_chartTitle),
                          const SizedBox(height: 12),
                          _buildBarChart(),
                          const SizedBox(height: 24),
                          _buildSectionTitle('Top habits'),
                          const SizedBox(height: 12),
                          _buildHabitRanking(habits),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  String get _chartTitle {
    switch (_period) {
      case ReportPeriod.weekly:
        return 'Tasks completed each day';
      case ReportPeriod.monthly:
        return 'Tasks completed each week';
      case ReportPeriod.yearly:
        return 'Tasks completed each month';
    }
  }

  String get _rangeLabel {
    final start = _periodStart;
    final last = _periodEnd.subtract(const Duration(days: 1));
    switch (_period) {
      case ReportPeriod.weekly:
        final fmt = DateFormat('MMM d');
        return '${fmt.format(start)} – ${fmt.format(last)}';
      case ReportPeriod.monthly:
        return DateFormat('MMMM yyyy').format(start);
      case ReportPeriod.yearly:
        return DateFormat('yyyy').format(start);
    }
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_period.label} Report',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _rangeLabel,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  /// Weekly / Monthly / Yearly switch.
  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Row(
        children: ReportPeriod.values.map((p) {
          final selected = p == _period;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _period = p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  p.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      );

  Widget _buildScoreCard(List<HabitModel> habits) {
    final score = _productivityScore(habits);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            height: 76,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 76,
                  height: 76,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 7,
                    backgroundColor: Colors.white.withOpacity(0.15),
                    valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                  ),
                ),
                Text(
                  '$score',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Productivity score',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _scoreMessage(score),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _scoreMessage(int score) {
    final window = _period.label.toLowerCase();
    if (score >= 80) return 'Outstanding $window. You are in a strong rhythm.';
    if (score >= 60) {
      return 'Solid $window. A little more consistency and you are there.';
    }
    if (score >= 40) return 'Steady progress. Try closing a few more tasks.';
    if (score > 0) {
      return 'Slow start. Pick one task and begin — momentum follows.';
    }
    return 'No activity logged in this $window yet. Complete a task to begin.';
  }

  Widget _buildSummaryGrid(List<HabitModel> habits) {
    final habitsKept = habits.where((h) => h.isCompletedToday).length;
    final bestStreak = habits.isEmpty
        ? 0
        : habits.map((h) => h.streakCount).reduce((a, b) => a > b ? a : b);
    final hours = _focusMinutesWeek ~/ 60;
    final mins = _focusMinutesWeek % 60;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.check_circle_outline,
                label: 'Tasks done',
                value: '$_completedInPeriod',
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.percent,
                label: 'Completion',
                value: '$_completionRate%',
                color: AppColors.primaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.local_fire_department_outlined,
                label: 'Best streak',
                value: '$bestStreak d',
                color: AppColors.gold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.hourglass_bottom,
                label: 'Focus time',
                value: hours > 0 ? '${hours}h ${mins}m' : '${mins}m',
                color: AppColors.primaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.timer_outlined,
                label: 'Focus sessions',
                value: '$_focusSessionsWeek',
                color: AppColors.gold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.done_all,
                label: 'Habits today',
                value: '$habitsKept/${habits.length}',
                color: AppColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBarChart() {
    final buckets = _buckets;
    final maxCount = buckets.isEmpty
        ? 0
        : buckets.map((b) => b.count).reduce((a, b) => a > b ? a : b);
    final todayIndex = _currentBucket;
    // Twelve month labels need to be tighter than seven day labels.
    final labelSize = buckets.length > 8 ? 9.0 : 11.0;
    final barGap = buckets.length > 8 ? 2.0 : 5.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(buckets.length, (i) {
                final count = buckets[i].count;
                // Always render a visible sliver so empty days read as zero, not missing.
                final heightFactor = maxCount == 0 ? 0.0 : count / maxCount;
                final barHeight = 8.0 + (heightFactor * 108.0);

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        count == 0 ? '' : '$count',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: labelSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: barGap),
                        height: barHeight,
                        decoration: BoxDecoration(
                          gradient: count == 0
                              ? null
                              : const LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [AppColors.primary, AppColors.primaryLight],
                                ),
                          color: count == 0 ? AppColors.surfaceHighlight : null,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(buckets.length, (i) {
              final isToday = i == todayIndex;
              return Expanded(
                child: Text(
                  buckets[i].label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isToday ? AppColors.gold : AppColors.textMuted,
                    fontSize: labelSize,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitRanking(List<HabitModel> habits) {
    if (habits.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceHighlight),
        ),
        child: const Column(
          children: [
            Icon(Icons.insights, color: AppColors.textMuted, size: 32),
            SizedBox(height: 10),
            Text(
              'No habits yet',
              style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 4),
            Text(
              'Add a habit and your consistency ranking appears here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final ranked = List<HabitModel>.from(habits)
      ..sort((a, b) => b.weeklyCompletionRate.compareTo(a.weeklyCompletionRate));
    final top = ranked.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Column(
        children: top.map((h) {
          final pct = (h.weeklyCompletionRate * 100).round();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: h.color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        h.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: h.weeklyCompletionRate.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: AppColors.surfaceHighlight,
                          valueColor: AlwaysStoppedAnimation(h.color),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$pct%',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}
