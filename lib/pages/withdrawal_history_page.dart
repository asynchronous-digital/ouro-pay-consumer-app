import 'package:flutter/material.dart';
import 'package:ouro_pay_consumer_app/theme/app_theme.dart';
import 'package:ouro_pay_consumer_app/models/withdrawal.dart';
import 'package:ouro_pay_consumer_app/services/withdrawal_service.dart';
import 'package:ouro_pay_consumer_app/pages/withdrawal_details_page.dart';

class WithdrawalHistoryPage extends StatefulWidget {
  const WithdrawalHistoryPage({super.key});

  @override
  State<WithdrawalHistoryPage> createState() => _WithdrawalHistoryPageState();
}

class _WithdrawalHistoryPageState extends State<WithdrawalHistoryPage> {
  List<Withdrawal> _withdrawals = [];
  bool _isLoading = true;
  final _withdrawalService = WithdrawalService();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWithdrawals();
  }

  Future<void> _loadWithdrawals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _withdrawalService.getWithdrawals();
      final List<dynamic> list = data['data'];
      if (mounted) {
        setState(() {
          _withdrawals = list.map((json) => Withdrawal.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll("Exception:", "");
        });
      }
    }
  }

  Future<void> _cancelWithdrawal(int id) async {
    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Cancel Withdrawal',
            style: TextStyle(color: AppColors.whiteText)),
        content: const Text(
            'Are you sure you want to cancel this withdrawal request?',
            style: TextStyle(color: AppColors.greyText)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No',
                  style: TextStyle(color: AppColors.greyText))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes',
                  style: TextStyle(color: AppColors.errorRed))),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _withdrawalService.cancelWithdrawal(id);
        await _loadWithdrawals();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Withdrawal cancelled successfully."),
              backgroundColor: AppColors.successGreen));
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
                  Text('Error: ${e.toString().replaceAll("Exception:", "")}'),
              backgroundColor: AppColors.errorRed));
        }
      }
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
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: _loadWithdrawals)
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGold))
          : _errorMessage != null
              ? Center(
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: AppColors.errorRed)))
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
          Icon(Icons.history,
              size: 64, color: AppColors.greyText.withOpacity(0.5)),
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
      case 'processed':
      case 'completed':
        statusColor = AppColors.successGreen;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = AppColors.warningOrange;
        statusIcon = Icons.pending;
        break;
      case 'rejected':
      case 'failed':
        statusColor = AppColors.errorRed;
        statusIcon = Icons.error;
        break;
      case 'cancelled':
        statusColor = AppColors.greyText;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = AppColors.greyText;
        statusIcon = Icons.info;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                WithdrawalDetailsPage(withdrawalId: withdrawal.id),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
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
                        const Icon(Icons.account_balance,
                            size: 16, color: AppColors.greyText),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${withdrawal.bankName} (${withdrawal.maskedAccountNumber})',
                            style: const TextStyle(color: AppColors.greyText),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDate(withdrawal.createdAt),
                      style: const TextStyle(
                          color: AppColors.greyText, fontSize: 12),
                    ),
                    if (withdrawal.status.toLowerCase() == 'pending')
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => _cancelWithdrawal(withdrawal.id),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.errorRed),
                              foregroundColor: AppColors.errorRed,
                            ),
                            child: const Text("Cancel Withdrawal"),
                          ),
                        ),
                      ),
                    if (withdrawal.notes != null &&
                        withdrawal.notes!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text("Notes: ${withdrawal.notes}",
                            style: const TextStyle(
                                color: AppColors.greyText,
                                fontSize: 12,
                                fontStyle: FontStyle.italic)),
                      ),
                    if (withdrawal.adminNote != null &&
                        withdrawal.adminNote!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text("Admin Note: ${withdrawal.adminNote}",
                            style: const TextStyle(
                                color: AppColors.warningOrange, fontSize: 12)),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios,
                  size: 16, color: AppColors.greyText),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
