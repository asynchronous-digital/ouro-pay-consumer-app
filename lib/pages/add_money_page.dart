import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ouro_pay_consumer_app/config/app_config.dart';
import 'package:ouro_pay_consumer_app/theme/app_theme.dart';
import 'package:ouro_pay_consumer_app/models/deposit.dart';
import 'package:ouro_pay_consumer_app/services/deposit_service.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;

class AddMoneyPage extends StatefulWidget {
  final String? preSelectedCurrency;

  const AddMoneyPage({
    super.key,
    this.preSelectedCurrency,
  });

  @override
  State<AddMoneyPage> createState() => _AddMoneyPageState();
}

class _AddMoneyPageState extends State<AddMoneyPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final DepositService _depositService = DepositService();

  String _selectedCurrency = 'EUR';
  String _selectedPaymentMethod = 'bank_transfer';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Use pre-selected currency if provided and valid
    if (widget.preSelectedCurrency != null) {
      final validCurrencies = ['EUR', 'USD', 'SRD'];
      if (validCurrencies.contains(widget.preSelectedCurrency)) {
        _selectedCurrency = widget.preSelectedCurrency!;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitDeposit() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

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

    if (_notesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter remarks/notes'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Map payment method to backend expected values
      String backendPaymentMethod = _selectedPaymentMethod;
      if (_selectedPaymentMethod == 'credit_card' ||
          _selectedPaymentMethod == 'debit_card') {
        backendPaymentMethod = 'card';
      }

      final request = DepositRequest(
        currencyCode: _selectedCurrency,
        amount: amount,
        paymentMethod: backendPaymentMethod,
        notes: _notesController.text.trim(),
      );

      final response = await _depositService.createDeposit(request);

      if (mounted) {
        if (response.success) {
          // Check if we have a client secret for Stripe payment
          if (response.clientSecret != null &&
              response.clientSecret!.isNotEmpty) {
            print(
                '🔵 Stripe: client_secret received: ${response.clientSecret}');
            try {
              print('🔵 Stripe: Initializing Payment Sheet...');

              // Defensive initialization: Ensure Stripe is configured
              try {
                // Try to access the key to see if it throws
                final key = Stripe.publishableKey;
                if (key.isEmpty) throw Exception('Key is empty');
              } catch (_) {
                print('⚠️ Stripe not initialized, re-initializing...');
                final stripeKey = AppConfig.stripePublishableKey;
                if (stripeKey.isNotEmpty) {
                  Stripe.publishableKey = stripeKey;
                  Stripe.merchantIdentifier = 'merchant.com.ouropay.consumer';
                  Stripe.urlScheme = 'ouropay';
                  await Stripe.instance.applySettings();
                  print('✅ Stripe re-initialized successfully');
                } else {
                  throw Exception(
                      'Stripe publishable key is missing in config');
                }
              }

              // Initialize and present Payment Sheet
              await Stripe.instance.initPaymentSheet(
                paymentSheetParameters: SetupPaymentSheetParameters(
                  paymentIntentClientSecret: response.clientSecret!,
                  merchantDisplayName: AppConfig.appName,
                  style: ThemeMode.dark,
                  appearance: const PaymentSheetAppearance(
                    colors: PaymentSheetAppearanceColors(
                      primary: AppColors.primaryGold,
                    ),
                  ),
                ),
              );

              print('🔵 Stripe: Payment Sheet initialized, presenting...');
              await Stripe.instance.presentPaymentSheet();

              print('🔵 Stripe: Payment Sheet completed successfully');
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payment successful!'),
                    backgroundColor: AppColors.successGreen,
                  ),
                );
                // Return to dashboard with success flag
                Navigator.pop(context, true);
              }
            } on StripeException catch (e) {
              print(
                  '🔴 Stripe Exception: ${e.error.code} - ${e.error.message}');
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Payment failed: ${e.error.localizedMessage}'),
                    backgroundColor: AppColors.errorRed,
                  ),
                );
              }
            } catch (e) {
              print('🔴 General Error: $e');
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: AppColors.errorRed,
                  ),
                );
              }
            }
          } else {
            // Normal success (e.g. Bank Transfer)
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response.message),
                backgroundColor: AppColors.successGreen,
              ),
            );

            // Return to dashboard with success flag
            Navigator.pop(context, true);
          }
        } else {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        title: const Text(
          'Add Money',
          style: TextStyle(
            color: AppColors.whiteText,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.whiteText),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.darkBackground.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: AppColors.darkBackground,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Funds',
                          style: TextStyle(
                            color: AppColors.darkBackground,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Top up your wallet',
                          style: TextStyle(
                            color: AppColors.darkBackground,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form Card
            Card(
              color: AppColors.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Currency Selection
                    const Text(
                      'Currency',
                      style: TextStyle(
                        color: AppColors.whiteText,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      isExpanded: true,
                      dropdownColor: AppColors.cardBackground,
                      style: const TextStyle(
                          color: AppColors.whiteText, fontSize: 16),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.darkBackground,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(
                          Icons.currency_exchange,
                          color: AppColors.primaryGold,
                        ),
                      ),
                      items: [
                        _buildCurrencyItem('EUR', '€', 'Euro'),
                        _buildCurrencyItem('USD', '\$', 'US Dollar'),
                        _buildCurrencyItem('SRD', 'Sr\$', 'Surinamese Dollar'),
                      ],
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedCurrency = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Amount Input
                    const Text(
                      'Amount',
                      style: TextStyle(
                        color: AppColors.whiteText,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      style: const TextStyle(
                        color: AppColors.whiteText,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.darkBackground,
                        hintText: '0.00',
                        hintStyle: TextStyle(
                          color: AppColors.greyText.withOpacity(0.5),
                          fontSize: 24,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(
                          Icons.attach_money,
                          color: AppColors.primaryGold,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Payment Method
                    const Text(
                      'Payment Method',
                      style: TextStyle(
                        color: AppColors.whiteText,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedPaymentMethod,
                      dropdownColor: AppColors.cardBackground,
                      style: const TextStyle(
                          color: AppColors.whiteText, fontSize: 16),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.darkBackground,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(
                          Icons.payment,
                          color: AppColors.primaryGold,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'bank_transfer',
                          child: Text('Bank Transfer'),
                        ),
                        DropdownMenuItem(
                          value: 'credit_card',
                          child: Text('Credit Card'),
                        ),
                        DropdownMenuItem(
                          value: 'debit_card',
                          child: Text('Debit Card'),
                        ),
                      ],
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedPaymentMethod = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Notes (Mandatory)
                    Row(
                      children: [
                        const Text(
                          'Remarks',
                          style: TextStyle(
                            color: AppColors.whiteText,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '*',
                          style: TextStyle(
                            color: AppColors.errorRed,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      style: const TextStyle(color: AppColors.whiteText),
                      maxLines: 3,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.darkBackground,
                        hintText: 'Enter remarks about this deposit...',
                        hintStyle: TextStyle(
                          color: AppColors.greyText.withOpacity(0.5),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitDeposit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: AppColors.darkBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: AppColors.darkBackground,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Submit Deposit',
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

  DropdownMenuItem<String> _buildCurrencyItem(
    String code,
    String symbol,
    String name,
  ) {
    return DropdownMenuItem<String>(
      value: code,
      child: Text(
        '$symbol  $code - $name',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
