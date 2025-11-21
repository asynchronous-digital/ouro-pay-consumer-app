import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ouro_pay_consumer_app/config/app_config.dart';
import 'package:ouro_pay_consumer_app/services/auth_service.dart';

/// Wallet model
class WalletData {
  final int id;
  final String currencyCode;
  final String currencyName;
  final String currencySymbol;
  final double balance;
  final double lockedBalance;
  final double availableBalance;
  final String? status;
  final DateTime createdAt;
  final DateTime updatedAt;

  WalletData({
    required this.id,
    required this.currencyCode,
    required this.currencyName,
    required this.currencySymbol,
    required this.balance,
    required this.lockedBalance,
    required this.availableBalance,
    this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WalletData.fromJson(Map<String, dynamic> json) {
    return WalletData(
      id: json['id'] ?? 0,
      currencyCode: json['currency_code'] ?? '',
      currencyName: json['currency_name'] ?? '',
      currencySymbol: json['currency_symbol'] ?? '',
      balance: (json['balance'] ?? 0).toDouble(),
      lockedBalance: (json['locked_balance'] ?? 0).toDouble(),
      availableBalance: (json['available_balance'] ?? 0).toDouble(),
      status: json['status'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : DateTime.now(),
    );
  }

  String get formattedBalance => '$currencySymbol${balance.toStringAsFixed(2)}';
  String get formattedAvailableBalance =>
      '$currencySymbol${availableBalance.toStringAsFixed(2)}';
}

/// Response model for wallets
class WalletsResponse {
  final bool success;
  final String? message;
  final List<WalletData>? wallets;

  WalletsResponse({
    required this.success,
    this.message,
    this.wallets,
  });

  factory WalletsResponse.fromJson(Map<String, dynamic> json) {
    List<WalletData>? wallets;

    if (json['data'] != null && json['data'] is List) {
      wallets = (json['data'] as List)
          .map((wallet) => WalletData.fromJson(wallet as Map<String, dynamic>))
          .toList();
    }

    return WalletsResponse(
      success: json['success'] ?? false,
      message: json['message'],
      wallets: wallets,
    );
  }
}

/// Wallet service for managing user wallets
class WalletService {
  static final WalletService _instance = WalletService._internal();
  factory WalletService() => _instance;
  WalletService._internal();

  /// Get the full API base URL
  String get _baseUrl => AppConfig.baseUrl;

  /// Get user's wallets
  ///
  /// Makes a GET request to {{base_url}}/wallets
  /// Requires authentication token in header
  Future<WalletsResponse> getWallets() async {
    try {
      final authService = AuthService();
      final token = await authService.getToken();

      if (token == null) {
        return WalletsResponse(
          success: false,
          message: 'No authentication token found',
        );
      }

      final url = Uri.parse('$_baseUrl/wallets');

      print('🔵 GET WALLETS API CALL');
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
        return WalletsResponse(
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
        return WalletsResponse(
          success: false,
          message: 'Invalid response format from server. Please try again.',
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final walletsResponse = WalletsResponse.fromJson(responseData);
        print(
            '✅ Wallets retrieved: ${walletsResponse.wallets?.length ?? 0} wallets');
        return walletsResponse;
      } else {
        // Handle error response
        return WalletsResponse(
          success: false,
          message: responseData['message'] ??
              responseData['error'] ??
              'Failed to retrieve wallets. Please try again.',
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

      print('❌ Error fetching wallets: $e');

      return WalletsResponse(
        success: false,
        message: errorMessage,
      );
    }
  }
}
