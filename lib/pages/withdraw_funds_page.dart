import 'package:flutter/material.dart';
import 'package:ouro_pay_consumer_app/theme/app_theme.dart';
import 'package:ouro_pay_consumer_app/services/wallet_service.dart';
import 'package:ouro_pay_consumer_app/models/bank_account.dart';

class WithdrawFundsPage extends StatefulWidget {
  final BankAccount bankAccount;

  const WithdrawFundsPage({
    super.key,
    required this.bankAccount,
  });

  @override
  State<WithdrawFundsPage> createState() => _WithdrawFundsPageState();
}

class _WithdrawFundsPageState extends State<WithdrawFundsPage> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  List<WalletData> _wallets = [];
  WalletData? _selectedWallet;
  bool _isLoadingWallets = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchWallets();
  }

  Future<void> _fetchWallets() async {
    try {
      final response = await WalletService().getWallets();
      if (mounted) {
        setState(() {
          _isLoadingWallets = false;
          if (response.success && response.wallets != null && response.wallets!.isNotEmpty) {
            _wallets = response.wallets!;
            _selectedWallet = _wallets.first;
          } else {
            // Fallback for demo/testing if API fails or returns empty
            _wallets = [
              WalletData(
                id: 1,
                currencyCode: 'USD',
                currencyName: 'US Dollar',
                currencySymbol: '\$',
                balance: 2500.00,
                lockedBalance: 0,
                availableBalance: 2500.00,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
              WalletData(
                id: 2,
                currencyCode: 'EUR',
                currencyName: 'Euro',
                currencySymbol: '€',
                balance: 1200.50,
                lockedBalance: 0,
                availableBalance: 1200.50,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
              WalletData(
                id: 3,
                currencyCode: 'SRD',
                currencyName: 'Surinamese Dollar',
                currencySymbol: 'Sr\$',
                balance: 5000.00,
                lockedBalance: 0,
                availableBalance: 5000.00,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            ];
            _selectedWallet = _wallets.first;
            // _errorMessage = response.message ?? 'Failed to load wallets';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingWallets = false;
          _errorMessage = 'Error loading wallets: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleWithdraw() async {
    if (_formKey.currentState!.validate()) {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text(
            'Confirm Withdrawal',
            style: TextStyle(color: AppColors.whiteText),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Amount: ${_selectedWallet?.currencySymbol}${_amountController.text}',
                style: const TextStyle(color: AppColors.whiteText, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'From: ${_selectedWallet?.currencyName} Wallet',
                style: const TextStyle(color: AppColors.greyText),
              ),
              const SizedBox(height: 4),
              const SizedBox(height: 8),
              Text(
                'To: ${widget.bankAccount.bankName} (${widget.bankAccount.maskedAccountNumber})',
                style: const TextStyle(color: AppColors.greyText),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: AppColors.greyText)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm', style: TextStyle(color: AppColors.primaryGold)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        setState(() {
          _isLoading = true;
        });

        // Simulate API call
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          Navigator.pop(context);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Withdrawal request submitted successfully'),
              backgroundColor: AppColors.primaryGold,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Withdraw Funds'),
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
      ),
      body: _isLoadingWallets
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGold))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Wallet Selection
                    const Text(
                      'Withdraw From',
                      style: TextStyle(
                        color: AppColors.greyText,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.greyText),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<WalletData>(
                          value: _selectedWallet,
                          dropdownColor: AppColors.cardBackground,
                          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primaryGold),
                          isExpanded: true,
                          items: _wallets.map((wallet) {
                            return DropdownMenuItem(
                              value: wallet,
                              child: Row(
                                children: [
                                  Text(
                                    wallet.currencyCode,
                                    style: const TextStyle(
                                      color: AppColors.whiteText,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '- ${wallet.currencyName}',
                                    style: const TextStyle(color: AppColors.greyText),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (WalletData? newValue) {
                            setState(() {
                              _selectedWallet = newValue;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Balance Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryGold, Color(0xFFB8860B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Available Balance',
                            style: TextStyle(
                              color: AppColors.darkBackground,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedWallet?.formattedAvailableBalance ?? 'N/A',
                            style: const TextStyle(
                              color: AppColors.darkBackground,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
              
              const Text(
                'Withdraw to',
                style: TextStyle(
                  color: AppColors.greyText,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance, color: AppColors.primaryGold),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.bankAccount.bankName,
                          style: const TextStyle(
                            color: AppColors.whiteText,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          widget.bankAccount.maskedAccountNumber,
                          style: const TextStyle(
                            color: AppColors.greyText,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppColors.whiteText, fontSize: 24),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  labelStyle: const TextStyle(color: AppColors.greyText),
                  prefixText: '${_selectedWallet?.currencySymbol ?? ''} ',
                  prefixStyle: const TextStyle(color: AppColors.whiteText, fontSize: 24),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.greyText),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primaryGold),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.errorRed),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.errorRed),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null) {
                    return 'Invalid amount';
                  }
                  if (amount <= 0) {
                    return 'Amount must be greater than 0';
                  }
                  if (_selectedWallet != null && amount > _selectedWallet!.availableBalance) {
                    return 'Insufficient balance';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 32),
              
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleWithdraw,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: AppColors.darkBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                          'Withdraw Funds',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
