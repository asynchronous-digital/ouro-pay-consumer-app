import 'dart:convert';
import 'package:ouro_pay_consumer_app/services/http_service.dart';
import 'package:ouro_pay_consumer_app/models/deposit.dart';
import 'package:ouro_pay_consumer_app/services/auth_service.dart';

class DepositResponse {
  final bool success;
  final String message;
  final Deposit? data;
  final String? clientSecret;

  DepositResponse({
    required this.success,
    required this.message,
    this.data,
    this.clientSecret,
  });

  factory DepositResponse.fromJson(Map<String, dynamic> json) {
    // Backend returns client_secret at data.client_secret
    String? secret;
    Deposit? deposit;

    if (json['data'] != null) {
      // Get client_secret from data level
      if (json['data']['client_secret'] != null) {
        secret = json['data']['client_secret'];
      }

      // Get deposit from data.deposit
      if (json['data']['deposit'] != null) {
        deposit = Deposit.fromJson(json['data']['deposit']);
      } else if (json['data']['id'] != null) {
        // Fallback: if deposit data is directly in data object
        deposit = Deposit.fromJson(json['data']);
      }
    }

    return DepositResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: deposit,
      clientSecret: secret,
    );
  }
}

class DepositListResponse {
  final bool success;
  final String message;
  final List<Deposit>? deposits;
  final Map<String, dynamic>? meta;

  DepositListResponse({
    required this.success,
    required this.message,
    this.deposits,
    this.meta,
  });

  factory DepositListResponse.fromJson(Map<String, dynamic> json) {
    List<Deposit>? depositList;
    if (json['data'] != null && json['data']['data'] != null) {
      depositList = (json['data']['data'] as List)
          .map((item) => Deposit.fromJson(item))
          .toList();
    }

    return DepositListResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      deposits: depositList,
      meta: json['data']?['meta'],
    );
  }
}

class DepositService {
  final String baseUrl = 'http://64.225.108.213/api/v1';
  final AuthService authService = AuthService();

  /// Create a new deposit request
  /// POST /deposits
  Future<DepositResponse> createDeposit(DepositRequest request) async {
    try {
      final token = await authService.getToken();

      if (token == null) {
        return DepositResponse(
          success: false,
          message: 'No authentication token found',
        );
      }

      print('💰 Creating deposit: ${request.currencyCode} ${request.amount}');

      final response = await HttpService.post(
        Uri.parse('$baseUrl/deposits'),
        body: jsonEncode(request.toJson()),
      );

      print('📥 Response Status Code: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final depositResponse = DepositResponse.fromJson(jsonResponse);
        print('✅ Deposit created: ${depositResponse.data?.reference}');
        return depositResponse;
      } else {
        print('❌ Failed to create deposit: ${response.statusCode}');
        return DepositResponse(
          success: false,
          message: jsonResponse['message'] ?? 'Failed to create deposit',
        );
      }
    } catch (e) {
      print('❌ Error creating deposit: $e');
      return DepositResponse(
        success: false,
        message: 'Error creating deposit: $e',
      );
    }
  }

  /// Get deposit history for a specific currency
  /// GET /deposits?currency={currency}
  Future<DepositListResponse> getDeposits({String? currency}) async {
    try {
      final token = await authService.getToken();

      if (token == null) {
        return DepositListResponse(
          success: false,
          message: 'No authentication token found',
        );
      }

      final uri = currency != null
          ? Uri.parse('$baseUrl/deposits?currency=$currency')
          : Uri.parse('$baseUrl/deposits');

      print('📋 Fetching deposits${currency != null ? ' for $currency' : ''}');

      final response = await HttpService.get(uri);

      print('📥 Response Status Code: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final depositListResponse = DepositListResponse.fromJson(jsonResponse);
        print(
            '✅ Deposits retrieved: ${depositListResponse.deposits?.length ?? 0} deposits');
        return depositListResponse;
      } else {
        print('❌ Failed to get deposits: ${response.statusCode}');
        return DepositListResponse(
          success: false,
          message: jsonResponse['message'] ?? 'Failed to get deposits',
        );
      }
    } catch (e) {
      print('❌ Error getting deposits: $e');
      return DepositListResponse(
        success: false,
        message: 'Error getting deposits: $e',
      );
    }
  }
}
