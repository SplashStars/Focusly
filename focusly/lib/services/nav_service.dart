// ─────────────────────────────────────────────────────────────────────────────
// Nav Service — which of the five main tabs is showing.
//
// Lifted out of MainScreen's local state so the Home header's dropdown menu
// can jump between tabs too, rather than only the bottom bar being able to.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

/// The five destinations, in the order MainScreen stacks them.
enum AppTab {
  home(0, 'Home', Icons.home_rounded),
  focus(1, 'Focus', Icons.timer_rounded),
  planner(2, 'Planner', Icons.view_timeline_rounded),
  habits(3, 'Habits', Icons.local_fire_department_rounded),
  reports(4, 'Report', Icons.insights_rounded);

  const AppTab(this.index, this.label, this.icon);
  final int index;
  final String label;
  final IconData icon;
}

class NavService extends ChangeNotifier {
  int _index = 0;

  int get index => _index;
  AppTab get tab => AppTab.values[_index];

  void go(int index) {
    if (index == _index) return;
    _index = index;
    notifyListeners();
  }

  void goTo(AppTab tab) => go(tab.index);
}
