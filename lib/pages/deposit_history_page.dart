import 'package:flutter/material.dart';
import 'package:ouro_pay_consumer_app/theme/app_theme.dart';
import 'package:ouro_pay_consumer_app/models/deposit.dart';
import 'package:ouro_pay_consumer_app/services/deposit_service.dart';

class DepositHistoryPage extends StatefulWidget {
  final String? currency;

  const DepositHistoryPage({super.key, this.currency});

  @override
  State<DepositHistoryPage> createState() => _DepositHistoryPageState();
}

class _DepositHistoryPageState extends State<DepositHistoryPage> {
  final DepositService _depositService = DepositService();
  List<Deposit> _deposits = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDeposits();
  }

  Future<void> _loadDeposits() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response =
          await _depositService.getDeposits(currency: widget.currency);

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (response.success && response.deposits != null) {
            _deposits = response.deposits!;
          } else {
            _errorMessage = response.message;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading deposits: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        title: Text(
          widget.currency != null
              ? '${widget.currency} Deposit History'
              : 'Deposit History',
          style: const TextStyle(
            color: AppColors.whiteText,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.whiteText),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadDeposits,
        color: AppColors.primaryGold,
        backgroundColor: AppColors.cardBackground,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryGold,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.errorRed,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.whiteText,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDeposits,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_deposits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              color: AppColors.greyText.withOpacity(0.5),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No deposits yet',
              style: TextStyle(
                color: AppColors.greyText.withOpacity(0.7),
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _deposits.length,
      itemBuilder: (context, index) {
        return _buildDepositCard(_deposits[index]);
      },
    );
  }

  Widget _buildDepositCard(Deposit deposit) {
    Color statusColor;
    IconData statusIcon;

    switch (deposit.status.toLowerCase()) {
      case 'completed':
        statusColor = AppColors.successGreen;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = AppColors.warningYellow;
        statusIcon = Icons.pending;
        break;
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Reference and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    deposit.reference,
                    style: const TextStyle(
                      color: AppColors.whiteText,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon,
                        color: statusColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        deposit.statusDisplay,
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

            // Amount
            Text(
              deposit.formattedAmount,
              style: const TextStyle(
                color: AppColors.primaryGold,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Details
            _buildDetailRow('Payment Method', deposit.paymentMethod),
            if (deposit.fee > 0) ...[
              const SizedBox(height: 4),
              _buildDetailRow('Fee', '${deposit.formattedNetAmount}'),
            ],
            if (deposit.notes != null && deposit.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              _buildDetailRow('Notes', deposit.notes!),
            ],
            const SizedBox(height: 4),
            _buildDetailRow('Created', _formatDate(deposit.createdAt)),
            if (deposit.processedAt != null) ...[
              const SizedBox(height: 4),
              _buildDetailRow('Processed', _formatDate(deposit.processedAt!)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.greyText,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.whiteText,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}
