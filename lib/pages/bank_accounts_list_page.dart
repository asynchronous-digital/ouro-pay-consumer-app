import 'package:flutter/material.dart';
import 'package:ouro_pay_consumer_app/models/bank_account.dart';
import 'package:ouro_pay_consumer_app/services/bank_service.dart';
import 'package:ouro_pay_consumer_app/services/auth_service.dart';
import 'package:ouro_pay_consumer_app/theme/app_theme.dart';
import 'package:ouro_pay_consumer_app/pages/add_bank_account_page.dart';

class BankAccountsListPage extends StatefulWidget {
  const BankAccountsListPage({super.key});

  @override
  State<BankAccountsListPage> createState() => _BankAccountsListPageState();
}

class _BankAccountsListPageState extends State<BankAccountsListPage> {
  final BankService _bankService = BankService();
  late Future<List<BankAccount>> _accountsFuture;
  bool _isKycApproved = false;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
    _loadKycStatus();
  }

  Future<void> _loadKycStatus() async {
    try {
      final authService = AuthService();
      final response = await authService.getUserProfile();
      if (mounted) {
        setState(() {
          _isKycApproved =
              response.data?.authorization.kycStatus.isApproved ?? false;
        });
      }
    } catch (e) {
      print('Error loading KYC status: $e');
    }
  }

  void _loadAccounts() {
    setState(() {
      _accountsFuture = _bankService.getBankAccounts();
    });
  }

  Future<void> _deleteAccount(int id) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryGold),
      ),
    );

    try {
      final success = await _bankService.deleteBankAccount(id);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bank account deleted successfully'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        _loadAccounts();
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${e.toString().replaceAll("Exception:", "")}'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  void _showDeleteConfirmation(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Delete Account',
            style: TextStyle(color: AppColors.errorRed)),
        content: const Text(
            'Are you sure you want to delete this bank account?',
            style: TextStyle(color: AppColors.whiteText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.greyText)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount(id);
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Bank Accounts'),
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.whiteText,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<List<BankAccount>>(
        future: _accountsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryGold));
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.errorRed, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading accounts',
                    style: const TextStyle(
                        color: AppColors.whiteText, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error
                        .toString()
                        .replaceAll("Exception:", "")
                        .trim(),
                    style: const TextStyle(color: AppColors.greyText),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadAccounts,
                    child: const Text('Retry'),
                  )
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance,
                      size: 64, color: AppColors.greyText.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text('No bank accounts found',
                      style:
                          TextStyle(color: AppColors.greyText, fontSize: 16)),
                ],
              ),
            );
          }

          final accounts = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _loadAccounts(),
            color: AppColors.primaryGold,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: accounts.length,
              itemBuilder: (context, index) {
                final account = accounts[index];
                return Card(
                  color: AppColors.cardBackground,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: account.isDefault
                        ? const BorderSide(
                            color: AppColors.primaryGold, width: 1)
                        : BorderSide.none,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.account_balance,
                          color: AppColors.primaryGold),
                    ),
                    title: Text(
                      account.bankName,
                      style: const TextStyle(
                          color: AppColors.whiteText,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          account.accountNumber, // Masked
                          style: const TextStyle(
                              color: AppColors.greyText, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${account.accountHolderName} • ${account.currency?.code ?? "USD"}',
                          style: TextStyle(
                              color: AppColors.greyText.withOpacity(0.7),
                              fontSize: 12),
                        ),
                        if (account.isDefault)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGold.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Primary',
                                style: TextStyle(
                                    color: AppColors.primaryGold,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.errorRed),
                      onPressed: () => _showDeleteConfirmation(account.id),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: _isKycApproved
          ? FloatingActionButton.extended(
              onPressed: _handleAddBankAccount,
              backgroundColor: AppColors.primaryGold,
              icon: const Icon(Icons.account_balance,
                  color: AppColors.darkBackground),
              label: const Text(
                'Add Bank',
                style: TextStyle(
                  color: AppColors.darkBackground,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  void _handleAddBankAccount() async {
    // Navigate to add bank account page (KYC already checked before showing button)
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddBankAccountPage()),
    );
    if (result == true) {
      _loadAccounts();
    }
  }
}
