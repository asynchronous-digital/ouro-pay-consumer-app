import 'package:flutter/material.dart';
import 'package:ouro_pay_consumer_app/theme/app_theme.dart';
import 'package:ouro_pay_consumer_app/services/bank_service.dart';
import 'package:ouro_pay_consumer_app/services/auth_service.dart';
import 'package:ouro_pay_consumer_app/models/country.dart';
import 'package:ouro_pay_consumer_app/pages/bank_accounts_list_page.dart';

class AddBankAccountPage extends StatefulWidget {
  const AddBankAccountPage({super.key});

  @override
  State<AddBankAccountPage> createState() => _AddBankAccountPageState();
}

class _AddBankAccountPageState extends State<AddBankAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _bankService = BankService();
  final _authService = AuthService();

  final _accountHolderController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _swiftCodeController = TextEditingController();
  final _ibanController = TextEditingController();

  // Currency handling
  final List<String> _currencies = ['USD', 'EUR', 'SRD'];
  String _selectedCurrency = 'USD';

  // Country handling
  List<Country> _countries = [];
  Country? _selectedCountry;
  bool _isLoadingCountries = true;

  bool _isPrimary = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCountries();
  }

  Future<void> _fetchCountries() async {
    try {
      final countries = await _authService.getCountries();
      if (mounted) {
        setState(() {
          _countries = countries;
          _isLoadingCountries = false;
          // Pre-select Default (e.g. Netherlands or first one)
          if (_countries.isNotEmpty) {
            try {
              _selectedCountry = _countries.firstWhere((c) => c.code == 'NL');
            } catch (e) {
              _selectedCountry = _countries.first;
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCountries = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _accountHolderController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _swiftCodeController.dispose();
    _ibanController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    // Close keyboard
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final success = await _bankService.addBankAccount({
          "bank_name": _bankNameController.text.trim(),
          "account_holder_name": _accountHolderController.text.trim(),
          "account_number": _accountNumberController.text.trim(),
          "swift_code": _swiftCodeController.text.trim(),
          "iban": _ibanController.text.trim(),
          "currency_code": _selectedCurrency,
          "country_code": _selectedCountry?.code ?? 'NL',
          "is_primary": _isPrimary
        });

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Bank account added successfully'),
                backgroundColor: AppColors.successGreen,
              ),
            );
            Navigator.pop(context, true); // Return true to trigger refresh
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Add Bank Account'),
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.whiteText,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter your bank details',
                style: TextStyle(
                  color: AppColors.whiteText,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _accountHolderController,
                label: 'Account Holder Name',
                icon: Icons.person,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _bankNameController,
                label: 'Bank Name',
                icon: Icons.account_balance,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _accountNumberController,
                label: 'Account Number',
                icon: Icons.numbers,
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _swiftCodeController,
                label: 'SWIFT Code',
                icon: Icons.code,
                textCapitalization: TextCapitalization.characters,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _ibanController,
                label: 'IBAN',
                icon: Icons.account_balance_wallet,
                textCapitalization: TextCapitalization.characters,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedCurrency,
                      dropdownColor: AppColors.cardBackground,
                      style: const TextStyle(color: AppColors.whiteText),
                      decoration: InputDecoration(
                        labelText: 'Currency',
                        labelStyle: const TextStyle(color: AppColors.greyText),
                        prefixIcon: const Icon(Icons.attach_money,
                            color: AppColors.primaryGold),
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
                      items: _currencies.map((String currency) {
                        return DropdownMenuItem<String>(
                          value: currency,
                          child: Text(currency),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedCurrency = newValue;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _isLoadingCountries
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primaryGold))
                        : DropdownButtonFormField<Country>(
                            isExpanded: true,
                            value: _selectedCountry,
                            dropdownColor: AppColors.cardBackground,
                            style: const TextStyle(color: AppColors.whiteText),
                            decoration: InputDecoration(
                              labelText: 'Country',
                              labelStyle:
                                  const TextStyle(color: AppColors.greyText),
                              prefixIcon: const Icon(Icons.flag,
                                  color: AppColors.primaryGold),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: AppColors.greyText),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: AppColors.primaryGold),
                              ),
                            ),
                            items: _countries.map((Country country) {
                              return DropdownMenuItem<Country>(
                                value: country,
                                child: Text(country.name),
                              );
                            }).toList(),
                            onChanged: (Country? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedCountry = newValue;
                                });
                              }
                            },
                            validator: (value) =>
                                value == null ? 'Required' : null,
                          ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Is Primary Checkbox
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.greyText.withOpacity(0.3)),
                ),
                child: CheckboxListTile(
                  title: const Text('Set as Primary Account',
                      style: TextStyle(color: AppColors.whiteText)),
                  value: _isPrimary,
                  activeColor: AppColors.primaryGold,
                  checkColor: AppColors.darkBackground,
                  onChanged: (val) {
                    setState(() {
                      _isPrimary = val ?? false;
                    });
                  },
                ),
              ),

              const SizedBox(height: 32),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
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
                          'Add Bank Account',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: const TextStyle(color: AppColors.whiteText),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.greyText),
        prefixIcon: Icon(icon, color: AppColors.primaryGold),
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
      validator: validator,
    );
  }
}
