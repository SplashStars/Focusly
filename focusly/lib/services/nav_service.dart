// ─────────────────────────────────────────────────────────────────────────────
// Nav Service — which of the five main tabs is showing.
//
// Lifted out of MainScreen's local state so the Home header's dropdown menu
// can jump between tabs too, rather than only the bottom bar being able to.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'locale_controller.dart';

/// The five destinations, in the order MainScreen stacks them.
///
/// No `index` field here: every Dart enum already has a built-in `index` equal
/// to its declaration order, which is exactly the tab order, and declaring our
/// own would collide with it.
enum AppTab {
  home(Icons.home_rounded),
  focus(Icons.timer_rounded),
  planner(Icons.view_timeline_rounded),
  habits(Icons.local_fire_department_rounded),
  reports(Icons.insights_rounded);

  const AppTab(this.icon);
  final IconData icon;

  /// Resolved at call time, not stored: enum arguments must be compile-time
  /// constants, and a translated label is not one.
  String get label {
    switch (this) {
      case AppTab.home:
        return L10n.t.home;
      case AppTab.focus:
        return L10n.t.focus;
      case AppTab.planner:
        return L10n.t.planner;
      case AppTab.habits:
        return L10n.t.habits;
      case AppTab.reports:
        return L10n.t.report;
    }
  }
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
