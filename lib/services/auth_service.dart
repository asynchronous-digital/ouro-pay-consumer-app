import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ouro_pay_consumer_app/config/app_config.dart';
import 'package:ouro_pay_consumer_app/models/user.dart';

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

/// Response model for registration
class RegisterResponse {
  final bool success;
  final String? token;
  final Map<String, dynamic>? user;
  final String? message;
  final Map<String, dynamic>? data;
  final Map<String, String>? fieldErrors; // Field-specific validation errors

  RegisterResponse({
    required this.success,
    this.token,
    this.user,
    this.message,
    this.data,
    this.fieldErrors,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    // Parse field-specific errors from various possible formats
    Map<String, String>? fieldErrors;
    
    if (json['errors'] != null) {
      if (json['errors'] is Map) {
        fieldErrors = {};
        (json['errors'] as Map).forEach((key, value) {
          if (value is String) {
            fieldErrors![key.toString()] = value;
          } else if (value is List && value.isNotEmpty) {
            fieldErrors![key.toString()] = value[0].toString();
          }
        });
      }
    } else if (json['validation'] != null && json['validation'] is Map) {
      fieldErrors = {};
      (json['validation'] as Map).forEach((key, value) {
        if (value is String) {
          fieldErrors![key.toString()] = value;
        } else if (value is List && value.isNotEmpty) {
          fieldErrors![key.toString()] = value[0].toString();
        }
      });
    }
    
    // Print parsed field errors for debugging
    if (fieldErrors != null && fieldErrors.isNotEmpty) {
      print('🔴 Parsed Field Errors: $fieldErrors');
    }
    
    return RegisterResponse(
      success: json['success'] ?? false,
      token: json['token'] ?? json['data']?['token'],
      user: json['user'] ?? json['data']?['user'],
      message: json['message'] ?? json['error'],
      data: json['data'],
      fieldErrors: fieldErrors,
    );
  }
}

/// Authentication service for handling login and authentication
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  /// Get the full API base URL
  String get _baseUrl => AppConfig.baseUrl;

  /// Get SharedPreferences instance
  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  /// Register a new user
  ///
  /// Makes a POST request to {{base_url}}/auth/register
  /// Expected request body: {
  ///   "firstName": "...",
  ///   "lastName": "...",
  ///   "email": "...",
  ///   "phone": "...",
  ///   "dateOfBirth": "...",
  ///   "password": "...",
  ///   "country": "...",
  ///   "documentType": "..."
  /// }
  Future<RegisterResponse> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String dateOfBirth,
    required String password,
    String? country,
    String? documentType,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/auth/register');

      // Prepare request body
      final requestBody = {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'dateOfBirth': dateOfBirth,
        'password': password,
      };

      // Add optional fields if provided
      if (country != null && country.isNotEmpty) {
        requestBody['country'] = country;
      }
      if (documentType != null && documentType.isNotEmpty) {
        requestBody['documentType'] = documentType;
      }

      // Print API URL and request body for debugging
      print('🔵 REGISTER API CALL');
      print('📍 URL: $url');
      print('📤 Request Body: ${jsonEncode(requestBody)}');

      final response = await http
          .post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      )
          .timeout(
        AppConfig.connectionTimeout,
        onTimeout: () {
          throw Exception(
              'Connection timeout. Please check your internet connection.');
        },
      );

      // Print response details
      print('📥 Response Status Code: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      // Handle empty response body
      if (response.body.isEmpty) {
        return RegisterResponse(
          success: false,
          message: 'Empty response from server. Please try again.',
        );
      }

      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        return RegisterResponse(
          success: false,
          message: 'Invalid response format from server. Please try again.',
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return RegisterResponse.fromJson(responseData);
      } else {
        // Handle error response - still parse field errors even from error responses
        return RegisterResponse.fromJson(responseData);
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

      return RegisterResponse(
        success: false,
        message: errorMessage,
      );
    }
  }

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

      final response = await http
          .post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      )
          .timeout(
        AppConfig.connectionTimeout,
        onTimeout: () {
          throw Exception(
              'Connection timeout. Please check your internet connection.');
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
        errorMessage =
            'Connection timeout. Please check your internet connection.';
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
  Future<String?> getToken() async {
    final prefs = await _prefs;
    return prefs.getString(_tokenKey);
  }

  /// Save authentication token
  Future<void> saveToken(String token) async {
    final prefs = await _prefs;
    await prefs.setString(_tokenKey, token);
  }

  /// Save user data
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await _prefs;
    await prefs.setString(_userKey, jsonEncode(userData));
  }

  /// Get user data as Map
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await _prefs;
    final userDataString = prefs.getString(_userKey);
    if (userDataString != null) {
      try {
        return jsonDecode(userDataString) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Get current logged in user
  Future<User?> getCurrentUser() async {
    final userData = await getUserData();
    if (userData != null) {
      try {
        return User.fromJson(userData);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Clear authentication token and user data
  Future<void> clearToken() async {
    final prefs = await _prefs;
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Logout user
  ///
  /// Clears local token and optionally calls logout API endpoint
  Future<bool> logout() async {
    try {
      // Optionally call logout API endpoint if needed
      final token = await getToken();
      if (token != null) {
        try {
          final url = Uri.parse('$_baseUrl/auth/logout');
          await http.post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          ).timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              // If logout API fails, still clear local token
              return http.Response('', 408);
            },
          );
        } catch (e) {
          // If API call fails, still proceed with local logout
          // This ensures user can always logout even if API is unavailable
        }
      }

      // Clear local token and user data
      await clearToken();
      return true;
    } catch (e) {
      // Even if there's an error, try to clear local data
      await clearToken();
      return false;
    }
  }
}
