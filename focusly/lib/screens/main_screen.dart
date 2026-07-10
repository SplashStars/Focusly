// ─────────────────────────────────────────────────────────────────────────────
// Main Screen — bottom navigation shell
// v1.1.0: Added Planner tab (Activities Organiser with Gantt chart)
//         Nav: Home | Tasks | Planner | Habits | Projects
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/task_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/project_provider.dart';
import 'home/home_screen.dart';
import 'tasks/tasks_screen.dart';
import 'habits/habits_screen.dart';
import 'projects/projects_screen.dart';
import 'planner/planner_screen.dart';
import 'tasks/add_edit_task_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    TasksScreen(),
    PlannerScreen(),   // NEW — Activities Organiser
    HabitsScreen(),
    ProjectsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTasks();
      context.read<HabitProvider>().loadHabits();
      context.read<ProjectProvider>().loadProjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _showFAB ? _buildFAB() : null,
    );
  }

  /// Only show the FAB on Home, Tasks, and Habits screens
  bool get _showFAB => _currentIndex == 0 || _currentIndex == 1 || _currentIndex == 3;

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.surfaceHighlight, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            activeIcon: Icon(Icons.check_circle),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.view_timeline_outlined),
            activeIcon: Icon(Icons.view_timeline),
            label: 'Planner',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_fire_department_outlined),
            activeIcon: Icon(Icons.local_fire_department),
            label: 'Habits',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            activeIcon: Icon(Icons.folder),
            label: 'Projects',
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () => _showAddOptions(context),
      backgroundColor: AppColors.gold,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: const CircleBorder(),
      child: const Icon(Icons.add, size: 28),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.surfaceHighlight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'What do you want to add?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _AddOptionCard(
                    icon: Icons.check_circle_outline,
                    label: 'Task',
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddEditTaskScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AddOptionCard(
                    icon: Icons.local_fire_department,
                    label: 'Habit',
                    color: AppColors.gold,
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() => _currentIndex = 3); // Go to Habits tab
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AddOptionCard(
                    icon: Icons.view_timeline,
                    label: 'Planner',
                    color: AppColors.success,
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() => _currentIndex = 2); // Go to Planner tab
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _AddOptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AddOptionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
