// ─────────────────────────────────────────────────────────────────────────────
// Home Screen — today's overview with beautiful purple gradient header
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/task_provider.dart';
import '../../providers/habit_provider.dart';
import '../../widgets/task_card.dart';
import '../../widgets/habit_card.dart';
import '../tasks/add_edit_task_screen.dart';
import '../tasks/tasks_screen.dart';
import '../habits/add_edit_habit_screen.dart';
import '../habits/habits_screen.dart';
import '../settings_screen.dart';
import '../../services/nav_service.dart';
import '../../services/locale_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return L10n.t.goodMorning;
    if (hour < 17) return L10n.t.goodAfternoon;
    return L10n.t.goodEvening;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.gold,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          await context.read<TaskProvider>().loadTasks();
          await context.read<HabitProvider>().loadHabits();
        },
        child: CustomScrollView(
          slivers: [
            _buildHeader(context),
            _buildStatsRow(context),
            _buildSectionHeader(
              L10n.t.todaySFocus,
              seeAllLabel: L10n.t.allTasks,
              onSeeAll: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TasksScreen()),
              ),
            ),
            _buildTodayTasks(context),
            _buildSectionHeader(
              L10n.t.dailyHabits,
              seeAllLabel: L10n.t.allHabits,
              onSeeAll: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HabitsScreen()),
              ),
            ),
            _buildHabits(context),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final now = DateTime.now();
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.of(context).padding.top + 20,
          20,
          28,
        ),
        decoration: BoxDecoration(
          gradient: AppColors.headerGradient,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_getGreeting()} ✨',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          // The header band stays deep purple in light mode too,
                          // so its text cannot follow textPrimary.
                          color: AppColors.headerText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEEE, MMMM d').format(now),
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.headerTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // Same destinations as the bottom bar, reachable from the top.
                _NavDropdown(),
                const SizedBox(width: 10),
                // Settings — the only way into the daily reminder controls.
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.22)),
                    ),
                    child: Icon(Icons.settings_outlined,
                        color: AppColors.headerText, size: 22),
                  ),
                ),
                const SizedBox(width: 10),
                // Quick add button
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddEditTaskScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                    ),
                    child: Icon(Icons.add, color: AppColors.gold, size: 22),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Consumer2<TaskProvider, HabitProvider>(
          builder: (context, tasks, habits, _) {
            final todayTasks = tasks.todayTaskCount;
            final habitsDone = habits.completedTodayCount;
            final habitsTotal = habits.totalCount;

            return Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.check_circle_outline,
                    value: '$todayTasks',
                    label: L10n.t.tasksToday,
                    color: AppColors.primary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TasksScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.local_fire_department,
                    value: '$habitsDone/$habitsTotal',
                    label: L10n.t.habitsDone,
                    color: AppColors.gold,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HabitsScreen()),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title, {
    VoidCallback? onSeeAll,
    String seeAllLabel = L10n.t.seeAll,
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            // Home only previews a few items, so every section links through
            // to the screen that manages the whole list.
            if (onSeeAll != null)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onSeeAll,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(seeAllLabel,
                          style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      Icon(Icons.chevron_right,
                          size: 16, color: AppColors.gold),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayTasks(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return SliverToBoxAdapter(
            child: Center(child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: AppColors.gold),
            )),
          );
        }

        if (provider.todayTasks.isEmpty) {
          return SliverToBoxAdapter(
            child: _EmptyState(
              icon: Icons.celebration_outlined,
              title: L10n.t.allDoneForToday,
              subtitle: L10n.t.noTasksDueTodayAddOne,
              actionLabel: L10n.t.addTask,
              onAction: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditTaskScreen()),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final task = provider.todayTasks[index];
              return TaskCard(
                task: task,
                compact: true,
                // Swiping still completes the task; tapping opens the editor.
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddEditTaskScreen(task: task),
                  ),
                ),
              );
            },
            childCount: provider.todayTasks.length,
          ),
        );
      },
    );
  }

  Widget _buildHabits(BuildContext context) {
    return Consumer<HabitProvider>(
      builder: (context, provider, _) {
        if (provider.habits.isEmpty) {
          return SliverToBoxAdapter(
            child: _EmptyState(
              icon: Icons.local_fire_department_outlined,
              title: L10n.t.noHabitsYet2,
              subtitle: L10n.t.buildPositiveHabitsAndTrackYour,
              actionLabel: L10n.t.addHabit,
              onAction: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditHabitScreen()),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final habit = provider.habits[index];
              // The ring and the day dots still tick the habit; tapping the
              // rest of the card opens the editor.
              return HabitCard(
                habit: habit,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddEditHabitScreen(habit: habit),
                  ),
                ),
              );
            },
            childCount: provider.habits.length > 3 ? 3 : provider.habits.length,
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              // Expanded caps the text to the room actually left in the card.
              // Without it a long value or label overflows the row by a pixel
              // or two and Flutter paints the yellow overflow stripes.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.textMuted), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onAction,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.gold,
              side: BorderSide(color: AppColors.gold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}


/// Mirrors the bottom navigation, plus Settings. Some users never look at the
/// bottom bar, and Settings has no home there at all.
class _NavDropdown extends StatelessWidget {
  const _NavDropdown();

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: L10n.t.menu,
      color: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      offset: const Offset(0, 48),
      onSelected: (value) {
        if (value == 'settings') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
          return;
        }
        context.read<NavService>().go(int.parse(value));
      },
      itemBuilder: (context) => [
        for (final tab in AppTab.values)
          PopupMenuItem<String>(
            value: '${tab.index}',
            child: Row(
              children: [
                Icon(tab.icon, size: 18, color: AppColors.primaryLight),
                const SizedBox(width: 12),
                Text(tab.label,
                    style: TextStyle(color: AppColors.textPrimary)),
              ],
            ),
          ),
        PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings_outlined, size: 18, color: AppColors.gold),
              const SizedBox(width: 12),
              Text(L10n.t.settings, style: TextStyle(color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.22)),
        ),
        child: Icon(Icons.menu_rounded, color: AppColors.headerText, size: 22),
      ),
    );
  }
}
