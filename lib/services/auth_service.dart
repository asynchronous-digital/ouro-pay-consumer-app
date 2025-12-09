import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ouro_pay_consumer_app/config/app_config.dart';
import 'package:ouro_pay_consumer_app/models/user.dart';
import 'package:ouro_pay_consumer_app/models/country.dart';
import 'package:ouro_pay_consumer_app/models/user_profile.dart';

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

/// Response model for step 1 validation
class ValidationResponse {
  final bool success;
  final String? message;
  final Map<String, List<String>>? errors;

  ValidationResponse({
    required this.success,
    this.message,
    this.errors,
  });

  factory ValidationResponse.fromJson(Map<String, dynamic> json) {
    Map<String, List<String>>? errors;

    if (json['errors'] != null && json['errors'] is Map) {
      errors = {};
      (json['errors'] as Map).forEach((key, value) {
        if (value is List) {
          errors![key.toString()] = value.map((e) => e.toString()).toList();
        } else if (value is String) {
          errors![key.toString()] = [value];
        }
      });
    }

    return ValidationResponse(
      success: json['success'] ?? false,
      message: json['message'],
      errors: errors,
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
  final Map<String, List<String>>? errors; // Field-specific validation errors

  RegisterResponse({
    required this.success,
    this.token,
    this.user,
    this.message,
    this.data,
    this.errors,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    // Parse field-specific errors from various possible formats
    Map<String, List<String>>? errors;

    if (json['errors'] != null) {
      if (json['errors'] is Map) {
        errors = {};
        (json['errors'] as Map).forEach((key, value) {
          if (value is String) {
            errors![key.toString()] = [value];
          } else if (value is List) {
            errors![key.toString()] = value.map((e) => e.toString()).toList();
          }
        });
      }
    } else if (json['validation'] != null && json['validation'] is Map) {
      errors = {};
      (json['validation'] as Map).forEach((key, value) {
        if (value is String) {
          errors![key.toString()] = [value];
        } else if (value is List) {
          errors![key.toString()] = value.map((e) => e.toString()).toList();
        }
      });
    }

    // Print parsed field errors for debugging
    if (errors != null && errors.isNotEmpty) {
      print('🔴 Parsed Field Errors: $errors');
    }

    return RegisterResponse(
      success: json['success'] ?? false,
      token: json['token'] ?? json['data']?['token'],
      user: json['user'] ?? json['data']?['user'],
      message: json['message'] ?? json['error'],
      data: json['data'],
      errors: errors,
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

  /// Validate step 1 of registration
  ///
  /// Makes a POST request to {{base_url}}/auth/register/validation/step1
  Future<ValidationResponse> validateStep1({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String dateOfBirth,
    required String password,
    String? countryId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/auth/register/validation/step1');

      // Prepare request body
      final requestBody = {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'date_of_birth': dateOfBirth,
        'password': password,
        'password_confirmation': password,
      };

      if (countryId != null) {
        requestBody['country_id'] = countryId;
      }

      print('');
      print('═══════════════════════════════════════════════════════════');
      print('🔵 VALIDATE STEP 1 API CALL');
      print('═══════════════════════════════════════════════════════════');
      print('📍 API Endpoint: $url');
      print('📤 Request Body: ${jsonEncode(requestBody)}');
      print('───────────────────────────────────────────────────────────');

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

      print('📥 Response Status Code: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.body.isEmpty) {
        return ValidationResponse(
          success: false,
          message: 'Empty response from server',
        );
      }

      final responseData = jsonDecode(response.body);
      return ValidationResponse.fromJson(responseData);
    } catch (e) {
      print('❌ Validation Error: $e');
      print('═══════════════════════════════════════════════════════════');
      print('');
      return ValidationResponse(
        success: false,
        message: 'An error occurred during validation',
      );
    }
  }

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
    required String first_name,
    required String last_name,
    required String email,
    required String phone,
    required String date_of_birth,
    required String password,
    String? country,
    String? documentType,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/auth/register');

      // Prepare request body
      final requestBody = {
        'first_name': first_name,
        'last_name': last_name,
        'email': email,
        'phone': phone,
        'date_of_birth': date_of_birth,
        'password': password,
        'password_confirmation':
            password, // Often required by backends expecting confirmation
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

  /// Register a new user with document uploads
  ///
  /// Makes a POST request to {{base_url}}/auth/register with multipart/form-data
  /// Required fields:
  /// - first_name, last_name, email, password, date_of_birth
  /// - otp (verification code)
  /// - country_id (ID of the country)
  /// - document_type (passport, national_id, or drivers_license)
  /// - document (file: JPG, PNG, WEBP, PDF - max 5MB)
  /// - selfie (file: JPG, PNG, WEBP - max 5MB)
  Future<RegisterResponse> registerWithDocuments({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String dateOfBirth,
    required String phone,
    required String otp,
    required int countryId,
    required String documentType,
    required String documentFrontPath,
    required String documentBackPath,
    required String selfiePath,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/auth/register');

      print('');
      print('═══════════════════════════════════════════════════════════');
      print('🔵 REGISTER WITH DOCUMENTS API CALL');
      print('═══════════════════════════════════════════════════════════');
      print('📍 API Endpoint: $url');
      print('───────────────────────────────────────────────────────────');

      // Create multipart request
      var request = http.MultipartRequest('POST', url);

      // Add text fields
      request.fields['first_name'] = firstName;
      request.fields['last_name'] = lastName;
      request.fields['email'] = email;
      request.fields['password'] = password;
      request.fields['password_confirmation'] = password; // Same as password
      request.fields['date_of_birth'] = dateOfBirth;
      request.fields['phone'] = phone;
      request.fields['otp'] = otp;
      request.fields['country_id'] = countryId.toString();
      request.fields['document_type'] = documentType;

      print('📤 Request Fields:');
      print('   first_name: $firstName');
      print('   last_name: $lastName');
      print('   email: $email');
      print('   phone: $phone');
      print('   date_of_birth: $dateOfBirth');
      print('   password: ***');
      print('   password_confirmation: ***');
      print('   otp: $otp');
      print('   country_id: $countryId');
      print('   document_type: $documentType');

      // Add document front file
      var documentFrontFile = await http.MultipartFile.fromPath(
        'document_front',
        documentFrontPath,
      );
      request.files.add(documentFrontFile);
      print('   document_front: ${documentFrontPath.split('/').last}');

      // Add document back file
      var documentBackFile = await http.MultipartFile.fromPath(
        'document_back',
        documentBackPath,
      );
      request.files.add(documentBackFile);
      print('   document_back: ${documentBackPath.split('/').last}');

      // Add selfie file
      var selfieFile = await http.MultipartFile.fromPath(
        'selfie',
        selfiePath,
      );
      request.files.add(selfieFile);
      print('   selfie: ${selfiePath.split('/').last}');

      // Set headers (no access token needed for registration)
      request.headers['Accept'] = 'application/json';

      print('───────────────────────────────────────────────────────────');

      // Send request
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60), // Longer timeout for file uploads
        onTimeout: () {
          throw Exception(
              'Connection timeout. Please check your internet connection.');
        },
      );

      // Get response
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Response Status Code: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      // Handle empty response body
      if (response.body.isEmpty) {
        print('❌ Failed: Empty response from server');
        print('═══════════════════════════════════════════════════════════');
        print('');
        return RegisterResponse(
          success: false,
          message: 'Empty response from server. Please try again.',
        );
      }

      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        print('❌ Failed: Invalid JSON response');
        print('═══════════════════════════════════════════════════════════');
        print('');
        return RegisterResponse(
          success: false,
          message: 'Invalid response format from server. Please try again.',
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Success: Registration completed');
        print('═══════════════════════════════════════════════════════════');
        print('');
        return RegisterResponse.fromJson(responseData);
      } else {
        print('❌ Failed: Status ${response.statusCode}');
        print('═══════════════════════════════════════════════════════════');
        print('');
        // Handle error response - still parse field errors even from error responses
        return RegisterResponse.fromJson(responseData);
      }
    } catch (e) {
      print('❌ Register Error: $e');
      print('═══════════════════════════════════════════════════════════');
      print('');

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

      print('🔵 LOGIN API CALL');
      print('📍 URL: $url');
      print('📤 Request Body: ${jsonEncode({
            'email': email,
            'password': '***'
          })}');

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

      print('📥 Response Status Code: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

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
        print('📋 Parsed Response Data: $responseData');
      } catch (e) {
        print('❌ Failed to parse response: $e');
        return LoginResponse(
          success: false,
          message: 'Invalid response format from server. Please try again.',
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final loginResponse = LoginResponse.fromJson(responseData);
        print(
            '✅ LoginResponse created - success: ${loginResponse.success}, token: ${loginResponse.token != null ? "present" : "null"}, user: ${loginResponse.user != null ? "present" : "null"}');
        return loginResponse;
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
    final token = prefs.getString(_tokenKey);
    if (token != null) {
      print('🔑 Retrieved Token: $token');
    }
    return token;
  }

  /// Save authentication token
  Future<void> saveToken(String token) async {
    final prefs = await _prefs;
    print('🔑 Saving Token: $token');
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

  /// Send OTP for email verification
  ///
  /// Makes a POST request to {{base_url}}/email-verification/send-otp
  /// Expected request body: { "email": "..." }
  Future<bool> sendOtp(String email) async {
    try {
      final url = Uri.parse('$_baseUrl/email-verification/send-otp');

      print('');
      print('═══════════════════════════════════════════════════════════');
      print('🔵 SEND OTP API CALL');
      print('═══════════════════════════════════════════════════════════');
      print('📍 API Endpoint: $url');
      print('📤 Request Body: ${jsonEncode({'email': email})}');
      print(
          '📋 Headers: Content-Type: application/json, Accept: application/json');
      print('───────────────────────────────────────────────────────────');

      final response = await http
          .post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email}),
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final message = responseData['message'] ?? 'OTP sent successfully';
        final success = responseData['success'] ?? true;

        print('✅ Success: $success');
        print('💬 Message: $message');
        print('📊 Full Response Data: $responseData');
        print('═══════════════════════════════════════════════════════════');
        print('');

        return success;
      } else {
        final responseData = jsonDecode(response.body);
        final message = responseData['message'] ??
            responseData['error'] ??
            'Failed to send OTP';

        print('❌ Failed: Status ${response.statusCode}');
        print('💬 Error Message: $message');
        print('📊 Full Response Data: $responseData');
        print('═══════════════════════════════════════════════════════════');
        print('');

        return false;
      }
    } catch (e) {
      print('❌ Send OTP Error: $e');
      print('═══════════════════════════════════════════════════════════');
      print('');
      return false;
    }
  }

  /// Verify OTP for email verification
  ///
  /// Makes a POST request to {{base_url}}/email-verification/verify-otp
  /// Expected request body: { "email": "...", "otp": "..." }
  Future<bool> verifyOtp(String email, String otp) async {
    try {
      final url = Uri.parse('$_baseUrl/email-verification/verify-otp');

      print('');
      print('═══════════════════════════════════════════════════════════');
      print('🔵 VERIFY OTP API CALL');
      print('═══════════════════════════════════════════════════════════');
      print('📍 API Endpoint: $url');
      print('📤 Request Body: ${jsonEncode({'email': email, 'otp': otp})}');
      print(
          '📋 Headers: Content-Type: application/json, Accept: application/json');
      print('───────────────────────────────────────────────────────────');

      final response = await http
          .post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'otp': otp}),
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final message = responseData['message'] ?? 'OTP verified successfully';
        final success = responseData['success'] ?? true;

        print('✅ Success: $success');
        print('💬 Message: $message');
        print('📊 Full Response Data: $responseData');
        print('═══════════════════════════════════════════════════════════');
        print('');

        return success;
      } else {
        final responseData = jsonDecode(response.body);
        final message = responseData['message'] ??
            responseData['error'] ??
            'Failed to verify OTP';

        print('❌ Failed: Status ${response.statusCode}');
        print('💬 Error Message: $message');
        print('📊 Full Response Data: $responseData');
        print('═══════════════════════════════════════════════════════════');
        print('');

        return false;
      }
    } catch (e) {
      print('❌ Verify OTP Error: $e');
      print('═══════════════════════════════════════════════════════════');
      print('');
      return false;
    }
  }

