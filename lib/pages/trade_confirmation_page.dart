import 'package:flutter/material.dart';
import 'package:ouro_pay_consumer_app/services/gold_service.dart';
import 'package:ouro_pay_consumer_app/theme/app_theme.dart';

class TradeConfirmationPage extends StatefulWidget {
  final bool isBuy;
  final String currency;
  final double pricePerGram;

  const TradeConfirmationPage({
    Key? key,
    required this.isBuy,
    required this.currency,
    required this.pricePerGram,
  }) : super(key: key);

  @override
  State<TradeConfirmationPage> createState() => _TradeConfirmationPageState();
}

class _TradeConfirmationPageState extends State<TradeConfirmationPage> {
  final TextEditingController _gramsController = TextEditingController();
  double _totalValue = 0.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _gramsController.addListener(_updateTotal);
  }

  @override
  void dispose() {
    _gramsController.dispose();
    super.dispose();
  }

  void _updateTotal() {
    final grams = double.tryParse(_gramsController.text) ?? 0.0;
    setState(() {
      _totalValue = grams * widget.pricePerGram;
    });
  }

  Future<void> _confirmTrade() async {
    final grams = double.tryParse(_gramsController.text);
    if (grams == null || grams <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final service = GoldService();
    final resp = widget.isBuy
        ? await service.buyGold(currency: widget.currency, grams: grams)
        : await service.sellGold(currency: widget.currency, grams: grams);

    if (mounted) {
      setState(() => _isLoading = false);
      if (resp.success) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('Success'),
            content: Text(resp.message ?? 'Transaction completed successfully'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(true); // Return to previous screen
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resp.message ?? 'Transaction failed'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.isBuy ? 'Buy' : 'Sell';
    final color = widget.isBuy ? AppColors.successGreen : AppColors.errorRed;

    return Scaffold(
      appBar: AppBar(
        title: Text('$action Gold'),
        backgroundColor: AppColors.darkBackground,
      ),
      backgroundColor: AppColors.darkBackground,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter Amount',
              style: TextStyle(
                color: AppColors.greyText,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _gramsController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.whiteText, fontSize: 24),
              decoration: InputDecoration(
                suffixText: 'grams',
                suffixStyle: const TextStyle(color: AppColors.primaryGold),
                enabledBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: AppColors.greyText.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppColors.primaryGold),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.greyText.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Price per gram',
                          style: TextStyle(color: AppColors.greyText)),
                      Text(
                        '${widget.pricePerGram.toStringAsFixed(2)} ${widget.currency}',
                        style: const TextStyle(
                            color: AppColors.whiteText,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: AppColors.greyText),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Value',
                          style: TextStyle(
                              color: AppColors.whiteText, fontSize: 18)),
                      Text(
                        '${_totalValue.toStringAsFixed(2)} ${widget.currency}',
                        style: TextStyle(
                            color: color,
                            fontSize: 24,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _confirmTrade,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Confirm $action',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
