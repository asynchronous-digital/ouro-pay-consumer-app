import 'package:flutter/material.dart';
import 'package:ouro_pay_consumer_app/services/gold_service.dart';
import 'package:ouro_pay_consumer_app/theme/app_theme.dart';

class TradeGoldPage extends StatefulWidget {
  const TradeGoldPage({Key? key}) : super(key: key);

  @override
  State<TradeGoldPage> createState() => _TradeGoldPageState();
}

class _TradeGoldPageState extends State<TradeGoldPage> {
  final List<String> _currencies = ['EUR', 'USD', 'SRD'];
  String _selectedCurrency = 'EUR';
  double? _grams;
  bool _isLoading = false;
  GoldPriceData? _priceData;

  @override
  void initState() {
    super.initState();
    _loadPrice();
  }

  Future<void> _loadPrice() async {
    setState(() => _isLoading = true);
    final service = GoldService();
    final resp = await service.getGoldPrice(_selectedCurrency);
    if (mounted) {
      setState(() {
        _priceData = resp.success ? resp.data : null;
        _isLoading = false;
      });
    }
  }

  Future<void> _performAction({required bool isBuy}) async {
    if (_grams == null || _grams! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount of grams')),
      );
      return;
    }
    setState(() => _isLoading = true);
    final service = GoldService();
    final resp = isBuy
        ? await service.buyGold(currency: _selectedCurrency, grams: _grams!)
        : await service.sellGold(currency: _selectedCurrency, grams: _grams!);
    if (mounted) {
      setState(() => _isLoading = false);
      if (resp.success) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Success'),
            content: Text(resp.message ?? 'Transaction completed'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp.message ?? 'Transaction failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trade Gold'),
        backgroundColor: AppColors.darkBackground,
      ),
      backgroundColor: AppColors.darkBackground,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Currency selector
            DropdownButton<String>(
              value: _selectedCurrency,
              items: _currencies
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => _selectedCurrency = v);
                  _loadPrice();
                }
              },
            ),
            const SizedBox(height: 16),
            // Price display
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _priceData != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Buy: ${_priceData!.getFormattedBuyPrice()}'),
                          Text('Sell: ${_priceData!.getFormattedSellPrice()}'),
                        ],
                      )
                    : const Text('Price not available'),
            const SizedBox(height: 24),
            // Grams input
            TextField(
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Grams',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => _grams = double.tryParse(v),
            ),
            const SizedBox(height: 24),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Buy'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.successGreen,
                    ),
                    onPressed: () => _performAction(isBuy: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.sell),
                    label: const Text('Sell'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.errorRed,
                    ),
                    onPressed: () => _performAction(isBuy: false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
