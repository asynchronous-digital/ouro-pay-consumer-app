import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ouro_pay_consumer_app/models/conversion.dart';
import 'package:ouro_pay_consumer_app/pages/conversion_history_page.dart';
import 'package:ouro_pay_consumer_app/services/conversion_service.dart';
import 'package:ouro_pay_consumer_app/services/wallet_service.dart';
import 'package:ouro_pay_consumer_app/theme/app_theme.dart';

class ConversionPage extends StatefulWidget {
  const ConversionPage({super.key});

  @override
  State<ConversionPage> createState() => _ConversionPageState();
}

class _ConversionPageState extends State<ConversionPage> {
  final ConversionService _conversionService = ConversionService();
  final WalletService _walletService = WalletService();
  final TextEditingController _amountController = TextEditingController();

  String _fromCurrency = 'EUR';
  String _toCurrency = 'USD';
  bool _isLoadingRate = false;
  bool _isConverting = false;
  bool _isLoadingWallets = true;
  ExchangeRate? _currentRate;
  String? _errorMessage;
  Map<String, double> _availableBalances = {};

  final List<String> _currencies = ['EUR', 'USD', 'SRD'];

  @override
  void initState() {
    super.initState();
    _loadWallets();
    _loadExchangeRate();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadWallets() async {
    setState(() {
      _isLoadingWallets = true;
    });

    try {
      final response = await _walletService.getWallets();
      if (response.success && response.wallets != null) {
        final balances = <String, double>{};
        for (var wallet in response.wallets!) {
          balances[wallet.currencyCode] = wallet.availableBalance;
        }
        if (mounted) {
          setState(() {
            _availableBalances = balances;
            _isLoadingWallets = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingWallets = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingWallets = false;
        });
      }
    }
  }

  double get _maxAvailableBalance {
    return _availableBalances[_fromCurrency] ?? 0.0;
  }

  void _setMaxAmount() {
    _amountController.text = _maxAvailableBalance.toStringAsFixed(2);
    setState(() {}); // Update estimated amount
  }

  Future<void> _loadExchangeRate() async {
    if (_fromCurrency == _toCurrency) {
      setState(() {
        _currentRate = null;
        _errorMessage = 'Please select different currencies';
      });
      return;
    }

    setState(() {
      _isLoadingRate = true;
      _errorMessage = null;
    });

    try {
      final response = await _conversionService.getExchangeRates(
        fromCurrency: _fromCurrency,
        toCurrency: _toCurrency,
      );

      if (mounted) {
        setState(() {
          _isLoadingRate = false;
          if (response.success && response.data != null) {
            _currentRate = response.data;
          } else {
            _errorMessage = response.message ?? 'Failed to load exchange rate';
            _currentRate = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRate = false;
          _errorMessage = 'Error loading exchange rate: $e';
          _currentRate = null;
        });
      }
    }
  }

  Future<void> _performConversion() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    // Validate amount
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    // Check if amount exceeds available balance
    if (amount > _maxAvailableBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Insufficient balance. Maximum available: ${_maxAvailableBalance.toStringAsFixed(2)} $_fromCurrency'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    if (_fromCurrency == _toCurrency) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select different currencies'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() {
      _isConverting = true;
    });

    try {
      final request = ConversionRequest(
        fromCurrency: _fromCurrency,
        toCurrency: _toCurrency,
        amount: amount,
      );

      final response = await _conversionService.convertCurrency(request);

      if (mounted) {
        setState(() {
          _isConverting = false;
        });

        if (response.success && response.data != null) {
          // Reload wallets to update balances
          _loadWallets();
          // Show success dialog
          _showSuccessDialog(response.data!);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Conversion failed'),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConverting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  void _showSuccessDialog(Conversion conversion) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.successGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Conversion Successful',
              style: TextStyle(
                color: AppColors.whiteText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(color: AppColors.greyText),
            const SizedBox(height: 16),
            _buildDetailRow(
              'From',
              '${conversion.formattedFromAmount} ${conversion.fromCurrency}',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'To',
              '${conversion.formattedToAmount} ${conversion.toCurrency}',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Exchange Rate',
              '1 ${conversion.fromCurrency} = ${conversion.formattedRate} ${conversion.toCurrency}',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Fee',
              '${conversion.formattedFee} ${conversion.fromCurrency}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to dashboard
            },
            child: const Text(
              'Done',
              style: TextStyle(color: AppColors.greyText),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ConversionHistoryPage(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: AppColors.darkBackground,
            ),
            child: const Text('View History'),
          ),
        ],
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
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  double? get _estimatedAmount {
    final amount = double.tryParse(_amountController.text);
    if (amount != null && _currentRate != null) {
      return amount * _currentRate!.rate;
    }
    return null;
  }

  Color _getCurrencyColor(String currency) {
    switch (currency) {
      case 'EUR':
        return AppColors.euroColor;
      case 'USD':
        return AppColors.usdColor;
      case 'SRD':
        return AppColors.srdColor;
      default:
        return AppColors.primaryGold;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Currency Conversion'),
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.pushNamed(context, '/conversion-history');
            },
            tooltip: 'Conversion History',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Currency Selection - Horizontal Layout
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // From Currency
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _getCurrencyColor(_fromCurrency),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'From',
                              style: TextStyle(
                                color: AppColors.greyText,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _fromCurrency,
                          dropdownColor: AppColors.cardBackground,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.darkBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          style: const TextStyle(
                            color: AppColors.whiteText,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: AppColors.primaryGold,
                            size: 20,
                          ),
                          items: _currencies.map((currency) {
                            return DropdownMenuItem(
                              value: currency,
                              enabled: currency !=
                                  _toCurrency, // Disable if it's the "To" currency
                              child: Text(
                                currency,
                                style: TextStyle(
                                  color: currency == _toCurrency
                                      ? AppColors.greyText.withOpacity(0.3)
                                      : AppColors.whiteText,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null && value != _toCurrency) {
                              setState(() {
                                _fromCurrency = value;
                                _amountController.clear();
                              });
                              _loadExchangeRate();
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        if (!_isLoadingWallets)
                          Text(
                            'Available: ${_maxAvailableBalance.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: AppColors.greyText.withOpacity(0.8),
                              fontSize: 11,
                            ),
                          )
                        else
                          SizedBox(height: 14), // Reserve space for consistency
                      ],
                    ),
                  ),

                  // Transfer Icon in the middle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Container(
                      margin: const EdgeInsets.only(top: 32),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        color: AppColors.darkBackground,
                        size: 20,
                      ),
                    ),
                  ),

                  // To Currency
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _getCurrencyColor(_toCurrency),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'To',
                              style: TextStyle(
                                color: AppColors.greyText,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _toCurrency,
                          dropdownColor: AppColors.cardBackground,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.darkBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          style: const TextStyle(
                            color: AppColors.whiteText,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: AppColors.primaryGold,
                            size: 20,
                          ),
                          items: _currencies.map((currency) {
                            return DropdownMenuItem(
                              value: currency,
                              enabled: currency !=
                                  _fromCurrency, // Disable if it's the "From" currency
                              child: Text(
                                currency,
                                style: TextStyle(
                                  color: currency == _fromCurrency
                                      ? AppColors.greyText.withOpacity(0.3)
                                      : AppColors.whiteText,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null && value != _fromCurrency) {
                              setState(() {
                                _toCurrency = value;
                              });
                              _loadExchangeRate();
                            }
                          },
                        ),
                        const SizedBox(
                            height: 22), // Match the other side's height
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Amount Input with MAX button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Amount',
                        style: TextStyle(
                          color: AppColors.greyText,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: _isLoadingWallets ? null : _setMaxAmount,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          backgroundColor:
                              AppColors.primaryGold.withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'MAX',
                          style: TextStyle(
                            color: AppColors.primaryGold,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                      color: AppColors.whiteText,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.darkBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      hintText: '0.00',
                      hintStyle: TextStyle(
                        color: AppColors.greyText.withOpacity(0.5),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                      suffixText: _fromCurrency,
                      suffixStyle: const TextStyle(
                        color: AppColors.greyText,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    onChanged: (value) {
                      // Validate doesn't exceed max balance
                      if (value.isNotEmpty) {
                        final amount = double.tryParse(value);
                        if (amount != null && amount > _maxAvailableBalance) {
                          // Cap at max available balance
                          _amountController.text =
                              _maxAvailableBalance.toStringAsFixed(2);
                          _amountController.selection =
                              TextSelection.fromPosition(
                            TextPosition(offset: _amountController.text.length),
                          );
                        }
                      }
                      setState(() {}); // Update estimated amount
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Exchange Rate Display
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: _isLoadingRate
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.darkBackground,
                      ),
                    )
                  : _errorMessage != null
                      ? Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.errorRed,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: AppColors.darkBackground,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        )
                      : _currentRate != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Exchange Rate',
                                      style: TextStyle(
                                        color: AppColors.darkBackground,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '1 $_fromCurrency = ${_currentRate!.rate.toStringAsFixed(4)} $_toCurrency',
                                      style: const TextStyle(
                                        color: AppColors.darkBackground,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                if (_estimatedAmount != null) ...[
                                  const SizedBox(height: 12),
                                  const Divider(
                                    color: AppColors.darkBackground,
                                    height: 1,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'You will receive',
                                        style: TextStyle(
                                          color: AppColors.darkBackground,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${_estimatedAmount!.toStringAsFixed(2)} $_toCurrency',
                                        style: const TextStyle(
                                          color: AppColors.darkBackground,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            )
                          : const Text(
                              'Select currencies to see exchange rate',
                              style: TextStyle(
                                color: AppColors.darkBackground,
                                fontSize: 14,
                              ),
                            ),
            ),

            const SizedBox(height: 24),

            // Convert Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isConverting || _currentRate == null
                    ? null
                    : _performConversion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: AppColors.darkBackground,
                  disabledBackgroundColor: AppColors.greyText,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isConverting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.darkBackground,
                        ),
                      )
                    : const Text(
                        'Transfer',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
