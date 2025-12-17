class MerchantInfoResponse {
  final bool success;
  final String? message;
  final MerchantPaymentInfo? data;

  MerchantInfoResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory MerchantInfoResponse.fromJson(Map<String, dynamic> json) {
    return MerchantInfoResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null
          ? MerchantPaymentInfo.fromJson(json['data'])
          : null,
    );
  }
}

class MerchantPaymentInfo {
  final MerchantDetails merchant;
  final ConsumerBalance consumerBalance;
  final GoldPrice goldPrice;

  MerchantPaymentInfo({
    required this.merchant,
    required this.consumerBalance,
    required this.goldPrice,
  });

  factory MerchantPaymentInfo.fromJson(Map<String, dynamic> json) {
    return MerchantPaymentInfo(
      merchant: MerchantDetails.fromJson(json['merchant']),
      consumerBalance: ConsumerBalance.fromJson(json['consumer_balance']),
      goldPrice: GoldPrice.fromJson(json['gold_price']),
    );
  }
}

class MerchantDetails {
  final int id;
  final String name;
  final String? logoUrl;
  final String currency;
  final String currencySymbol;

  MerchantDetails({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.currency,
    required this.currencySymbol,
  });

  factory MerchantDetails.fromJson(Map<String, dynamic> json) {
    return MerchantDetails(
      id: json['id'],
      name: json['name'],
      logoUrl: json['logo_url'],
      currency: json['currency'],
      currencySymbol: json['currency_symbol'],
    );
  }
}

class ConsumerBalance {
  final double totalGoldGrams;

  ConsumerBalance({required this.totalGoldGrams});

  factory ConsumerBalance.fromJson(Map<String, dynamic> json) {
    return ConsumerBalance(
      totalGoldGrams: (json['total_gold_grams'] as num).toDouble(),
    );
  }
}

class GoldPrice {
  final double pricePerGram;
  final double sellPricePerGram;

  GoldPrice({
    required this.pricePerGram,
    required this.sellPricePerGram,
  });

  factory GoldPrice.fromJson(Map<String, dynamic> json) {
    return GoldPrice(
      pricePerGram: (json['price_per_gram'] as num).toDouble(),
      sellPricePerGram: (json['sell_price_per_gram'] as num).toDouble(),
    );
  }
}
