/// Exchange rate model
class ExchangeRate {
  final String fromCurrency;
  final String toCurrency;
  final double rate;
  final DateTime timestamp;

  ExchangeRate({
    required this.fromCurrency,
    required this.toCurrency,
    required this.rate,
    required this.timestamp,
  });

  factory ExchangeRate.fromJson(Map<String, dynamic> json) {
    return ExchangeRate(
      fromCurrency: json['from_currency'] ?? '',
      toCurrency: json['to_currency'] ?? '',
      rate: (json['rate'] ?? 0).toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'].toString())
          : DateTime.now(),
    );
  }
}

/// Response model for exchange rates API
class ExchangeRatesResponse {
  final bool success;
  final String? message;
  final ExchangeRate? data;

  ExchangeRatesResponse({
    required this.success,
    this.message,
    this.data,
  });

  /// Parse the nested exchange rates response
  /// The API returns all rates in format: data[fromCurrency][toCurrency]
  factory ExchangeRatesResponse.fromJson(
    Map<String, dynamic> json,
    String fromCurrency,
    String toCurrency,
  ) {
    ExchangeRate? exchangeRate;

    if (json['data'] != null && json['data'] is Map) {
      final data = json['data'] as Map<String, dynamic>;

      // Navigate to data[fromCurrency][toCurrency]
      if (data[fromCurrency] != null && data[fromCurrency] is Map) {
        final fromRates = data[fromCurrency] as Map<String, dynamic>;

        if (fromRates[toCurrency] != null && fromRates[toCurrency] is Map) {
          final rateData = fromRates[toCurrency] as Map<String, dynamic>;

          exchangeRate = ExchangeRate(
            fromCurrency: fromCurrency,
            toCurrency: toCurrency,
            rate: (rateData['rate'] ?? 0).toDouble(),
            timestamp: rateData['updated_at'] != null
                ? DateTime.parse(rateData['updated_at'].toString())
                : DateTime.now(),
          );
        }
      }
    }

    return ExchangeRatesResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: exchangeRate,
    );
  }
}

/// Request model for currency conversion
class ConversionRequest {
  final String fromCurrency;
  final String toCurrency;
  final double amount;

  ConversionRequest({
    required this.fromCurrency,
    required this.toCurrency,
    required this.amount,
  });

  Map<String, dynamic> toJson() {
    return {
      'from_currency': fromCurrency,
      'to_currency': toCurrency,
      'amount': amount,
    };
  }
}

/// Conversion transaction model
class Conversion {
  final int id;
  final String fromCurrency;
  final String toCurrency;
  final double fromAmount;
  final double toAmount;
  final double rate;
  final double fee;
  final String? status;
  final DateTime createdAt;

  Conversion({
    required this.id,
    required this.fromCurrency,
    required this.toCurrency,
    required this.fromAmount,
    required this.toAmount,
    required this.rate,
    required this.fee,
    this.status,
    required this.createdAt,
  });

  factory Conversion.fromJson(Map<String, dynamic> json) {
    return Conversion(
      id: json['id'] ?? 0,
      fromCurrency: json['from_currency'] ?? '',
      toCurrency: json['to_currency'] ?? '',
      fromAmount: (json['from_amount'] ?? 0).toDouble(),
      toAmount: (json['to_amount'] ?? 0).toDouble(),
      rate: (json['exchange_rate'] ?? json['rate'] ?? 0).toDouble(),
      fee: (json['fee'] ?? 0).toDouble(),
      status: json['status'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  String get formattedFromAmount => fromAmount.toStringAsFixed(2);
  String get formattedToAmount => toAmount.toStringAsFixed(2);
  String get formattedRate => rate.toStringAsFixed(4);
  String get formattedFee => fee.toStringAsFixed(2);
}

/// Response model for conversion API
class ConversionResponse {
  final bool success;
  final String? message;
  final Conversion? data;

  ConversionResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory ConversionResponse.fromJson(Map<String, dynamic> json) {
    return ConversionResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null
          ? Conversion.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Response model for conversion history list
class ConversionListResponse {
  final bool success;
  final String? message;
  final List<Conversion>? conversions;
  final Map<String, dynamic>? meta;

  ConversionListResponse({
    required this.success,
    this.message,
    this.conversions,
    this.meta,
  });

  factory ConversionListResponse.fromJson(Map<String, dynamic> json) {
    List<Conversion>? conversionList;

    if (json['data'] != null) {
      if (json['data'] is List) {
        conversionList = (json['data'] as List)
            .map((item) => Conversion.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (json['data']['data'] != null && json['data']['data'] is List) {
        conversionList = (json['data']['data'] as List)
            .map((item) => Conversion.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    }

    return ConversionListResponse(
      success: json['success'] ?? false,
      message: json['message'],
      conversions: conversionList,
      meta: json['data'] is Map
          ? (json['data'] as Map<String, dynamic>)['meta']
          : null,
    );
  }
}
