import 'package:flutter/material.dart';
import 'package:ouro_pay_consumer_app/services/gold_service.dart';
import 'package:ouro_pay_consumer_app/theme/app_theme.dart';

class GoldTransactionsPage extends StatefulWidget {
  const GoldTransactionsPage({Key? key}) : super(key: key);

  @override
  State<GoldTransactionsPage> createState() => _GoldTransactionsPageState();
}

class _GoldTransactionsPageState extends State<GoldTransactionsPage> {
  bool _isLoading = false;
  GoldTransactionsResponse? _response;

  @override
  void initState() {
    super.initState();
    _loadTransactions(isRefresh: false);
  }

  Future<void> _loadTransactions({bool isRefresh = false}) async {
    if (!isRefresh) {
      setState(() => _isLoading = true);
    }
    final service = GoldService();
    final resp = await service.getGoldTransactions();
    if (mounted) {
      setState(() {
        _response = resp;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gold Transactions',
          style: TextStyle(color: AppColors.primaryGold),
        ),
        backgroundColor: AppColors.darkBackground,
        iconTheme: const IconThemeData(color: AppColors.primaryGold),
        elevation: 0,
      ),
      backgroundColor: AppColors.darkBackground,
      body: RefreshIndicator(
        onRefresh: () => _loadTransactions(isRefresh: true),
        color: AppColors.primaryGold,
        backgroundColor: AppColors.cardBackground,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _response == null ||
                    !_response!.success ||
                    _response!.data == null ||
                    _response!.data!.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.primaryGold.withOpacity(0.2)),
                          ),
                          child: Icon(
                            Icons.history_edu,
                            size: 64,
                            color: AppColors.primaryGold.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'No Transactions Yet',
                          style: TextStyle(
                            color: AppColors.whiteText,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your gold trading history will appear here',
                          style: TextStyle(
                            color: AppColors.greyText.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _response!.data!.length,
                    itemBuilder: (context, index) {
                      final item =
                          _response!.data![index] as Map<String, dynamic>;
                      return _buildTransactionCard(item);
                    },
                  ),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final type = transaction['type']?.toString().toUpperCase() ?? 'UNKNOWN';
    final isBuy = type == 'BUY';
    final grams = double.tryParse(transaction['grams']?.toString() ?? '0') ?? 0;
    final total =
        double.tryParse(transaction['total_amount']?.toString() ?? '0') ?? 0;
    final currency = transaction['currency_code']?.toString() ?? 'USD';
    final status = transaction['status']?.toString().toUpperCase() ?? 'PENDING';
    final dateStr = transaction['created_at']?.toString() ?? '';

    // Parse date
    DateTime? date;
    try {
      date = DateTime.parse(dateStr);
    } catch (_) {}

    final formattedDate = date != null
        ? '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
        : dateStr;

    Color statusColor;
    switch (status) {
      case 'COMPLETED':
        statusColor = AppColors.successGreen;
        break;
      case 'FAILED':
        statusColor = AppColors.errorRed;
        break;
      default:
        statusColor = AppColors.primaryGold;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.greyText.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isBuy
                        ? AppColors.successGreen.withOpacity(0.1)
                        : AppColors.errorRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isBuy ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isBuy ? AppColors.successGreen : AppColors.errorRed,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBuy ? 'Bought Gold' : 'Sold Gold',
                        style: const TextStyle(
                          color: AppColors.whiteText,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          color: AppColors.greyText.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isBuy ? '+' : '-'}${grams.toStringAsFixed(3)} g',
                      style: TextStyle(
                        color:
                            isBuy ? AppColors.successGreen : AppColors.errorRed,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.greyText, height: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildInfoColumn(
                    'Total', '$currency ${total.toStringAsFixed(2)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.greyText.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.whiteText,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
