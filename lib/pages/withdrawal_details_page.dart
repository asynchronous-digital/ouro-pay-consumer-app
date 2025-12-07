import 'package:flutter/material.dart';
import 'package:ouro_pay_consumer_app/theme/app_theme.dart';
import 'package:ouro_pay_consumer_app/models/withdrawal.dart';
import 'package:ouro_pay_consumer_app/services/withdrawal_service.dart';

class WithdrawalDetailsPage extends StatefulWidget {
  final int withdrawalId;

  const WithdrawalDetailsPage({super.key, required this.withdrawalId});

  @override
  State<WithdrawalDetailsPage> createState() => _WithdrawalDetailsPageState();
}

class _WithdrawalDetailsPageState extends State<WithdrawalDetailsPage> {
  bool _isLoading = true;
  Withdrawal? _withdrawal;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final withdrawal =
          await WithdrawalService().getWithdrawalDetails(widget.withdrawalId);
      if (mounted) {
        setState(() {
          _withdrawal = withdrawal;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll("Exception:", "");
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Withdrawal Details'),
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGold))
          : _errorMessage != null
              ? Center(
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: AppColors.errorRed)))
              : _withdrawal == null
                  ? const Center(
                      child: Text('Withdrawal not found',
                          style: TextStyle(color: AppColors.greyText)))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatusCard(_withdrawal!),
                          const SizedBox(height: 24),
                          _buildDetailsCard(_withdrawal!),
                          const SizedBox(height: 24),
                          _buildBankCard(_withdrawal!),
                          if (_withdrawal!.notes != null &&
                              _withdrawal!.notes!.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _buildNotesCard(_withdrawal!),
                          ],
                        ],
                      ),
                    ),
    );
  }

  Widget _buildStatusCard(Withdrawal withdrawal) {
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Icon(statusIcon, size: 48, color: statusColor),
          const SizedBox(height: 16),
          Text(
            withdrawal.formattedAmount,
            style: const TextStyle(
              color: AppColors.whiteText,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              withdrawal.statusDisplay,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (withdrawal.reference != null) ...[
            const SizedBox(height: 16),
            Text(
              'Ref: ${withdrawal.reference}',
              style: const TextStyle(color: AppColors.greyText, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsCard(Withdrawal withdrawal) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transaction Details',
            style: TextStyle(
              color: AppColors.whiteText,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Amount', withdrawal.formattedAmount),
          if (withdrawal.fee != null && withdrawal.fee! > 0) ...[
            const SizedBox(height: 12),
            _buildDetailRow('Fee', withdrawal.formattedFee),
            const SizedBox(height: 12),
            const Divider(color: AppColors.greyText),
            const SizedBox(height: 12),
            _buildDetailRow('Net Amount', withdrawal.formattedNetAmount,
                isBold: true),
          ],
          const SizedBox(height: 12),
          _buildDetailRow('Date', _formatDate(withdrawal.createdAt)),
        ],
      ),
    );
  }

  Widget _buildBankCard(Withdrawal withdrawal) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bank Account',
            style: TextStyle(
              color: AppColors.whiteText,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.account_balance, color: AppColors.primaryGold),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    withdrawal.bankName,
                    style: const TextStyle(
                      color: AppColors.whiteText,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    withdrawal.maskedAccountNumber,
                    style: const TextStyle(color: AppColors.greyText),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(Withdrawal withdrawal) {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notes',
            style: TextStyle(
              color: AppColors.whiteText,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            withdrawal.notes!,
            style: const TextStyle(
                color: AppColors.greyText, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.greyText),
        ),
        Text(
          value,
          style: TextStyle(
            color: AppColors.whiteText,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 14,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
