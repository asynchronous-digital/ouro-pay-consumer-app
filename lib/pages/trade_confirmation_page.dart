import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ouro_pay_consumer_app/services/gold_service.dart';
import 'package:ouro_pay_consumer_app/services/wallet_service.dart';
import 'package:ouro_pay_consumer_app/theme/app_theme.dart';
import 'package:ouro_pay_consumer_app/pages/gold_transactions_page.dart';

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
  late String _selectedCurrency;
  late double _currentPricePerGram;
  double _totalValue = 0.0;
  double _availableBalance = 0.0;
  bool _isLoading = false;
  bool _isPriceLoading = false;
  bool _isBalanceLoading = false;
  double _availableGoldHoldings = 0.0;

  @override
  void initState() {
    super.initState();
    _selectedCurrency = widget.currency;
    _currentPricePerGram = widget.pricePerGram;
    _gramsController.addListener(_updateTotal);
    if (widget.isBuy) {
      _fetchBalance();
    } else {
      _fetchHoldings();
    }
  }

  @override
  void dispose() {
    _gramsController.dispose();
    super.dispose();
  }

  void _updateTotal() {
    final grams = double.tryParse(_gramsController.text) ?? 0.0;
    setState(() {
      _totalValue = grams * _currentPricePerGram;
    });
  }

  Future<void> _fetchBalance() async {
    setState(() => _isBalanceLoading = true);
    try {
      final service = WalletService();
      final response = await service.getWallets();
      if (response.success && response.wallets != null) {
        final wallet = response.wallets!.firstWhere(
          (w) => w.currencyCode == _selectedCurrency,
          orElse: () => WalletData(
            id: 0,
            currencyCode: _selectedCurrency,
            currencyName: '',
            currencySymbol: '',
            balance: 0,
            lockedBalance: 0,
            availableBalance: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        if (mounted) {
          setState(() {
            _availableBalance = wallet.availableBalance;
            _isBalanceLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isBalanceLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isBalanceLoading = false);
    }
  }

  Future<double> _fetchHoldings() async {
    try {
      final service = GoldService();
      final response = await service.getGoldHoldings();
      if (response.success && response.data != null) {
        if (mounted) {
          setState(() {
            _availableGoldHoldings = response.data!.totalGrams;
          });
        }
        return response.data!.totalGrams;
      }
    } catch (e) {
      // ignore errors
    }
    return 0.0;
  }

  Future<void> _updateCurrency(String? newCurrency) async {
    if (newCurrency == null || newCurrency == _selectedCurrency) return;

    setState(() {
      _isPriceLoading = true;
      _selectedCurrency = newCurrency;
    });

    if (widget.isBuy) {
      _fetchBalance();
    }

    try {
      final service = GoldService();
      final response = await service.getGoldPrice(newCurrency);
      if (response.success && response.data != null) {
        if (mounted) {
          setState(() {
            _currentPricePerGram = widget.isBuy
                ? response.data!.buyPrice
                : response.data!.sellPrice;
            _isPriceLoading = false;
          });
          _updateTotal();
        }
      } else {
        // Handle error, revert or show message
        if (mounted) {
          setState(() => _isPriceLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update price')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPriceLoading = false);
      }
    }
  }

  Future<void> _confirmTrade() async {
    final grams = double.tryParse(_gramsController.text);
    if (grams == null || grams <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (widget.isBuy && _totalValue > _availableBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient funds'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    if (!widget.isBuy && grams > _availableGoldHoldings) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient gold holdings'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    // Step 1: Show loading indicator first to prevent blank screen
    setState(() => _isLoading = true);

    // Step 2: Dismiss keyboard after loading indicator is shown
    FocusScope.of(context).unfocus();

    // Step 3: Make API call
    final service = GoldService();
    final resp = widget.isBuy
        ? await service.buyGold(currency: _selectedCurrency, grams: grams)
        : await service.sellGold(currency: _selectedCurrency, grams: grams);

    if (mounted) {
      // Step 4: Show dialog
      if (resp.success) {
        // Temporarily fetch holdings to show in dialog, but don't update UI yet
        final tempHoldings = await _fetchHoldings();

        if (!mounted) return;

        // Stop loading just before showing dialog (prevents flash of underlying page)
        setState(() => _isLoading = false);

        // Show success dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.cardBackground,
            title: const Row(
              children: [
                Icon(Icons.check_circle,
                    color: AppColors.successGreen, size: 32),
                SizedBox(width: 12),
                Text(
                  'Success',
                  style: TextStyle(color: AppColors.whiteText),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resp.message ?? 'Transaction completed successfully',
                  style: const TextStyle(color: AppColors.greyText),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your new gold balance: ${tempHoldings.toStringAsFixed(3)}g',
                  style: const TextStyle(
                      color: AppColors.primaryGold,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (_) => const GoldTransactionsPage()),
                  );
                },
                child: const Text('View Transactions',
                    style: TextStyle(color: AppColors.primaryGold)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  // Pop back to dashboard with success flag
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/dashboard', (route) => false);
                },
                child: const Text('OK',
                    style: TextStyle(color: AppColors.whiteText)),
              ),
            ],
          ),
        );

        // Step 5: After dialog closes (if not already navigated to dashboard)
        // The dialog's OK button now handles navigation to dashboard
        // Only pop if user clicked "View Transactions" instead of "OK"
        if (!mounted) return;

        // This will only execute if the dialog was closed by "View Transactions" button
        // The OK button navigates directly to dashboard in its onPressed handler
      } else {
        // Stop loading for error case
        setState(() => _isLoading = false);

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resp.message ?? 'Transaction failed'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
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
            ...['EUR', 'USD', 'SRD'].map((currency) => ListTile(
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
                    Navigator.pop(context);
                    _updateCurrency(currency);
                  },
                )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.isBuy ? 'Buy' : 'Sell';
    final color = widget.isBuy ? AppColors.successGreen : AppColors.errorRed;
    final hasInsufficientFunds =
        widget.isBuy && _totalValue > _availableBalance;
    final hasInsufficientGold = !widget.isBuy &&
        (double.tryParse(_gramsController.text) ?? 0.0) >
            _availableGoldHoldings;

    return Scaffold(
      appBar: AppBar(
        title: Text('$action Gold'),
        backgroundColor: AppColors.darkBackground,
        actions: [
          // Currency Selector in AppBar
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: GestureDetector(
                onTap: _isLoading ? null : _showCurrencyPicker,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.primaryGold.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedCurrency,
                        style: const TextStyle(
                          color: AppColors.primaryGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down,
                          color: AppColors.primaryGold, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.darkBackground,
      body: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
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
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}')),
                      if (!widget.isBuy) MaxAmountFormatter(_availableGoldHoldings),
                    ],
                    style: const TextStyle(color: AppColors.whiteText, fontSize: 24),
                    decoration: InputDecoration(
                      suffixText: 'grams',
                      suffixStyle: const TextStyle(color: AppColors.primaryGold),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: AppColors.greyText.withValues(alpha: 0.3)),
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
                      border: Border.all(
                          color: AppColors.greyText.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Price per gram',
                                style: TextStyle(color: AppColors.greyText)),
                            _isPriceLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2))
                                : Text(
                                    '${_currentPricePerGram.toStringAsFixed(2)} $_selectedCurrency',
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
                            _isPriceLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2))
                                : Text(
                                    '${_totalValue.toStringAsFixed(2)} $_selectedCurrency',
                                    style: TextStyle(
                                        color: hasInsufficientFunds
                                            ? AppColors.errorRed
                                            : color,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold),
                                  ),
                          ],
                        ),
                        if (widget.isBuy) ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Available Balance',
                                  style: TextStyle(
                                      color: AppColors.greyText, fontSize: 14)),
                              _isBalanceLoading
                                  ? const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child:
                                          CircularProgressIndicator(strokeWidth: 2))
                                  : Text(
                                      '${_availableBalance.toStringAsFixed(2)} $_selectedCurrency',
                                      style: TextStyle(
                                        color: hasInsufficientFunds
                                            ? AppColors.errorRed
                                            : AppColors.whiteText,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                            ],
                          ),
                        ] else ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Current Gold Balance',
                                  style: TextStyle(
                                      color: AppColors.greyText, fontSize: 14)),
                              Text(
                                '${_availableGoldHoldings.toStringAsFixed(3)}g',
                                style: const TextStyle(
                                  color: AppColors.whiteText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Estimated Remaining Gold',
                                  style: TextStyle(
                                      color: AppColors.greyText, fontSize: 14)),
                              Text(
                                '${(_availableGoldHoldings - (double.tryParse(_gramsController.text) ?? 0.0)).toStringAsFixed(3)}g',
                                style: TextStyle(
                                  color: (_availableGoldHoldings -
                                              (double.tryParse(
                                                      _gramsController.text) ??
                                                  0.0)) <
                                          0
                                      ? AppColors.errorRed
                                      : AppColors.primaryGold,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ||
                              _isPriceLoading ||
                              hasInsufficientFunds ||
                              hasInsufficientGold
                          ? null
                          : _confirmTrade,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        disabledBackgroundColor: color.withValues(alpha: 0.3),
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
                              hasInsufficientFunds
                                  ? 'Insufficient Funds'
                                  : hasInsufficientGold
                                      ? 'Insufficient Gold'
                                      : 'Confirm $action',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MaxAmountFormatter extends TextInputFormatter {
  final double maxAmount;

  MaxAmountFormatter(this.maxAmount);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Allow partial inputs like "." or ".1" while typing
    if (newValue.text == '.' || newValue.text.startsWith('.')) {
      return newValue;
    }

    final newAmount = double.tryParse(newValue.text);
    if (newAmount == null) {
      return oldValue;
    }

    if (newAmount > maxAmount) {
      return oldValue;
    }

    return newValue;
  }
}
