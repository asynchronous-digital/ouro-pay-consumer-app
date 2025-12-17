import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ouro_pay_consumer_app/config/app_config.dart';
import 'package:ouro_pay_consumer_app/services/auth_service.dart';
import 'package:ouro_pay_consumer_app/models/merchant_payment_info.dart';
import 'package:ouro_pay_consumer_app/models/merchant_transaction_models.dart';
import 'package:ouro_pay_consumer_app/models/payment_history_models.dart';

class MerchantService {
  static final MerchantService _instance = MerchantService._internal();
  factory MerchantService() => _instance;
  MerchantService._internal();

  String get _baseUrl => AppConfig.baseUrl;

  /// Get merchant info by ID and currency
  /// GET {{base_url}}/payments/merchant/{{merchant_id}}?currency={{currency}}
  Future<MerchantInfoResponse> getMerchantInfo(
      int merchantId, String currency) async {
    try {
      final authService = AuthService();
      final token = await authService.getToken();

      if (token == null) {
        return MerchantInfoResponse(
          success: false,
          message: 'No authentication token found',
        );
      }

      final url = Uri.parse(
          '$_baseUrl/payments/merchant/$merchantId?currency=$currency');

      print('🔵 GET MERCHANT INFO API CALL');
      print('📍 URL: $url');

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
        return MerchantInfoResponse(
          success: false,
          message: 'Empty response from server',
        );
      }

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return MerchantInfoResponse.fromJson(responseData);
      } else {
        return MerchantInfoResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to get merchant info',
        );
      }
    } catch (e) {
      print('❌ Error fetching merchant info: $e');
      return MerchantInfoResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  /// Calculate gold required for payment
  /// POST {{base_url}}/payments/calculate
  Future<GoldCalculationResponse> calculatePayment(
      double amount, String currency, int merchantId) async {
    try {
      final authService = AuthService();
      final token = await authService.getToken();

      if (token == null) {
        return GoldCalculationResponse(
          success: false,
          message: 'No authentication token found',
        );
      }

      final url = Uri.parse('$_baseUrl/payments/calculate');
      final body = jsonEncode({
        'amount': amount,
        'currency': currency,
        'merchant_id': merchantId,
      });

      print('🔵 CALCULATE PAYMENT API CALL');
      print('📍 URL: $url');
      print('📦 Body: $body');

      final response = await http
          .post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      )
          .timeout(
        AppConfig.connectionTimeout,
        onTimeout: () {
          throw Exception(
              'Connection timeout. Please check your internet connection.');
        },
      );

      print('📥 Response Status Code: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.body.isEmpty) {
        return GoldCalculationResponse(
          success: false,
          message: 'Empty response from server',
        );
      }

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      return GoldCalculationResponse.fromJson(responseData);
    } catch (e) {
      print('❌ Error calculating payment: $e');
      return GoldCalculationResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  /// Confirm and pay merchant
  /// POST {{base_url}}/payments/pay-merchant
  Future<MerchantPaymentResponse> payMerchant({
    required int merchantId,
    required double amount,
    required String currency,
    required double confirmGoldAmount,
  }) async {
    try {
      final authService = AuthService();
      final token = await authService.getToken();

      if (token == null) {
        return MerchantPaymentResponse(
          success: false,
          message: 'No authentication token found',
        );
      }

      final url = Uri.parse('$_baseUrl/payments/pay-merchant');
      final body = jsonEncode({
        'merchant_id': merchantId,
        'amount': amount,
        'currency': currency,
        'confirm_gold_amount': confirmGoldAmount,
      });

      print('🔵 PAY MERCHANT API CALL');
      print('📍 URL: $url');
      print('📦 Body: $body');

      final response = await http
          .post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      )
          .timeout(
        AppConfig.connectionTimeout,
        onTimeout: () {
          throw Exception(
              'Connection timeout. Please check your internet connection.');
        },
      );

      print('📥 Response Status Code: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.body.isEmpty) {
        return MerchantPaymentResponse(
          success: false,
          message: 'Empty response from server',
        );
      }

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      return MerchantPaymentResponse.fromJson(responseData);
    } catch (e) {
      print('❌ Error paying merchant: $e');
      return MerchantPaymentResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  /// Get payment history
  /// GET {{base_url}}/payments/history?per_page=15
  Future<PaymentHistoryResponse> getPaymentHistory({int perPage = 15}) async {
    try {
      final authService = AuthService();
      final token = await authService.getToken();

      if (token == null) {
        return PaymentHistoryResponse(
          success: false,
          message: 'No authentication token found',
        );
      }

      final url = Uri.parse('$_baseUrl/payments/history?per_page=$perPage');

      print('🔵 GET PAYMENT HISTORY API CALL');
      print('📍 URL: $url');

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
      // Truncate long response for logging
      final bodyToLog = response.body.length > 500
          ? '${response.body.substring(0, 500)}...'
          : response.body;
      print('📥 Response Body: $bodyToLog');

      if (response.body.isEmpty) {
        return PaymentHistoryResponse(
          success: false,
          message: 'Empty response from server',
        );
      }

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      return PaymentHistoryResponse.fromJson(responseData);
    } catch (e) {
      print('❌ Error fetching payment history: $e');
      return PaymentHistoryResponse(
        success: false,
        message: e.toString(),
      );
    }
  }
}
