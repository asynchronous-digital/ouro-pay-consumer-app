class GoldCalculationResponse {
  final bool success;
  final String? message;
  final GoldCalculationData? data;

  GoldCalculationResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory GoldCalculationResponse.fromJson(Map<String, dynamic> json) {
    return GoldCalculationResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null
          ? GoldCalculationData.fromJson(json['data'])
          : null,
    );
  }
}

class GoldCalculationData {
  final double fiatAmount;
  final String currency;
  final double goldRequired;
  final double goldPricePerGram;
  final bool sufficientBalance;
  final double consumerGoldBalance;
  final String priceValidUntil;

  GoldCalculationData({
    required this.fiatAmount,
    required this.currency,
    required this.goldRequired,
    required this.goldPricePerGram,
    required this.sufficientBalance,
    required this.consumerGoldBalance,
    required this.priceValidUntil,
  });

  factory GoldCalculationData.fromJson(Map<String, dynamic> json) {
    return GoldCalculationData(
      fiatAmount: (json['fiat_amount'] as num).toDouble(),
      currency: json['currency'],
      goldRequired: (json['gold_required'] as num).toDouble(),
      goldPricePerGram: (json['gold_price_per_gram'] as num).toDouble(),
      sufficientBalance: json['sufficient_balance'] ?? false,
      consumerGoldBalance: (json['consumer_gold_balance'] as num).toDouble(),
      priceValidUntil: json['price_valid_until'],
    );
  }
}

class MerchantPaymentResponse {
  final bool success;
  final String? message;
  final Map<String, dynamic>? data;

  MerchantPaymentResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory MerchantPaymentResponse.fromJson(Map<String, dynamic> json) {
    return MerchantPaymentResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'],
    );
  }
}
