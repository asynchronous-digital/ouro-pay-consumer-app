import 'package:flutter/material.dart';
import 'package:ouro_pay_consumer_app/theme/app_theme.dart';
import 'package:ouro_pay_consumer_app/models/user_profile.dart'; // For UserProfile and AppealStatus

import 'package:ouro_pay_consumer_app/services/auth_service.dart';

class SuspendedPage extends StatelessWidget {
  const SuspendedPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get arguments properly
    final profile = ModalRoute.of(context)?.settings.arguments as UserProfile?;
    final canAppeal = profile?.appealStatus?.canAppeal ?? false;

    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.block_flipped,
                  size: 80,
                  color: AppColors.errorRed,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Account Suspended',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.whiteText,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your account has been suspended. You can only view your profile and wallet information.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.greyText,
                  ),
                ),
                const SizedBox(height: 32),
                if (canAppeal) ...[
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/submit-appeal');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Submit Appeal'),
                  ),
                ] else if (profile?.appealStatus?.hasPendingAppeal == true) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primaryGold),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.access_time, color: AppColors.primaryGold),
                        SizedBox(width: 8),
                        Text(
                          'Appeal Under Review',
                          style: TextStyle(
                            color: AppColors.primaryGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Not able to appeal and no pending appeal (e.g. permanently suspended or just rejected)
                  const Text(
                    'Appeal Status: Cannot Appeal',
                    style: TextStyle(
                      color: AppColors.errorRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/appeals');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.whiteText,
                    side: const BorderSide(color: AppColors.greyText),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Appeal History'),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    // Navigate to Dashboard (which will re-check suspension if needed)
                    // We remove until dashboard to clear stack, but here we can just pushNamedAndRemoveUntil
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/dashboard',
                      (route) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryGold,
                    side: const BorderSide(color: AppColors.primaryGold),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Back to Dashboard'),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () async {
                    // Logout logic
                    await AuthService().logout();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/welcome',
                        (route) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout, color: AppColors.errorRed),
                  label: const Text(
                    'Logout',
                    style: TextStyle(color: AppColors.errorRed),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
