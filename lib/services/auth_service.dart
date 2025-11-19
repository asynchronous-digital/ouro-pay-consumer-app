import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ouro_pay_consumer_app/config/app_config.dart';

/// Response model for login
class LoginResponse {
  final bool success;
  final String? token;
  final Map<String, dynamic>? user;
  final String? message;
  final Map<String, dynamic>? data;

  LoginResponse({
    required this.success,
    this.token,
    this.user,
    this.message,
    this.data,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? false,
      token: json['token'] ?? json['data']?['token'],
      user: json['user'] ?? json['data']?['user'],
      message: json['message'] ?? json['error'],
      data: json['data'],
    );
  }
}

/// Authentication service for handling login and authentication
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// Get the full API base URL
  String get _baseUrl => AppConfig.baseUrl;

  /// Login with email and password
  /// 
  /// Makes a POST request to {{base_url}}/auth/login
  /// Expected request body: { "email": "...", "password": "..." }
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/auth/login');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(
        AppConfig.connectionTimeout,
        onTimeout: () {
          throw Exception('Connection timeout. Please check your internet connection.');
        },
      );

      // Handle empty response body
      if (response.body.isEmpty) {
        return LoginResponse(
          success: false,
          message: 'Empty response from server. Please try again.',
        );
      }

      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        return LoginResponse(
          success: false,
          message: 'Invalid response format from server. Please try again.',
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return LoginResponse.fromJson(responseData);
      } else {
        // Handle error response
        return LoginResponse(
          success: false,
          message: responseData['message'] ?? 
                   responseData['error'] ?? 
                   'Login failed. Please try again.',
        );
      }
    } catch (e) {
      // Handle network errors, timeouts, etc.
      String errorMessage = 'An error occurred. Please try again.';
      
      if (e.toString().contains('timeout')) {
        errorMessage = 'Connection timeout. Please check your internet connection.';
      } else if (e.toString().contains('SocketException') || 
                 e.toString().contains('Failed host lookup')) {
        errorMessage = 'No internet connection. Please check your network.';
      } else if (e.toString().contains('FormatException')) {
        errorMessage = 'Invalid response from server. Please try again.';
      }
      
      return LoginResponse(
        success: false,
        message: errorMessage,
      );
    }
  }

  /// Get stored authentication token
  String? getToken() {
    // TODO: Implement token storage (SharedPreferences, secure storage, etc.)
    return null;
  }

  /// Save authentication token
  Future<void> saveToken(String token) async {
    // TODO: Implement token storage (SharedPreferences, secure storage, etc.)
  }

  /// Clear authentication token
  Future<void> clearToken() async {
    // TODO: Implement token clearing
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    final token = getToken();
    return token != null && token.isNotEmpty;
  }
}

