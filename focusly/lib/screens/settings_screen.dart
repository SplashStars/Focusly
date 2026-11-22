// ─────────────────────────────────────────────────────────────────────────────
// Settings — daily reminder controls and a direct feedback channel.
//
// The feedback link exists because the Play reviews we have are all five-star
// generic praise with no bug reports or feature requests in them. A mailto
// link gets us specific complaints from people who actually use the app.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import '../services/daily_reminder_service.dart';
import '../services/notification_service.dart';

/// Shown in the feedback email so a report arrives with the build attached.
const String kAppVersionLabel = '1.1.4 (14)';
const String kFeedbackEmail = 'esellersstores@gmail.com';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Settings',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: const [
          _SectionLabel('Reminders'),
          _DailyReminderCard(),
          SizedBox(height: 24),
          _SectionLabel('Help us improve'),
          _FeedbackCard(),
          SizedBox(height: 24),
          _SectionLabel('About'),
          _AboutCard(),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

// ── Daily reminder ───────────────────────────────────────────────────────────

class _DailyReminderCard extends StatelessWidget {
  const _DailyReminderCard();

  @override
  Widget build(BuildContext context) {
    final reminder = context.watch<DailyReminderService>();

    return _Card(
      child: Column(
        children: [
          SwitchListTile(
            value: reminder.enabled,
            // activeColor is deprecated on newer Flutter; thumbColor is the
            // current API and compiles on both.
            thumbColor: WidgetStateProperty.resolveWith(
              (states) =>
                  states.contains(WidgetState.selected) ? AppColors.gold : null,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: const Text('Daily reminder',
                style: TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            subtitle: const Text(
              'One nudge a day to plan or review',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            secondary: const Icon(Icons.notifications_active_outlined,
                color: AppColors.primaryLight),
            onChanged: (value) => _onToggle(context, reminder, value),
          ),
          const Divider(height: 1, color: AppColors.surfaceElevated),
          Opacity(
            // Dimmed rather than removed, so the chosen time stays visible
            // and the row does not jump around when the switch is flipped.
            opacity: reminder.enabled ? 1 : 0.45,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: const Icon(Icons.schedule, color: AppColors.primaryLight),
              title: const Text('Reminder time',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600)),
              trailing: Text(
                reminder.timeLabel,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: reminder.enabled ? () => _pickTime(context, reminder) : null,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onToggle(
      BuildContext context, DailyReminderService reminder, bool value) async {
    if (value) {
      // Android 13+ will not deliver anything until the user grants this, and
      // a silently dead reminder is worse than no reminder at all.
      final granted = await NotificationService.instance.requestPermissions();
      if (!granted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            content: Text(
              'Notifications are turned off for Focusly. Enable them in your '
              'phone settings to get the daily reminder.',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ),
        );
        return;
      }
    }
    await reminder.setEnabled(value);
  }

  Future<void> _pickTime(
      BuildContext context, DailyReminderService reminder) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: reminder.time,
      builder: (context, child) => Theme(
        data: AppTheme.darkTheme.copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) await reminder.setTime(picked);
  }
}

// ── Feedback ─────────────────────────────────────────────────────────────────

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: const Icon(Icons.mail_outline, color: AppColors.gold),
            title: const Text('Send feedback',
                style: TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            subtitle: const Text(
              'Report a bug or ask for a feature',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
            onTap: () => _sendFeedback(context),
          ),
        ],
      ),
    );
  }

  Future<void> _sendFeedback(BuildContext context) async {
    // Build the mailto URI with Uri's own encoder — hand-rolled escaping breaks
    // as soon as a subject contains a space or an ampersand.
    final uri = Uri(
      scheme: 'mailto',
      path: kFeedbackEmail,
      query: Uri(queryParameters: {
        'subject': 'Focusly feedback ($kAppVersionLabel)',
        'body': '\n\n\n'
            '----------------------------\n'
            'App version: $kAppVersionLabel\n'
            'Device OS: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}\n'
            '(Please keep these lines — they help us reproduce the problem.)\n',
      }).query,
    );

    final launched =
        await launchUrl(uri, mode: LaunchMode.externalApplication).catchError((_) => false);

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          content: Text(
            'No email app found. Write to $kFeedbackEmail',
            style: TextStyle(color: AppColors.textPrimary),
          ),
        ),
      );
    }
  }
}

// ── About ────────────────────────────────────────────────────────────────────

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: const Icon(Icons.info_outline, color: AppColors.primaryLight),
        title: const Text('Focusly',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        subtitle: const Text('Version $kAppVersionLabel',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ),
    );
  }
}
