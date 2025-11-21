import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ouro_pay_consumer_app/config/app_config.dart';
import 'package:ouro_pay_consumer_app/services/auth_service.dart';

/// Gold holdings data model
class GoldHoldingsData {
  final double totalGrams;
  final Map<String, double> currentValues;
  final Map<String, double> totalProfitLoss;
  final List<dynamic> investmentsByCurrency;

  GoldHoldingsData({
    required this.totalGrams,
    required this.currentValues,
    required this.totalProfitLoss,
    required this.investmentsByCurrency,
  });

  factory GoldHoldingsData.fromJson(Map<String, dynamic> json) {
    return GoldHoldingsData(
      totalGrams: (json['total_grams'] ?? 0).toDouble(),
      currentValues: {
        'eur': (json['current_values']?['eur'] ?? 0).toDouble(),
        'usd': (json['current_values']?['usd'] ?? 0).toDouble(),
        'srd': (json['current_values']?['srd'] ?? 0).toDouble(),
      },
      totalProfitLoss: {
        'eur': (json['total_profit_loss']?['eur'] ?? 0).toDouble(),
        'usd': (json['total_profit_loss']?['usd'] ?? 0).toDouble(),
        'srd': (json['total_profit_loss']?['srd'] ?? 0).toDouble(),
      },
      investmentsByCurrency: json['investments_by_currency'] ?? [],
    );
  }

  String getFormattedValue(String currency) {
    final value = currentValues[currency.toLowerCase()] ?? 0;
    String symbol;
    switch (currency.toUpperCase()) {
      case 'EUR':
        symbol = '€';
        break;
      case 'USD':
        symbol = '\$';
        break;
      case 'SRD':
        symbol = 'Sr\$';
        break;
      default:
        symbol = '\$';
    }
    return '$symbol${value.toStringAsFixed(2)}';
  }

  String getFormattedProfitLoss(String currency) {
    final value = totalProfitLoss[currency.toLowerCase()] ?? 0;
    String symbol;
    switch (currency.toUpperCase()) {
      case 'EUR':
        symbol = '€';
        break;
      case 'USD':
        symbol = '\$';
        break;
      case 'SRD':
        symbol = 'Sr\$';
        break;
      default:
        symbol = '\$';
    }
    final prefix = value >= 0 ? '+' : '';
    return '$prefix$symbol${value.toStringAsFixed(2)}';
  }
}

/// Response model for gold holdings
class GoldHoldingsResponse {
  final bool success;
  final String? message;
  final GoldHoldingsData? data;

  GoldHoldingsResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory GoldHoldingsResponse.fromJson(Map<String, dynamic> json) {
    GoldHoldingsData? data;

    if (json['data'] != null && json['data'] is Map) {
      data = GoldHoldingsData.fromJson(json['data'] as Map<String, dynamic>);
    }

    return GoldHoldingsResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: data,
    );
  }
}

/// Gold service for managing gold holdings
class GoldService {
  static final GoldService _instance = GoldService._internal();
  factory GoldService() => _instance;
  GoldService._internal();

  /// Get the full API base URL
  String get _baseUrl => AppConfig.baseUrl;

