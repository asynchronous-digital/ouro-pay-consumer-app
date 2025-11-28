import 'package:flutter/material.dart';
import 'package:ouro_pay_consumer_app/services/gold_service.dart';
import 'package:ouro_pay_consumer_app/theme/app_theme.dart';
import 'package:ouro_pay_consumer_app/pages/trade_confirmation_page.dart';

class TradeGoldPage extends StatefulWidget {
  const TradeGoldPage({Key? key}) : super(key: key);

  @override
  State<TradeGoldPage> createState() => _TradeGoldPageState();
}

class _TradeGoldPageState extends State<TradeGoldPage> {
  final List<String> _currencies = ['EUR', 'USD', 'SRD'];
  String _selectedCurrency = 'EUR';
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

  void _navigateToConfirmation({required bool isBuy}) {
    if (_priceData == null) return;

    final price = isBuy ? _priceData!.buyPrice : _priceData!.sellPrice;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TradeConfirmationPage(
          isBuy: isBuy,
          currency: _selectedCurrency,
          pricePerGram: price,
        ),
      ),
    ).then((result) {
      if (result == true) {
        // Optionally refresh data or show a success message if needed
      }
    });
  }

  void _showCurrencyPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Currency',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.whiteText,
              ),
            ),
            const SizedBox(height: 20),
            ..._currencies.map((currency) => ListTile(
                  title: Text(
                    currency,
                    style: TextStyle(
                      color: _selectedCurrency == currency
                          ? AppColors.primaryGold
                          : AppColors.whiteText,
                      fontWeight: _selectedCurrency == currency
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: _selectedCurrency == currency
                      ? const Icon(Icons.check, color: AppColors.primaryGold)
                      : null,
                  onTap: () {
                    setState(() => _selectedCurrency = currency);
                    Navigator.pop(context);
                    _loadPrice();
                  },
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trade Gold'),
        backgroundColor: AppColors.darkBackground,
      ),
      backgroundColor: AppColors.darkBackground,
      body: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price Display Area
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Current Price',
                              style: TextStyle(
                                color: AppColors.darkBackground,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            GestureDetector(
                              onTap: _showCurrencyPicker,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.darkBackground.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      _selectedCurrency,
                                      style: const TextStyle(
                                        color: AppColors.darkBackground,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_drop_down, color: AppColors.darkBackground),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _isLoading
                            ? const CircularProgressIndicator(color: AppColors.darkBackground)
                            : _priceData != null
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      Column(
                                        children: [
                                          const Text(
                                            'BUY',
                                            style: TextStyle(
                                              color: AppColors.darkBackground,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            '${_priceData!.getFormattedBuyPrice()} $_selectedCurrency',
                                            style: const TextStyle(
                                              color: AppColors.darkBackground,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        height: 40,
                                        width: 1,
                                        color: AppColors.darkBackground.withOpacity(0.3),
                                      ),
                                      Column(
                                        children: [
                                          const Text(
                                            'SELL',
                                            style: TextStyle(
                                              color: AppColors.darkBackground,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            '${_priceData!.getFormattedSellPrice()} $_selectedCurrency',
                                            style: const TextStyle(
                                              color: AppColors.darkBackground,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                : const Text('Price unavailable', style: TextStyle(color: AppColors.darkBackground)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text('Buy Gold'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.successGreen,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () => _navigateToConfirmation(isBuy: true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.sell),
                          label: const Text('Sell Gold'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.errorRed,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () => _navigateToConfirmation(isBuy: false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
