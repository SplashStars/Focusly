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
import '../services/theme_controller.dart';
import '../services/entitlement_service.dart';
import '../services/iap_service.dart';
import 'upgrade/upgrade_screen.dart';

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
        title: Text('Settings',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: const [
          _SectionLabel('Your plan'),
          _PlanCard(),
          SizedBox(height: 24),
          _SectionLabel('Appearance'),
          _ThemeCard(),
          SizedBox(height: 24),
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
        style: TextStyle(
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
            title: Text('Daily reminder',
                style: TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            subtitle: Text(
              'One nudge a day to plan or review',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            secondary: Icon(Icons.notifications_active_outlined,
                color: AppColors.primaryLight),
            onChanged: (value) => _onToggle(context, reminder, value),
          ),
          Divider(height: 1, color: AppColors.surfaceElevated),
          Opacity(
            // Dimmed rather than removed, so the chosen time stays visible
            // and the row does not jump around when the switch is flipped.
            opacity: reminder.enabled ? 1 : 0.45,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: Icon(Icons.schedule, color: AppColors.primaryLight),
              title: Text('Reminder time',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600)),
              trailing: Text(
                reminder.timeLabel,
                style: TextStyle(
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
          SnackBar(
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
          colorScheme: ColorScheme.dark(
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
            leading: Icon(Icons.mail_outline, color: AppColors.gold),
            title: Text('Send feedback',
                style: TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            subtitle: Text(
              'Report a bug or ask for a feature',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            trailing: Icon(Icons.chevron_right, color: AppColors.textMuted),
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
        SnackBar(
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

// ── Plan / upgrade ─────────────────────────────────────────────

/// Choosing "free with adverts" used to be permanent: the upgrade screen only
/// ever appeared once, at the end of the trial. This makes paying available at
/// any time afterwards.
class _PlanCard extends StatelessWidget {
  const _PlanCard();

  @override
  Widget build(BuildContext context) {
    final ent = context.watch<EntitlementService>();
    final iap = context.watch<IAPService>();

    if (ent.isPremium) {
      return _Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: Icon(Icons.verified, color: AppColors.gold),
          title: Text('Focusly unlocked',
              style: TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          subtitle: Text('Thank you — no adverts, everything included.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ),
      );
    }

    final subtitle = ent.isTrialActive
        ? '${ent.daysRemaining} days left in your free trial'
        : 'Currently free, supported by adverts';

    return _Card(
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: Icon(Icons.block, color: AppColors.gold),
            title: Text('Remove adverts — ${iap.priceLabel}',
                style: TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            subtitle: Text(subtitle,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            trailing: Icon(Icons.chevron_right, color: AppColors.textMuted),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UpgradeScreen()),
            ),
          ),
          Divider(height: 1, color: AppColors.surfaceElevated),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: Icon(Icons.restore, color: AppColors.primaryLight),
            title: Text('Restore purchase',
                style: TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            subtitle: Text('Already paid on another device?',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            onTap: () async {
              await context.read<IAPService>().restore();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.surfaceElevated,
                    content: Text(
                      'Checking Google Play for a previous purchase\u2026',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

// ── Appearance ───────────────────────────────────────────────────

class _ThemeCard extends StatelessWidget {
  const _ThemeCard();

  @override
  Widget build(BuildContext context) {
    final themes = context.watch<ThemeController>();

    return _Card(
      child: Column(
        children: [
          for (final mode in AppThemeMode.values)
            RadioListTile<AppThemeMode>(
              value: mode,
              groupValue: themes.mode,
              // fillColor rather than the deprecated activeColor.
              fillColor: WidgetStatePropertyAll(AppColors.gold),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Text(mode.label,
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600)),
              onChanged: (value) {
                if (value != null) {
                  context.read<ThemeController>().setMode(value);
                }
              },
            ),
        ],
      ),
    );
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
        leading: Icon(Icons.info_outline, color: AppColors.primaryLight),
        title: Text('Focusly',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        subtitle: Text('Version $kAppVersionLabel',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ),
    );
  }
}
