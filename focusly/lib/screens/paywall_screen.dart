import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/iap_service.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final iap = context.watch<IAPService>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.task_alt, size: 80, color: Color(0xFF6C63FF)),
              const SizedBox(height: 24),
              const Text('Focusly', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Your Daily Planner', style: TextStyle(fontSize: 18, color: Colors.grey)),
              const SizedBox(height: 40),
              const Text('Tasks · Habits · Planner', style: TextStyle(fontSize: 16), textAlign: TextAlign.center),
              const SizedBox(height: 48),
              if (iap.error != null) ...[
                Text(iap.error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: iap.isLoading ? null : () => iap.purchase(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: iap.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Unlock for \$2.99', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: iap.isLoading ? null : () => iap.restore(),
                child: const Text('Restore Purchase'),
              ),
              const SizedBox(height: 8),
              const Text('One-time payment · No subscription', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