  /// Get list of countries
  ///
  /// Makes a GET request to {{base_url}}/countries
  Future<List<Country>> getCountries() async {
    try {
      final url = Uri.parse('$_baseUrl/countries');

      print('');
      print('═══════════════════════════════════════════════════════════');
      print('🔵 GET COUNTRIES API CALL');
      print('═══════════════════════════════════════════════════════════');
      print('📍 API Endpoint: $url');
      print('───────────────────────────────────────────────────────────');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        AppConfig.connectionTimeout,
        onTimeout: () {
          throw Exception(
              'Connection timeout. Please check your internet connection.');
        },
      );

      print('📥 Response Status Code: ${response.statusCode}');
      // print('📥 Response Body: ${response.body}'); // Potentially large output

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final success = responseData['success'] ?? false;

        if (success && responseData['data'] != null) {
          final List<dynamic> data = responseData['data'];
          final countries = data.map((json) => Country.fromJson(json)).toList();

          print('✅ Success: Retrieved ${countries.length} countries');
          print('═══════════════════════════════════════════════════════════');
          print('');

          return countries;
        } else {
          print('❌ Failed: Success flag is false or data is null');
          return [];
        }
      } else {
        print('❌ Failed: Status ${response.statusCode}');
        print('═══════════════════════════════════════════════════════════');
        print('');
        return [];
      }
    } catch (e) {
      print('❌ Get Countries Error: $e');
      print('═══════════════════════════════════════════════════════════');
      print('');
      return [];
    }
  }

  /// Get user profile with KYC status and permissions
  ///
  /// Makes a GET request to {{base_url}}/user/profile
  /// Requires authentication token in header
  Future<UserProfileResponse> getUserProfile() async {
    try {
      final url = Uri.parse('$_baseUrl/consumer/profile');
      final token = await getToken();

      print('');
      print('═══════════════════════════════════════════════════════════');
      print('🔵 GET USER PROFILE API CALL');
      print('═══════════════════════════════════════════════════════════');
      print('📍 API Endpoint: $url');
      print('🔑 Authorization: Bearer ${token != null ? "***" : "null"}');
      print('───────────────────────────────────────────────────────────');

      if (token == null) {
        print('❌ Failed: No authentication token found');
        print('═══════════════════════════════════════════════════════════');
        print('');
        return UserProfileResponse(
          success: false,
          message: 'Authentication required',
        );
      }

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

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final profileResponse = UserProfileResponse.fromJson(responseData);

        if (profileResponse.data != null) {
          print('✅ Success: Profile retrieved');
          print('   User: ${profileResponse.data!.name}');
          print('   Email: ${profileResponse.data!.email}');
          print(
              '   KYC Status: ${profileResponse.data!.authorization.kycStatus.status}');
          print(
              '   Is Active: ${profileResponse.data!.authorization.isActive}');
        }
        print('═══════════════════════════════════════════════════════════');
        print('');

        return profileResponse;
      } else {
        final responseData = jsonDecode(response.body);
        print('❌ Failed: Status ${response.statusCode}');
        print('═══════════════════════════════════════════════════════════');
        print('');
        return UserProfileResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to get profile',
        );
      }
    } catch (e) {
      print('❌ Get User Profile Error: $e');
      print('═══════════════════════════════════════════════════════════');
      print('');
      return UserProfileResponse(
        success: false,
        message: 'An error occurred while fetching profile',
      );
    }
  }
}
