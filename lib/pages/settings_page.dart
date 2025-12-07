import 'package:flutter/material.dart';
import 'package:ouro_pay_consumer_app/theme/app_theme.dart';
import 'package:ouro_pay_consumer_app/services/auth_service.dart';
import 'package:ouro_pay_consumer_app/models/bank_account.dart';
import 'package:ouro_pay_consumer_app/pages/withdraw_funds_page.dart';
import 'package:ouro_pay_consumer_app/pages/withdrawal_history_page.dart';
import 'package:ouro_pay_consumer_app/services/bank_service.dart';
import 'package:ouro_pay_consumer_app/pages/bank_accounts_list_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  BankAccount? _bankAccount;
  final BankService _bankService = BankService();
  bool _isLoadingBank = true;

  @override
  void initState() {
    super.initState();
    _fetchBankAccount();
  }

  Future<void> _fetchBankAccount() async {
    try {
      final accounts = await _bankService.getBankAccounts();
      if (mounted) {
        setState(() {
          if (accounts.isNotEmpty) {
            // Find default or take first
            _bankAccount = accounts.firstWhere((a) => a.isDefault,
                orElse: () => accounts.first);
          } else {
            _bankAccount = null;
          }
          _isLoadingBank = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBank = false;
        });
      }
    }
  }

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
    return Card(
      child: ListTile(
        leading:
            const Icon(Icons.account_balance, color: AppColors.primaryGold),
        title: const Text('Bank Accounts'),
        subtitle: _isLoadingBank
            ? const Text('Loading...',
                style: TextStyle(color: AppColors.greyText, fontSize: 12))
            : Text(
                _bankAccount != null
                    ? '${_bankAccount!.bankName} • ${_bankAccount!.maskedAccountNumber}'
                    : 'Manage linked accounts',
                style: const TextStyle(color: AppColors.greyText),
              ),
        trailing: const Icon(Icons.arrow_forward_ios,
            size: 16, color: AppColors.greyText),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const BankAccountsListPage()),
          );
          _fetchBankAccount();
        },
      ),
    );
  }

  Widget _buildWithdrawTile() {
    final isEnabled = _bankAccount?.isVerified ?? false;

    return Card(
      child: ListTile(
        leading: Icon(Icons.payments_outlined,
            color: isEnabled ? AppColors.primaryGold : AppColors.greyText),
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
            ? const Icon(Icons.arrow_forward_ios,
                size: 16, color: AppColors.greyText)
            : null,
        onTap: isEnabled
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        WithdrawFundsPage(preSelectedBankAccount: _bankAccount),
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
        trailing: const Icon(Icons.arrow_forward_ios,
            size: 16, color: AppColors.greyText),
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
