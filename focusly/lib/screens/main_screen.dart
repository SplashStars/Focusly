// ─────────────────────────────────────────────────────────────────────────────
// Main Screen — bottom navigation shell
// v1.1.1: Added Focus Mode (Pomodoro / Deep Work) and Weekly Reports.
//         Nav: Home | Tasks | Focus | Planner | Habits | Stats
//         Projects are reached from the add sheet and the Home screen.
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
import 'focus/focus_screen.dart';
import 'reports/reports_screen.dart';
import 'tasks/add_edit_task_screen.dart';
import 'upgrade/upgrade_screen.dart';
import '../services/entitlement_service.dart';
import '../services/ads_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    FocusScreen(),     // Timer wheel, Strict Mode, Full Screen
    PlannerScreen(),   // Activities Organiser (Gantt)
    HabitsScreen(),
    ReportsScreen(),   // Weekly / Monthly / Yearly
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
    final ent = context.watch<EntitlementService>();

    return Scaffold(
      body: Column(
        children: [
          if (ent.shouldNudge) _buildTrialNudge(ent),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
          if (ent.showAds) const _AdBanner(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _showFAB ? _buildFAB() : null,
    );
  }

  /// Gentle reminder in the final two weeks of the free trial.
  Widget _buildTrialNudge(EntitlementService ent) {
    final days = ent.daysRemaining;
    return Material(
      color: AppColors.primary.withOpacity(0.18),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UpgradeScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: AppColors.primaryLight),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  days == 1
                      ? 'Last day of your free trial'
                      : '$days days left in your free trial',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const Text('See options',
                  style: TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w600)),
              const Icon(Icons.chevron_right, size: 16, color: AppColors.gold),
            ],
          ),
        ),
      ),
    );
  }

  /// Only show the FAB on Home, Tasks, and Habits screens
  bool get _showFAB => _currentIndex == 0 || _currentIndex == 3;

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
            icon: Icon(Icons.timer_outlined),
            activeIcon: Icon(Icons.timer),
            label: 'Focus',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.view_timeline_outlined),
            activeIcon: Icon(Icons.view_timeline),
            label: 'Planner',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_fire_department_outlined),
            activeIcon: Icon(Icons.local_fire_department),
            label: 'Habit',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Report',
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
                      setState(() => _currentIndex = 3); // Go to Habit tab
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AddOptionCard(
                    icon: Icons.folder,
                    label: 'Project',
                    color: AppColors.success,
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProjectsScreen()),
                      );
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


/// Banner advert shown only to users who chose adverts over the one-time unlock.
class _AdBanner extends StatefulWidget {
  const _AdBanner();

  @override
  State<_AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<_AdBanner> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final ads = context.read<AdsService>();
    await ads.initialize();
    if (!mounted) return;
    final banner = ads.createBanner(
      onLoaded: () {
        if (mounted) setState(() => _loaded = true);
      },
      onFailed: () {
        if (mounted) setState(() => _loaded = false);
      },
    );
    _ad = banner;
    await banner.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_ad == null || !_loaded) return const SizedBox.shrink();
    return Container(
      color: AppColors.surface,
      width: double.infinity,
      height: _ad!.size.height.toDouble(),
      alignment: Alignment.center,
      child: AdWidget(ad: _ad!),
    );
  }
}
