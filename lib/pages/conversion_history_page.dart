import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ouro_pay_consumer_app/models/conversion.dart';
import 'package:ouro_pay_consumer_app/services/conversion_service.dart';
import 'package:ouro_pay_consumer_app/theme/app_theme.dart';

class ConversionHistoryPage extends StatefulWidget {
  const ConversionHistoryPage({super.key});

  @override
  State<ConversionHistoryPage> createState() => _ConversionHistoryPageState();
}

class _ConversionHistoryPageState extends State<ConversionHistoryPage> {
  final ConversionService _conversionService = ConversionService();
  List<Conversion> _conversions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadConversions();
  }

  Future<void> _loadConversions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _conversionService.getConversions();

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (response.success && response.conversions != null) {
            _conversions = response.conversions!;
          } else {
            _errorMessage = response.message ?? 'Failed to load conversions';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading conversions: $e';
        });
      }
    }
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
        title: const Text('Conversion History'),
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryGold,
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.errorRed.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.greyText,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadConversions,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGold,
                            foregroundColor: AppColors.darkBackground,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _conversions.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 64,
                              color: AppColors.greyText.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No conversions yet',
                              style: TextStyle(
                                color: AppColors.greyText,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Your conversion history will appear here',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.greyText,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadConversions,
                      color: AppColors.primaryGold,
                      backgroundColor: AppColors.cardBackground,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _conversions.length,
                        itemBuilder: (context, index) {
                          final conversion = _conversions[index];
                          return _buildConversionCard(conversion);
                        },
                      ),
                    ),
    );
  }

  Widget _buildConversionCard(Conversion conversion) {
    final fromColor = _getCurrencyColor(conversion.fromCurrency);
    final toColor = _getCurrencyColor(conversion.toCurrency);
    final dateFormatter = DateFormat('MMM dd, yyyy • HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status and date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: AppColors.successGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          conversion.status?.toUpperCase() ?? 'COMPLETED',
                          style: const TextStyle(
                            color: AppColors.successGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    dateFormatter.format(conversion.createdAt),
                    style: const TextStyle(
                      color: AppColors.greyText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Conversion flow
              Row(
                children: [
                  // From Currency
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: fromColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: fromColor.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'From',
                            style: TextStyle(
                              color: fromColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            conversion.fromCurrency,
                            style: TextStyle(
                              color: fromColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            conversion.formattedFromAmount,
                            style: const TextStyle(
                              color: AppColors.whiteText,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Arrow
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold,
                        borderRadius: BorderRadius.circular(8),
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
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: toColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: toColor.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'To',
                            style: TextStyle(
                              color: toColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            conversion.toCurrency,
                            style: TextStyle(
                              color: toColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            conversion.formattedToAmount,
                            style: const TextStyle(
                              color: AppColors.whiteText,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(color: AppColors.greyText, height: 1),
              const SizedBox(height: 12),

              // Exchange rate
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Exchange Rate',
                    style: TextStyle(
                      color: AppColors.greyText,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '1 ${conversion.fromCurrency} = ${conversion.formattedRate} ${conversion.toCurrency}',
                    style: const TextStyle(
                      color: AppColors.whiteText,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Fee
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Fee',
                    style: TextStyle(
                      color: AppColors.greyText,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${conversion.formattedFee} ${conversion.fromCurrency}',
                    style: const TextStyle(
                      color: AppColors.whiteText,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
