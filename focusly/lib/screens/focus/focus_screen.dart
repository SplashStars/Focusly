// ─────────────────────────────────────────────────────────────────────────────
// Focus Screen — Pomodoro / Deep Work timer
// 25/5 Pomodoro technique, Deep Work mode, task linking, session tracking.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/task_provider.dart';
import '../../models/task_model.dart';
import '../../services/focus_service.dart';
import '../../services/notification_service.dart';
import '../../services/dnd_service.dart';

/// The three timer modes available on this screen.
enum FocusMode {
  pomodoro('Pomodoro', 25, 'Classic 25 minute sprint'),
  deepWork('Deep Work', 50, 'Longer 50 minute deep session'),
  shortBreak('Break', 5, 'Short 5 minute rest');

  final String label;
  final int minutes;
  final String description;
  const FocusMode(this.label, this.minutes, this.description);
}

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  Timer? _ticker;
  FocusMode _mode = FocusMode.pomodoro;

  /// The session length actually in use. Presets set this; the wheel overrides it.
  int _minutes = FocusMode.pomodoro.minutes;
  late int _remaining = _minutes * 60;
  bool _running = false;
  bool _strictMode = false;
  bool _fullScreen = false;
  TaskModel? _linkedTask;

  /// Selectable session lengths: 5 to 120 minutes in 5 minute steps.
  static final List<int> _options = List<int>.generate(24, (i) => (i + 1) * 5);

  late final FixedExtentScrollController _wheel =
      FixedExtentScrollController(initialItem: _options.indexOf(_minutes));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FocusService>().load();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _wheel.dispose();
    // Never leave the phone silenced or the status bar hidden behind us.
    if (_strictMode) DndService.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  int get _totalSeconds => _minutes * 60;
  double get _progress =>
      _totalSeconds == 0 ? 0 : (_totalSeconds - _remaining) / _totalSeconds;

  void _selectMode(FocusMode mode) {
    _ticker?.cancel();
    setState(() {
      _mode = mode;
      _minutes = mode.minutes;
      _remaining = _minutes * 60;
      _running = false;
    });
    _wheel.animateToItem(
      _options.indexOf(_minutes),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  /// Called when the wheel settles on a new value.
  void _selectMinutes(int minutes) {
    if (_running) return;
    setState(() {
      _minutes = minutes;
      _remaining = minutes * 60;
      // Keep the preset chip highlighted only while it still matches.
      _mode = FocusMode.values.firstWhere(
        (m) => m.minutes == minutes,
        orElse: () => _mode,
      );
    });
  }

  void _toggle() {
    if (_running) {
      _ticker?.cancel();
      setState(() => _running = false);
      return;
    }

    setState(() => _running = true);
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        t.cancel();
        _complete();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  void _reset() {
    _ticker?.cancel();
    setState(() {
      _remaining = _totalSeconds;
      _running = false;
    });
  }

  Future<void> _complete() async {
    setState(() {
      _remaining = 0;
      _running = false;
    });

    // Only real focus sessions count toward stats — breaks do not.
    if (_mode != FocusMode.shortBreak) {
      await context.read<FocusService>().recordSession(_minutes);
    }

    await NotificationService.instance.showFocusComplete(
      title: _mode == FocusMode.shortBreak ? 'Break over' : 'Session complete',
      body: _mode == FocusMode.shortBreak
          ? 'Ready for another focus session?'
          : 'Great work — ${_minutes} minutes focused.',
    );

    // Give the phone back to the user before celebrating.
    if (_strictMode) {
      await DndService.disable();
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (!mounted) return;
    setState(() {
      _strictMode = false;
      _fullScreen = false;
    });
    _showCompletionSheet();
  }

  void _showCompletionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _mode == FocusMode.shortBreak
                  ? Icons.self_improvement
                  : Icons.celebration,
              color: AppColors.gold,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              _mode == FocusMode.shortBreak ? 'Break finished' : 'Session complete',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _linkedTask != null
                  ? 'Focused on "${_linkedTask!.title}"'
                  : '${_minutes} minutes of focused work.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (_linkedTask != null && !_linkedTask!.isCompleted)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        context.read<TaskProvider>().completeTask(_linkedTask!.id);
                        setState(() => _linkedTask = null);
                        Navigator.pop(ctx);
                        _reset();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.success,
                        side: const BorderSide(color: AppColors.success),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Mark task done'),
                    ),
                  ),
                if (_linkedTask != null && !_linkedTask!.isCompleted)
                  const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _selectMode(_mode == FocusMode.shortBreak
                          ? FocusMode.pomodoro
                          : FocusMode.shortBreak);
                    },
                    child: Text(_mode == FocusMode.shortBreak
                        ? 'Start focusing'
                        : 'Take a break'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String get _timeLabel {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_fullScreen) return _buildFullScreen();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Focus Mode',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _running
                    ? 'Session in progress — stay with it'
                    : 'Spin the wheel to set your session length',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 24),
              _buildModeSelector(),
              const SizedBox(height: 20),
              Center(child: _running ? _buildDial() : _buildWheel()),
              const SizedBox(height: 20),
              _buildControls(),
              const SizedBox(height: 16),
              _buildSessionOptions(),
              const SizedBox(height: 24),
              _buildTaskLink(),
              const SizedBox(height: 24),
              _buildTodayStats(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Row(
      children: FocusMode.values.map((m) {
        final selected = m == _mode;
        return Expanded(
          child: GestureDetector(
            onTap: () => _selectMode(m),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withOpacity(0.25)
                    : AppColors.surface,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.surfaceHighlight,
                  width: selected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    m.label,
                    style: TextStyle(
                      color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${m.minutes} min',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDial() {
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 240,
            height: 240,
            child: CircularProgressIndicator(
              value: _progress,
              strokeWidth: 12,
              backgroundColor: AppColors.surfaceHighlight,
              valueColor: AlwaysStoppedAnimation(
                _mode == FocusMode.shortBreak ? AppColors.success : AppColors.gold,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _timeLabel,
                style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w300,
                  color: AppColors.textPrimary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _running ? 'Stay with it' : 'Ready when you are',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _toggle,
            icon: Icon(_running ? Icons.pause : Icons.play_arrow),
            label: Text(_running ? 'Pause' : 'Start'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _running ? AppColors.surfaceElevated : AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Reset'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.surfaceHighlight),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  // Timer wheel ---------------------------------------------------------------
  // Shown while the timer is stopped. Scrolling it picks the session length,
  // so the user is never limited to the three presets.

  Widget _buildWheel() {
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Static ring so the wheel reads as a dial, not a plain list.
          SizedBox(
            width: 240,
            height: 240,
            child: CircularProgressIndicator(
              value: _minutes / 120,
              strokeWidth: 12,
              backgroundColor: AppColors.surfaceHighlight,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          // Selection band behind the centre item.
          Container(
            width: 150,
            height: 62,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.35)),
            ),
          ),
          SizedBox(
            width: 170,
            height: 200,
            child: ListWheelScrollView.useDelegate(
              controller: _wheel,
              itemExtent: 62,
              perspective: 0.004,
              diameterRatio: 1.6,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (i) => _selectMinutes(_options[i]),
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: _options.length,
                builder: (context, i) {
                  final value = _options[i];
                  final selected = value == _minutes;
                  return Center(
                    child: Text(
                      '$value',
                      style: TextStyle(
                        fontSize: selected ? 46 : 30,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w300,
                        color: selected
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const Positioned(
            bottom: 46,
            child: Text(
              'minutes',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Strict Mode and Full Screen ----------------------------------------------

  Widget _buildSessionOptions() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Column(
        children: [
          SwitchListTile(
            value: _strictMode,
            onChanged: (v) => _toggleStrict(v),
            activeColor: AppColors.primary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: const Text(
              'Strict Mode',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: const Text(
              'Silence calls, messages and reminders until the session ends',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
            secondary: const Icon(
              Icons.do_not_disturb_on_outlined,
              color: AppColors.primaryLight,
              size: 20,
            ),
          ),
          const Divider(height: 1, color: AppColors.surfaceHighlight),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: const Icon(
              Icons.fullscreen,
              color: AppColors.primaryLight,
              size: 20,
            ),
            title: const Text(
              'Full Screen',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: const Text(
              'Just the countdown, nothing else on screen',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
              size: 20,
            ),
            onTap: _enterFullScreen,
          ),
        ],
      ),
    );
  }

  /// Strict Mode needs Do Not Disturb access. We only ever ask for it here -
  /// at the moment the user switches the feature on - never at launch.
  Future<void> _toggleStrict(bool value) async {
    if (!value) {
      await DndService.disable();
      if (mounted) setState(() => _strictMode = false);
      return;
    }

    final granted = await DndService.hasAccess();
    if (!granted) {
      if (!mounted) return;
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Allow Do Not Disturb?',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 17),
          ),
          content: const Text(
            'Strict Mode silences calls, messages and reminders while you '
            'focus. Android asks you to grant Do Not Disturb access once. '
            'Focusly restores your normal settings the moment the session '
            'ends.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Not now'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Open settings'),
            ),
          ],
        ),
      );
      if (go == true) {
        await DndService.openAccessSettings();
      }
      return;
    }

    final ok = await DndService.enable();
    if (!mounted) return;
    setState(() => _strictMode = ok);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not turn on Do Not Disturb')),
      );
    }
  }

  void _enterFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    setState(() => _fullScreen = true);
  }

  void _exitFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    setState(() => _fullScreen = false);
  }

  Widget _buildFullScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _exitFullScreen,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_linkedTask != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _linkedTask!.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Text(
                _timeLabel,
                style: const TextStyle(
                  fontSize: 96,
                  fontWeight: FontWeight.w200,
                  color: Colors.white,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 16),
              if (_strictMode)
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.do_not_disturb_on,
                        size: 14, color: AppColors.gold),
                    SizedBox(width: 6),
                    Text(
                      'Strict Mode on',
                      style: TextStyle(color: AppColors.gold, fontSize: 12),
                    ),
                  ],
                ),
              const SizedBox(height: 40),
              TextButton.icon(
                onPressed: _toggle,
                icon: Icon(
                  _running ? Icons.pause : Icons.play_arrow,
                  color: Colors.white70,
                ),
                label: Text(
                  _running ? 'Pause' : 'Start',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap anywhere to leave full screen',
                style: TextStyle(color: Colors.white24, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskLink() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Row(
        children: [
          const Icon(Icons.link, color: AppColors.primaryLight, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Working on',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  _linkedTask?.title ?? 'No task linked',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _linkedTask == null
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _pickTask,
            child: Text(_linkedTask == null ? 'Choose' : 'Change'),
          ),
        ],
      ),
    );
  }

  void _pickTask() {
    final tasks = context
        .read<TaskProvider>()
        .tasks
        .where((t) => !t.isCompleted)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: const BoxConstraints(maxHeight: 420),
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Link a task to this session',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (tasks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No open tasks. Add a task first and it will show up here.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: tasks.length,
                  itemBuilder: (_, i) {
                    final t = tasks[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.circle, size: 10, color: t.priority.color),
                      title: Text(
                        t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      onTap: () {
                        setState(() => _linkedTask = t);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            if (_linkedTask != null)
              TextButton(
                onPressed: () {
                  setState(() => _linkedTask = null);
                  Navigator.pop(ctx);
                },
                child: const Text('Clear link'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayStats() {
    return Consumer<FocusService>(
      builder: (context, focus, _) {
        final hours = focus.minutesToday ~/ 60;
        final mins = focus.minutesToday % 60;
        return Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.timer_outlined,
                label: 'Sessions today',
                value: '${focus.sessionsToday}',
                color: AppColors.primaryLight,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                icon: Icons.hourglass_bottom,
                label: 'Focused today',
                value: hours > 0 ? '${hours}h ${mins}m' : '${mins}m',
                color: AppColors.gold,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
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