  /// Get user's gold holdings
  ///
  /// Makes a GET request to {{base_url}}/gold/holdings
  /// Requires authentication token in header
  Future<GoldHoldingsResponse> getGoldHoldings() async {
    try {
      final authService = AuthService();
      final token = await authService.getToken();

      if (token == null) {
        return GoldHoldingsResponse(
          success: false,
          message: 'No authentication token found',
        );
      }

      final url = Uri.parse('$_baseUrl/gold/holdings');

      print('🔵 GET GOLD HOLDINGS API CALL');
      print('📍 URL: $url');
      print('🔑 Token: ${token.substring(0, 20)}...');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        AppConfig.connectionTimeout,
        onTimeout: () {
          throw Exception(
              'Connection timeout. Please check your internet connection.');
        },
      );

      print('📥 Response Status Code: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      // Handle empty response body
      if (response.body.isEmpty) {
        return GoldHoldingsResponse(
          success: false,
          message: 'Empty response from server. Please try again.',
        );
      }

      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
        print('📋 Parsed Response Data: $responseData');
      } catch (e) {
        print('❌ Failed to parse response: $e');
        return GoldHoldingsResponse(
          success: false,
          message: 'Invalid response format from server. Please try again.',
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final goldResponse = GoldHoldingsResponse.fromJson(responseData);
        print(
            '✅ Gold holdings retrieved: ${goldResponse.data?.totalGrams ?? 0} grams');
        return goldResponse;
      } else {
        // Handle error response
        return GoldHoldingsResponse(
          success: false,
          message: responseData['message'] ??
              responseData['error'] ??
              'Failed to retrieve gold holdings. Please try again.',
        );
      }
    } catch (e) {
      // Handle network errors, timeouts, etc.
      String errorMessage = 'An error occurred. Please try again.';

      if (e.toString().contains('timeout')) {
        errorMessage =
            'Connection timeout. Please check your internet connection.';
      } else if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        errorMessage = 'No internet connection. Please check your network.';
      } else if (e.toString().contains('FormatException')) {
        errorMessage = 'Invalid response from server. Please try again.';
      }

      print('❌ Error fetching gold holdings: $e');

      return GoldHoldingsResponse(
        success: false,
        message: errorMessage,
      );
    }
  }

  /// Get gold price for a specific currency
  ///
  /// Makes a GET request to {{base_url}}/gold/price?currency={currency}
  /// Requires authentication token in header
  Future<GoldPriceResponse> getGoldPrice(String currency) async {
    try {
      final authService = AuthService();
      final token = await authService.getToken();

      if (token == null) {
        return GoldPriceResponse(
          success: false,
          message: 'No authentication token found',
        );
      }

      final url = Uri.parse('$_baseUrl/gold/price?currency=$currency');

      print('🔵 GET GOLD PRICE API CALL');
      print('📍 URL: $url');
      print('💱 Currency: $currency');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        AppConfig.connectionTimeout,
        onTimeout: () {
          throw Exception(
              'Connection timeout. Please check your internet connection.');
        },
      );

      print('📥 Response Status Code: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.body.isEmpty) {
        return GoldPriceResponse(
          success: false,
          message: 'Empty response from server. Please try again.',
        );
      }

      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
        print('📋 Parsed Response Data: $responseData');
      } catch (e) {
        print('❌ Failed to parse response: $e');
        return GoldPriceResponse(
          success: false,
          message: 'Invalid response format from server. Please try again.',
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final priceResponse = GoldPriceResponse.fromJson(responseData);
        print(
            '✅ Gold price retrieved: ${priceResponse.data?.buyPrice ?? 0} ${priceResponse.data?.currency ?? currency}');
        return priceResponse;
      } else {
        return GoldPriceResponse(
          success: false,
          message: responseData['message'] ??
              responseData['error'] ??
              'Failed to retrieve gold price. Please try again.',
        );
      }
    } catch (e) {
      String errorMessage = 'An error occurred. Please try again.';

      if (e.toString().contains('timeout')) {
        errorMessage =
            'Connection timeout. Please check your internet connection.';
      } else if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        errorMessage = 'No internet connection. Please check your network.';
      } else if (e.toString().contains('FormatException')) {
        errorMessage = 'Invalid response from server. Please try again.';
      }

      print('❌ Error fetching gold price: $e');

      return GoldPriceResponse(
        success: false,
        message: errorMessage,
      );
    }
  }

  // ---------------------------------------------------------------------
  // BUY GOLD
  // ---------------------------------------------------------------------
  /// Buy gold for a specific currency and amount (grams)
  /// POST {{base_url}}/gold/buy with body {"grams":..., "currency_code":...}
  Future<GoldActionResponse> buyGold(
      {required String currency, required double grams}) async {
    try {
      final authService = AuthService();
      final token = await authService.getToken();
      if (token == null) {
        return GoldActionResponse(
            success: false, message: 'No authentication token found');
      }
      final url = Uri.parse('$_baseUrl/gold/buy');
      final body = jsonEncode({'grams': grams, 'currency_code': currency});
      final response = await http
          .post(url,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: body)
          .timeout(AppConfig.connectionTimeout, onTimeout: () {
        throw Exception(
            'Connection timeout. Please check your internet connection.');
      });

      if (response.body.isEmpty) {
        return GoldActionResponse(
            success: false, message: 'Empty response from server');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return GoldActionResponse(
        success: data['success'] ?? false,
        message: data['message'] ?? 'Buy gold request completed',
      );
    } catch (e) {
      return GoldActionResponse(success: false, message: e.toString());
    }
  }

  // ---------------------------------------------------------------------
  // SELL GOLD
  // ---------------------------------------------------------------------
  /// Sell gold for a specific currency and amount (grams)
  /// POST {{base_url}}/gold/sell with body {"grams":..., "currency_code":...}
  Future<GoldActionResponse> sellGold(
      {required String currency, required double grams}) async {
    try {
      final authService = AuthService();
      final token = await authService.getToken();
      if (token == null) {
        return GoldActionResponse(
            success: false, message: 'No authentication token found');
      }
      final url = Uri.parse('$_baseUrl/gold/sell');
      final body = jsonEncode({'grams': grams, 'currency_code': currency});
      final response = await http
          .post(url,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: body)
          .timeout(AppConfig.connectionTimeout, onTimeout: () {
        throw Exception(
            'Connection timeout. Please check your internet connection.');
      });

      if (response.body.isEmpty) {
        return GoldActionResponse(
            success: false, message: 'Empty response from server');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return GoldActionResponse(
        success: data['success'] ?? false,
        message: data['message'] ?? 'Sell gold request completed',
      );
    } catch (e) {
      return GoldActionResponse(success: false, message: e.toString());
    }
  }

  // ---------------------------------------------------------------------
  // FETCH TRANSACTIONS
  // ---------------------------------------------------------------------
  /// Retrieve gold transaction history
  /// GET {{base_url}}/gold/transactions
  Future<GoldTransactionsResponse> getGoldTransactions() async {
    try {
      final authService = AuthService();
      final token = await authService.getToken();
      if (token == null) {
        return GoldTransactionsResponse(
            success: false, message: 'No authentication token found');
      }
      final url = Uri.parse('$_baseUrl/gold/transactions');
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      }).timeout(AppConfig.connectionTimeout, onTimeout: () {
        throw Exception(
            'Connection timeout. Please check your internet connection.');
      });

      if (response.body.isEmpty) {
        return GoldTransactionsResponse(
            success: false, message: 'Empty response from server');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return GoldTransactionsResponse.fromJson(data);
    } catch (e) {
      return GoldTransactionsResponse(success: false, message: e.toString());
    }
  }
}

