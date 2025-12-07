import 'package:flutter/material.dart';
import 'package:ouro_pay_consumer_app/theme/app_theme.dart';
import 'package:ouro_pay_consumer_app/services/wallet_service.dart';
import 'package:ouro_pay_consumer_app/models/bank_account.dart';
import 'package:ouro_pay_consumer_app/services/bank_service.dart';
import 'package:ouro_pay_consumer_app/services/withdrawal_service.dart';

class WithdrawFundsPage extends StatefulWidget {
  final BankAccount? preSelectedBankAccount;

  const WithdrawFundsPage({
    super.key,
    this.preSelectedBankAccount,
  });

  @override
  State<WithdrawFundsPage> createState() => _WithdrawFundsPageState();
}

class _WithdrawFundsPageState extends State<WithdrawFundsPage> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _previousValidAmount = '';

  List<WalletData> _wallets = [];
  WalletData? _selectedWallet;
  bool _isLoadingWallets = true;

  List<BankAccount> _bankAccounts = [];
  BankAccount? _selectedBankAccount;
  bool _isLoadingBanks = true;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoadingWallets = true;
      _isLoadingBanks = true;
      _errorMessage = null;
    });

    try {
      // Fetch Wallets
      final walletResponse = await WalletService().getWallets();
      if (walletResponse.success &&
          walletResponse.wallets != null &&
          walletResponse.wallets!.isNotEmpty) {
        // Filter wallets to show only those with available balance > 0
        _wallets = walletResponse.wallets!
            .where((wallet) => wallet.availableBalance > 0)
            .toList();
        
        if (_wallets.isNotEmpty) {
          _selectedWallet = _wallets.first; // Default to first wallet with balance
        } else {
          _selectedWallet = null;
        }
      } else {
        // Fallback if needed or handle empty
      }

      // Fetch Bank Accounts
      final bankAccounts = await BankService().getBankAccounts();
      _bankAccounts = bankAccounts;

      if (widget.preSelectedBankAccount != null) {
        // Try to match pre-selected by ID
        try {
          _selectedBankAccount = _bankAccounts
              .firstWhere((b) => b.id == widget.preSelectedBankAccount!.id);
        } catch (_) {
          if (_bankAccounts.isNotEmpty)
            _selectedBankAccount = _bankAccounts.first;
        }
      } else if (_bankAccounts.isNotEmpty) {
        _selectedBankAccount = _bankAccounts.first;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception:", "");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingWallets = false;
          _isLoadingBanks = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleWithdraw() async {
    // Dismiss keyboard immediately by requesting focus on a new unused node
    FocusScope.of(context).requestFocus(FocusNode());

    if (_formKey.currentState!.validate()) {
      if (_selectedWallet == null || _selectedBankAccount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select a wallet and a bank account')),
        );
        return;
      }

      // Check balance
      final amount = double.tryParse(_amountController.text) ?? 0;
      if (_selectedWallet != null &&
          amount > _selectedWallet!.availableBalance) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Insufficient balance for this withdrawal'),
            backgroundColor: AppColors.errorRed,
          ),
        );
        return;
      }

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
                style:
                    const TextStyle(color: AppColors.whiteText, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'From: ${_selectedWallet?.currencyName} Wallet',
                style: const TextStyle(color: AppColors.greyText),
              ),
              const SizedBox(height: 8),
              Text(
                'To: ${_selectedBankAccount?.bankName} (${_selectedBankAccount?.maskedAccountNumber})',
                style: const TextStyle(color: AppColors.greyText),
              ),
              if (_notesController.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Notes: ${_notesController.text}',
                  style: const TextStyle(
                      color: AppColors.greyText, fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.greyText)),
            ),
            TextButton(
              onPressed: () {
                // Ensure focus is cleared before closing dialog
                FocusScope.of(context).requestFocus(FocusNode());
                Navigator.pop(context, true);
              },
              child: const Text('Confirm',
                  style: TextStyle(color: AppColors.primaryGold)),
            ),
          ],
        ),
      );

      // Ensure keyboard stays closed after dialog
      if (mounted) FocusScope.of(context).unfocus();

      if (confirmed == true) {
        setState(() {
          _isLoading = true;
        });

        try {
          final success = await WithdrawalService().createWithdrawal({
            "currency_code": _selectedWallet?.currencyCode ?? "USD",
            "amount": double.parse(_amountController.text),
            "bank_account_id": _selectedBankAccount?.id,
            "notes": _notesController.text,
          });

          if (mounted) {
            setState(() {
              _isLoading = false;
            });

            if (success) {
              Navigator.pop(context); // Close WithdrawFundsPage
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Withdrawal request submitted successfully'),
                  backgroundColor: AppColors.primaryGold,
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
                content:
                    Text('Error: ${e.toString().replaceAll("Exception:", "")}'),
                backgroundColor: AppColors.errorRed,
              ),
            );
          }
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
      body: (_isLoadingWallets || _isLoadingBanks)
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGold))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(_errorMessage!,
                            style: const TextStyle(color: AppColors.errorRed)),
                      ),

                    // Wallet Selection
                    const Text(
                      'Withdraw From',
                      style: TextStyle(
                        color: AppColors.greyText,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    if (_wallets.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.warningOrange),
                        ),
                        child: const Text(
                          "No wallets with available balance found. Please deposit funds first.",
                          style: TextStyle(color: AppColors.whiteText),
                        ),
                      )
                    else
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
                            icon: const Icon(Icons.keyboard_arrow_down,
                                color: AppColors.primaryGold),
                            isExpanded: true,
                            items: _wallets.map((wallet) {
                              return DropdownMenuItem(
                                value: wallet,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
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
                                          style: const TextStyle(
                                              color: AppColors.greyText),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      wallet.formattedAvailableBalance,
                                      style: const TextStyle(
                                        color: AppColors.primaryGold,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
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

                    if (_bankAccounts.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.errorRed),
                        ),
                        child: const Text(
                          "No Bank Accounts Found. Please add a bank account first.",
                          style: TextStyle(color: AppColors.whiteText),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.greyText),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<BankAccount>(
                              value: _selectedBankAccount,
                              dropdownColor: AppColors.cardBackground,
                              icon: const Icon(Icons.keyboard_arrow_down,
                                  color: AppColors.primaryGold),
                              isExpanded: true,
                              items: _bankAccounts.map((account) {
                                final currencyCode =
                                    account.currency?.code ?? '';
                                final displayCurrency = currencyCode.isNotEmpty
                                    ? ' ($currencyCode)'
                                    : '';
                                return DropdownMenuItem(
                                  value: account,
                                  child: Text(
                                    '${account.bankName} - ${account.maskedAccountNumber}$displayCurrency',
                                    style: const TextStyle(
                                        color: AppColors.whiteText),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedBankAccount = val;
                                });
                              }),
                        ),
                      ),

                    const SizedBox(height: 24),

                    TextFormField(
                      controller: _amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (value) {
                        if (_selectedWallet != null) {
                          if (value.isEmpty) {
                            _previousValidAmount = '';
                            return;
                          }

                          final amount = double.tryParse(value);
                          if (amount != null) {
                            if (amount > _selectedWallet!.availableBalance) {
                              // Revert change
                              _amountController.text = _previousValidAmount;
                              _amountController.selection =
                                  TextSelection.fromPosition(TextPosition(
                                      offset: _previousValidAmount.length));

                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Amount cannot exceed available balance'),
                                  backgroundColor: AppColors.warningOrange,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            } else {
                              // Valid input, update tracker
                              _previousValidAmount = value;
                            }
                          }
                        }
                      },
                      style: const TextStyle(
                          color: AppColors.whiteText, fontSize: 24),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        labelStyle: const TextStyle(color: AppColors.greyText),
                        prefixText: '${_selectedWallet?.currencySymbol ?? ''} ',
                        prefixStyle: const TextStyle(
                            color: AppColors.whiteText, fontSize: 24),
                        suffixIcon: TextButton(
                          onPressed: () {
                            if (_selectedWallet != null) {
                              setState(() {
                                _amountController.text = _selectedWallet!
                                    .availableBalance
                                    .toStringAsFixed(2);
                              });
                              // Clear any snackbars
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                            }
                          },
                          child: const Text('MAX',
                              style: TextStyle(
                                  color: AppColors.primaryGold,
                                  fontWeight: FontWeight.bold)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.greyText),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.primaryGold),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.errorRed),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.errorRed),
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
                        if (_selectedWallet != null &&
                            amount > _selectedWallet!.availableBalance) {
                          return 'Insufficient balance';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      style: const TextStyle(color: AppColors.whiteText),
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Notes (Optional)',
                        labelStyle: const TextStyle(color: AppColors.greyText),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.greyText),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.primaryGold),
                        ),
                      ),
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
