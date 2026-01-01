import 'dart:convert';
import 'package:ouro_pay_consumer_app/services/http_service.dart';
import 'package:ouro_pay_consumer_app/config/app_config.dart';
import 'package:ouro_pay_consumer_app/models/conversion.dart';
import 'package:ouro_pay_consumer_app/services/auth_service.dart';

/// Conversion service for currency exchange operations
class ConversionService {
  static final ConversionService _instance = ConversionService._internal();
  factory ConversionService() => _instance;
  ConversionService._internal();

  final AuthService _authService = AuthService();

  /// Get the full API base URL
  String get _baseUrl => AppConfig.baseUrl;

  /// Get exchange rate between two currencies
  ///
  /// Makes a GET request to {{base_url}}/exchange-rates?from={from}&to={to}
  /// Requires authentication token in header
  Future<ExchangeRatesResponse> getExchangeRates({
    required String fromCurrency,
    required String toCurrency,
  }) async {
    try {
      final token = await _authService.getToken();

      if (token == null) {
        return ExchangeRatesResponse(
          success: false,
          message: 'No authentication token found',
        );
      }

      final url = Uri.parse(
          '$_baseUrl/exchange-rates?from=$fromCurrency&to=$toCurrency');

      print('💱 GET EXCHANGE RATES API CALL');
      print('📍 URL: $url');
      print('🔑 Token: ${token.substring(0, 20)}...');

      final response = await HttpService.get(url);

      print('📥 Response Status Code: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.body.isEmpty) {
        return ExchangeRatesResponse(
          success: false,
          message: 'Empty response from server. Please try again.',
        );
      }

      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        print('❌ Failed to parse response: $e');
        return ExchangeRatesResponse(
          success: false,
          message: 'Invalid response format from server. Please try again.',
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final exchangeRatesResponse = ExchangeRatesResponse.fromJson(
            responseData, fromCurrency, toCurrency);
        print('✅ Exchange rate retrieved: ${exchangeRatesResponse.data?.rate}');
        return exchangeRatesResponse;
      } else {
        return ExchangeRatesResponse(
          success: false,
          message: responseData['message'] ??
              responseData['error'] ??
              'Failed to retrieve exchange rates. Please try again.',
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

      print('❌ Error fetching exchange rates: $e');

      return ExchangeRatesResponse(
        success: false,
        message: errorMessage,
      );
    }
  }

  /// Convert currency
  ///
  /// Makes a POST request to {{base_url}}/conversions
  /// Requires authentication token in header
  Future<ConversionResponse> convertCurrency(ConversionRequest request) async {
    try {
      final token = await _authService.getToken();

      if (token == null) {
        return ConversionResponse(
          success: false,
          message: 'No authentication token found',
        );
      }

      final url = Uri.parse('$_baseUrl/conversions');

      print('💱 CONVERT CURRENCY API CALL');
      print('📍 URL: $url');
      print('📤 Request Body: ${jsonEncode(request.toJson())}');
      print('🔑 Token: ${token.substring(0, 20)}...');

      final response = await HttpService.post(
        url,
        body: jsonEncode(request.toJson()),
      );

      print('📥 Response Status Code: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.body.isEmpty) {
        return ConversionResponse(
          success: false,
          message: 'Empty response from server. Please try again.',
        );
      }

      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        print('❌ Failed to parse response: $e');
        return ConversionResponse(
          success: false,
          message: 'Invalid response format from server. Please try again.',
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final conversionResponse = ConversionResponse.fromJson(responseData);
        print('✅ Conversion successful: ${conversionResponse.data?.id}');
        return conversionResponse;
      } else {
        return ConversionResponse(
          success: false,
          message: responseData['message'] ??
              responseData['error'] ??
              'Failed to convert currency. Please try again.',
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

      print('❌ Error converting currency: $e');

      return ConversionResponse(
        success: false,
        message: errorMessage,
      );
    }
  }

  /// Get conversion history
  ///
  /// Makes a GET request to {{base_url}}/conversions
  /// Requires authentication token in header
  Future<ConversionListResponse> getConversions() async {
    try {
      final token = await _authService.getToken();

      if (token == null) {
        return ConversionListResponse(
          success: false,
          message: 'No authentication token found',
        );
      }

      final url = Uri.parse('$_baseUrl/conversions');

      print('📋 GET CONVERSIONS HISTORY API CALL');
      print('📍 URL: $url');
      print('🔑 Token: ${token.substring(0, 20)}...');

      final response = await HttpService.get(url);

      print('📥 Response Status Code: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.body.isEmpty) {
        return ConversionListResponse(
          success: false,
          message: 'Empty response from server. Please try again.',
        );
      }

      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        print('❌ Failed to parse response: $e');
        return ConversionListResponse(
          success: false,
          message: 'Invalid response format from server. Please try again.',
        );
      }

      if (response.statusCode == 200) {
        final conversionListResponse =
            ConversionListResponse.fromJson(responseData);
        print(
            '✅ Conversions retrieved: ${conversionListResponse.conversions?.length ?? 0} conversions');
        return conversionListResponse;
      } else {
        return ConversionListResponse(
          success: false,
          message: responseData['message'] ??
              responseData['error'] ??
              'Failed to retrieve conversions. Please try again.',
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

      print('❌ Error fetching conversions: $e');

      return ConversionListResponse(
        success: false,
        message: errorMessage,
      );
    }
  }
}