/// Gold price data model
class GoldPriceData {
  final String currency;
  final double basePrice;
  final double buyPrice;
  final double sellPrice;
  final double buySpreadPercentage;
  final double sellSpreadPercentage;
  final String updatedAt;

  GoldPriceData({
    required this.currency,
    required this.basePrice,
    required this.buyPrice,
    required this.sellPrice,
    required this.buySpreadPercentage,
    required this.sellSpreadPercentage,
    required this.updatedAt,
  });

  factory GoldPriceData.fromJson(Map<String, dynamic> json) {
    return GoldPriceData(
      currency: json['currency'] ?? '',
      basePrice: (json['base_price'] ?? 0).toDouble(),
      buyPrice: (json['buy_price'] ?? 0).toDouble(),
      sellPrice: (json['sell_price'] ?? 0).toDouble(),
      buySpreadPercentage: (json['buy_spread_percentage'] ?? 0).toDouble(),
      sellSpreadPercentage: (json['sell_spread_percentage'] ?? 0).toDouble(),
      updatedAt: json['updated_at'] ?? '',
    );
  }

  String getFormattedBuyPrice() {
    String symbol;
    switch (currency.toUpperCase()) {
      case 'EUR':
        symbol = '€';
        break;
      case 'USD':
        symbol = '\$';
        break;
      case 'SRD':
        symbol = 'Sr\$';
        break;
      default:
        symbol = '\$';
    }
    return '$symbol${buyPrice.toStringAsFixed(2)}';
  }

  String getFormattedSellPrice() {
    String symbol;
    switch (currency.toUpperCase()) {
      case 'EUR':
        symbol = '€';
        break;
      case 'USD':
        symbol = '\$';
        break;
      case 'SRD':
        symbol = 'Sr\$';
        break;
      default:
        symbol = '\$';
    }
    return '$symbol${sellPrice.toStringAsFixed(2)}';
  }
}

/// Response model for gold price
class GoldPriceResponse {
  final bool success;
  final String? message;
  final GoldPriceData? data;

  GoldPriceResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory GoldPriceResponse.fromJson(Map<String, dynamic> json) {
    GoldPriceData? data;

    if (json['data'] != null && json['data'] is Map) {
      data = GoldPriceData.fromJson(json['data'] as Map<String, dynamic>);
    }

    return GoldPriceResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: data,
    );
  }
}

// ---------- Top-level response models ----------
class GoldActionResponse {
  final bool success;
  final String? message;
  GoldActionResponse({required this.success, this.message});
}

class GoldTransactionsResponse {
  final bool success;
  final String? message;
  final List<dynamic>? data; // raw list of transactions
  GoldTransactionsResponse({required this.success, this.message, this.data});
  factory GoldTransactionsResponse.fromJson(Map<String, dynamic> json) {
    return GoldTransactionsResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data']?['data'] as List<dynamic>?,
    );
  }
}
