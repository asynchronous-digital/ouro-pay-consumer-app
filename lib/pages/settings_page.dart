import 'package:flutter/material.dart';
import 'package:ouro_pay_consumer_app/theme/app_theme.dart';
import 'package:ouro_pay_consumer_app/services/auth_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'App Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.whiteText,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.palette, color: AppColors.primaryGold),
              title: const Text('Theme'),
              subtitle: const Text('Dark / Light (coming soon)'),
              onTap: () {},
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock, color: AppColors.primaryGold),
              title: const Text('Security'),
              subtitle: const Text('Pin, Biometrics (coming soon)'),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.greyText),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppColors.errorRed),
              title: const Text(
                'Logout',
                style: TextStyle(color: AppColors.errorRed),
              ),
              subtitle: const Text('Sign out of your account'),
              onTap: () => _handleLogout(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Logout',
          style: TextStyle(color: AppColors.whiteText),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: AppColors.greyText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.greyText),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Logout',
              style: TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryGold,
          ),
        ),
      );

      try {
        final authService = AuthService();
        await authService.logout();

        if (context.mounted) {
          Navigator.pop(context); // Close loading dialog

          // Navigate to welcome page and clear navigation stack
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/welcome',
            (route) => false,
          );

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logged out successfully'),
              backgroundColor: AppColors.primaryGold,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // Close loading dialog
          
          // Still navigate to welcome even if there's an error
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/welcome',
            (route) => false,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout completed: ${e.toString()}'),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      }
    }
  }
}
