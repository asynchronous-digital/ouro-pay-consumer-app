import 'package:flutter/material.dart';
import 'package:ouro_pay_consumer_app/theme/app_theme.dart';
import 'package:ouro_pay_consumer_app/models/withdrawal.dart';

class WithdrawalHistoryPage extends StatefulWidget {
  const WithdrawalHistoryPage({super.key});

  @override
  State<WithdrawalHistoryPage> createState() => _WithdrawalHistoryPageState();
}

class _WithdrawalHistoryPageState extends State<WithdrawalHistoryPage> {
  List<Withdrawal> _withdrawals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWithdrawals();
  }

  Future<void> _loadWithdrawals() async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      setState(() {
        _withdrawals = Withdrawal.dummyList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Withdrawal History'),
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGold))
          : _withdrawals.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _withdrawals.length,
                  itemBuilder: (context, index) {
                    return _buildWithdrawalCard(_withdrawals[index]);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: AppColors.greyText.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'No withdrawals yet',
            style: TextStyle(color: AppColors.greyText, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalCard(Withdrawal withdrawal) {
    Color statusColor;
    IconData statusIcon;

    switch (withdrawal.status.toLowerCase()) {
      case 'completed':
        statusColor = AppColors.successGreen;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = AppColors.warningOrange;
        statusIcon = Icons.pending;
        break;
      case 'failed':
        statusColor = AppColors.errorRed;
        statusIcon = Icons.error;
        break;
      default:
        statusColor = AppColors.greyText;
        statusIcon = Icons.info;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  withdrawal.formattedAmount,
                  style: const TextStyle(
                    color: AppColors.whiteText,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        withdrawal.statusDisplay,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.account_balance, size: 16, color: AppColors.greyText),
                const SizedBox(width: 8),
                Text(
                  '${withdrawal.bankName} (${withdrawal.maskedAccountNumber})',
                  style: const TextStyle(color: AppColors.greyText),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _formatDate(withdrawal.createdAt),
              style: const TextStyle(color: AppColors.greyText, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
