// ─────────────────────────────────────────────────────────────────────────────
// Upgrade Screen — shown once the 90-day free trial ends.
//
// The user picks ONE of two ways to carry on. Both keep every feature:
//   • Pay $2.99 once  — no adverts, forever
//   • Continue free   — with adverts
//
// This screen is never shown during the trial, so a first-time user (and a
// Play reviewer) always reaches the full app immediately.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/entitlement_service.dart';
import '../../services/iap_service.dart';

class UpgradeScreen extends StatelessWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final iap = context.watch<IAPService>();
    final busy = iap.uiState == PurchaseUiState.loading ||
        iap.uiState == PurchaseUiState.pending;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.workspace_premium,
                      color: Colors.white, size: 38),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Your 3 months are up',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Thanks for using Focusly. Choose how you would like to carry '
                'on — both options keep every feature and all your data.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),

              // ── Option 1: pay once ──────────────────────────────────────
              _OptionCard(
                highlighted: true,
                badge: 'BEST VALUE',
                icon: Icons.workspace_premium,
                iconColor: AppColors.gold,
                title: 'Unlock Focusly',
                price: iap.priceLabel,
                priceNote: 'one-time payment',
                bullets: const [
                  'No adverts, ever',
                  'Every feature stays unlocked',
                  'Pay once — not a subscription',
                  'Restores free on a new phone',
                ],
                action: ElevatedButton(
                  onPressed: busy ? null : () => context.read<IAPService>().buy(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text('Unlock for ${iap.priceLabel}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 16),

              // ── Option 2: keep free, with adverts ───────────────────────
              _OptionCard(
                highlighted: false,
                icon: Icons.campaign_outlined,
                iconColor: AppColors.primaryLight,
                title: 'Continue free',
                price: 'Free',
                priceNote: 'supported by adverts',
                bullets: const [
                  'Every feature stays unlocked',
                  'A small banner advert is shown',
                  'Nothing to pay',
                  'You can unlock later at any time',
                ],
                action: OutlinedButton(
                  onPressed: busy
                      ? null
                      : () => context.read<EntitlementService>().acceptAds(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.surfaceHighlight),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Continue with adverts',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),

              if (iap.error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          iap.error!,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: busy ? null : () => context.read<IAPService>().restore(),
                  child: const Text('Already paid? Restore purchase',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Your tasks, habits and history stay on this device either way.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final bool highlighted;
  final String? badge;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String price;
  final String priceNote;
  final List<String> bullets;
  final Widget action;

  const _OptionCard({
    required this.highlighted,
    this.badge,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.price,
    required this.priceNote,
    required this.bullets,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlighted ? AppColors.gold : AppColors.surfaceHighlight,
          width: highlighted ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                price,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                priceNote,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...bullets.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check, size: 15, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      b,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(width: double.infinity, child: action),
        ],
      ),
    );
  }
}
