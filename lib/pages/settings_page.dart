import 'package:flutter/material.dart';
import 'package:ouro_pay_consumer_app/theme/app_theme.dart';
import 'package:ouro_pay_consumer_app/services/auth_service.dart';
import 'package:ouro_pay_consumer_app/models/bank_account.dart';
import 'package:ouro_pay_consumer_app/pages/add_bank_account_page.dart';
import 'package:ouro_pay_consumer_app/pages/withdraw_funds_page.dart';
import 'package:ouro_pay_consumer_app/pages/withdrawal_history_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  BankAccount? _bankAccount;

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
          const Text(
            'Bank & Withdrawal',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.whiteText,
            ),
          ),
          const SizedBox(height: 12),
          _buildBankAccountTile(),
          if (_bankAccount != null) ...[
            const SizedBox(height: 8),
            _buildWithdrawTile(),
          ],
          const SizedBox(height: 8),
          _buildWithdrawHistoryTile(),
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

  Widget _buildBankAccountTile() {
    if (_bankAccount == null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.account_balance, color: AppColors.primaryGold),
          title: const Text('Add Bank Account'),
          subtitle: const Text('Link your bank to withdraw funds'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.greyText),
          onTap: () async {
            final result = await Navigator.push<BankAccount>(
              context,
              MaterialPageRoute(builder: (context) => const AddBankAccountPage()),
            );
            if (result != null) {
              setState(() {
                _bankAccount = result;
              });
            }
          },
        ),
      );
    }

    return Card(
      child: ListTile(
        leading: const Icon(Icons.account_balance, color: AppColors.primaryGold),
        title: Text(_bankAccount!.bankName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_bankAccount!.maskedAccountNumber),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _bankAccount!.isVerified 
                    ? AppColors.successGreen.withOpacity(0.2) 
                    : AppColors.warningOrange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _bankAccount!.status.toUpperCase(),
                style: TextStyle(
                  color: _bankAccount!.isVerified 
                      ? AppColors.successGreen 
                      : AppColors.warningOrange,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.errorRed),
          onPressed: () {
            // Confirm delete
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: AppColors.cardBackground,
                title: const Text('Remove Bank Account?', style: TextStyle(color: AppColors.whiteText)),
                content: const Text('Are you sure you want to remove this bank account?', style: TextStyle(color: AppColors.greyText)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.greyText)),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _bankAccount = null;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Remove', style: TextStyle(color: AppColors.errorRed)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWithdrawTile() {
    final isEnabled = _bankAccount?.isVerified ?? false;
    
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.payments_outlined, 
          color: isEnabled ? AppColors.primaryGold : AppColors.greyText
        ),
        title: Text(
          'Withdraw Funds',
          style: TextStyle(
            color: isEnabled ? AppColors.whiteText : AppColors.greyText,
          ),
        ),
        subtitle: isEnabled 
            ? const Text('Transfer funds to your bank')
            : const Text('Verify bank account to withdraw'),
        trailing: isEnabled 
            ? const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.greyText)
            : null,
        onTap: isEnabled 
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WithdrawFundsPage(bankAccount: _bankAccount!),
                  ),
                );
              }
            : null,
      ),
    );
  }

  Widget _buildWithdrawHistoryTile() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.history, color: AppColors.primaryGold),
        title: const Text('Withdrawal History'),
        subtitle: const Text('View past withdrawals'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.greyText),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WithdrawalHistoryPage(),
            ),
          );
        },
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
