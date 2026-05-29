// ─────────────────────────────────────────────────────────────────────────────
// Habits Screen — daily habits with streaks and 7-day view
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/habit_provider.dart';
import '../../widgets/habit_card.dart';
import 'add_edit_habit_screen.dart';

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildHabitList(context)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditHabitScreen()),
        ),
        backgroundColor: AppColors.gold,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 20),
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Consumer<HabitProvider>(
        builder: (_, provider, __) {
          final done = provider.completedTodayCount;
          final total = provider.totalCount;
          final progress = total > 0 ? done / total : 0.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Daily Habits 🔥', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text('$done of $total completed today', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 14),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.surfaceHighlight,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                  minHeight: 6,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHabitList(BuildContext context) {
    return Consumer<HabitProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.gold));
        }

        if (provider.habits.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 60)),
                const SizedBox(height: 16),
                const Text('No habits yet!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                const Text(
                  'Build daily habits and watch your streaks grow.\nAll habit tracking is completely FREE.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Your First Habit'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddEditHabitScreen()),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.gold,
          onRefresh: provider.loadHabits,
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 100),
            itemCount: provider.habits.length,
            itemBuilder: (context, index) {
              final habit = provider.habits[index];
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
          ),
        );
      },
    );
  }
}
