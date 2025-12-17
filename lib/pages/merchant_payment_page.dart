import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ouro_pay_consumer_app/models/merchant_payment_info.dart';
import 'package:ouro_pay_consumer_app/theme/app_theme.dart';
import 'package:ouro_pay_consumer_app/services/merchant_service.dart';
import 'package:ouro_pay_consumer_app/models/merchant_transaction_models.dart';
import 'package:ouro_pay_consumer_app/widgets/quote_timer.dart';

class MerchantPaymentPage extends StatefulWidget {
  final MerchantPaymentInfo paymentInfo;

  const MerchantPaymentPage({super.key, required this.paymentInfo});

  @override
  State<MerchantPaymentPage> createState() => _MerchantPaymentPageState();
}

class _MerchantPaymentPageState extends State<MerchantPaymentPage> {
  final TextEditingController _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isProcessing = true;
      });

      try {
        final amount = double.parse(_amountController.text);
        final currency = widget.paymentInfo.merchant.currency;

        final merchantService = MerchantService();
        final response = await merchantService.calculatePayment(
            amount, currency, widget.paymentInfo.merchant.id);

        setState(() {
          _isProcessing = false;
        });

        if (response.success && response.data != null) {
          _showConfirmationSheet(response.data!);
        } else {
          _showError(response.message ?? 'Calculation failed');
        }
      } catch (e) {
        setState(() {
          _isProcessing = false;
        });
        _showError(e.toString());
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.errorRed),
    );
  }

  void _showConfirmationSheet(GoldCalculationData data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confirm Payment',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.whiteText,
              ),
            ),
            const SizedBox(height: 24),

            // Payment Summary
            _buildSummaryRow(
              'Amount to Pay',
              '${data.currency} ${data.fiatAmount.toStringAsFixed(2)}',
              isBold: true,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow('Gold Price',
                '${data.currency} ${data.goldPricePerGram.toStringAsFixed(2)} / g'),
            const SizedBox(height: 12),
            _buildSummaryRow(
              'Gold Required',
              '${data.goldRequired.toStringAsFixed(4)} g',
              isBold: true,
              valueColor: AppColors.primaryGold,
            ),
            const SizedBox(height: 24),

            if (!data.sufficientBalance)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.errorRed),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.errorRed),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Insufficient Balance',
                            style: TextStyle(
                              color: AppColors.errorRed,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'You have ${data.consumerGoldBalance.toStringAsFixed(4)} g',
                            style: const TextStyle(color: AppColors.errorRed),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Timer
            if (data.priceValidUntil.isNotEmpty && data.sufficientBalance)
              Center(
                child: QuoteTimer(
                  validUntilIso: data.priceValidUntil,
                  onExpired: () {
                    // Close sheet if open and show error
                    Navigator.of(context).pop();
                    _showError('Quote expired. Please calculate again.');
                  },
                ),
              ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    data.sufficientBalance ? () => _confirmPayment(data) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: AppColors.darkBackground,
                  disabledBackgroundColor:
                      AppColors.primaryGold.withOpacity(0.3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Confirm & Pay',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.greyText, fontSize: 16),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.whiteText,
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmPayment(GoldCalculationData data) async {
    Navigator.pop(context); // Close sheet

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryGold),
      ),
    );

    try {
      final merchantService = MerchantService();
      final response = await merchantService.payMerchant(
        merchantId: widget.paymentInfo.merchant.id,
        amount: data.fiatAmount,
        currency: data.currency,
        confirmGoldAmount: data.goldRequired,
      );

      // Close loading
      if (mounted) Navigator.pop(context);

      if (response.success) {
        if (mounted) {
          _showSuccessDialog();
        }
      } else {
        _showError(response.message ?? 'Payment failed');
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showError(e.toString());
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle,
                color: AppColors.successGreen, size: 60),
            const SizedBox(height: 16),
            const Text(
              'Payment Successful!',
              style: TextStyle(
                color: AppColors.whiteText,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You paid ${widget.paymentInfo.merchant.name}',
              style: const TextStyle(color: AppColors.greyText),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close Payment Page
            },
            child: const Text('Done',
                style: TextStyle(color: AppColors.primaryGold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.paymentInfo;
    final merchant = info.merchant;
    final balance = info.consumerBalance;
    final goldPrice = info.goldPrice;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Pay Merchant'),
        backgroundColor: AppColors.darkBackground,
        iconTheme: const IconThemeData(color: AppColors.primaryGold),
        titleTextStyle: const TextStyle(
            color: AppColors.primaryGold,
            fontSize: 20,
            fontWeight: FontWeight.bold),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Merchant Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.darkBackground,
                      child: merchant.logoUrl != null
                          ? ClipOval(
                              child: Image.network(merchant.logoUrl!,
                                  fit: BoxFit.cover, width: 80, height: 80))
                          : Text(
                              merchant.name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      merchant.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBackground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ID: ${merchant.id}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.darkBackground.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Payment Details
              const Text(
                'Payment Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.whiteText,
                ),
              ),
              const SizedBox(height: 16),

              // Currency Display
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Currency',
                        style: TextStyle(color: AppColors.greyText)),
                    Text(
                      '${merchant.currency} (${merchant.currencySymbol})',
                      style: const TextStyle(
                        color: AppColors.whiteText,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Amount Input
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppColors.whiteText),
                decoration: InputDecoration(
                  labelText: 'Amount to Pay',
                  prefixText: '${merchant.currencySymbol} ',
                  prefixStyle: const TextStyle(color: AppColors.whiteText),
                  hintText: '0.00',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Balance Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surfaceColor),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Your Balance',
                            style: TextStyle(color: AppColors.greyText)),
                        Text(
                          '${balance.totalGoldGrams} g',
                          style: const TextStyle(
                              color: AppColors.primaryGold,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Gold Sell Price',
                            style: TextStyle(color: AppColors.greyText)),
                        Text(
                          '${merchant.currencySymbol}${goldPrice.sellPricePerGram.toStringAsFixed(2)} / g',
                          style: const TextStyle(color: AppColors.whiteText),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Pay Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: AppColors.darkBackground,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.darkBackground))
                      : const Text(
                          'Continue to Pay',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
