import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ouro_pay_consumer_app/config/app_config.dart';
import 'package:ouro_pay_consumer_app/services/auth_service.dart';
import 'package:ouro_pay_consumer_app/models/user_profile.dart';

// Import suspended page path - will be created later, so using dynamic import logic sort of.
// Actually we need to import it properly.
// For now, let's assume we will pass a callback or use named routes.
// But the requirement says "show a from Your account has been suspended".

class HttpService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static String get _baseUrl => AppConfig.baseUrl;

  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService().getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> get(Uri url,
      {bool skipSuspensionCheck = false}) async {
    print('🔵 GET Request: $url');
    final headers = await _getHeaders();
    final response = await http
        .get(url, headers: headers)
        .timeout(AppConfig.connectionTimeout);
    print('📥 RESPONSE (${response.statusCode}): $url');
    await checkStatus(response, skipSuspensionCheck: skipSuspensionCheck);
    return response;
  }

  static Future<http.Response> post(Uri url,
      {Object? body, bool skipSuspensionCheck = false}) async {
    print('🔵 POST Request: $url');
    final headers = await _getHeaders();
    final response = await http
        .post(url, headers: headers, body: body)
        .timeout(AppConfig.connectionTimeout);
    print('📥 RESPONSE (${response.statusCode}): $url');
    await checkStatus(response, skipSuspensionCheck: skipSuspensionCheck);
    return response;
  }

  static Future<http.Response> delete(Uri url,
      {Object? body, bool skipSuspensionCheck = false}) async {
    print('🔵 DELETE Request: $url');
    final headers = await _getHeaders();
    final response = await http
        .delete(url, headers: headers, body: body)
        .timeout(AppConfig.connectionTimeout);
    print('📥 RESPONSE (${response.statusCode}): $url');
    await checkStatus(response, skipSuspensionCheck: skipSuspensionCheck);
    return response;
  }

  static Future<void> checkStatus(http.Response response,
      {bool skipSuspensionCheck = false}) async {
    // Skip global 403 handling for appeals endpoints
    if (response.request?.url.path.contains('/appeals') == true) {
      return;
    }

    if (skipSuspensionCheck) {
      print(
          '⚠️ 403 Forbidden detected but global suspension check is skipped.');
      return;
    }

    if (response.statusCode == 403) {
      print('⚠️ 403 Forbidden detected. Checking Profile Status...');
      try {
        // We avoid calling HttpService.get here to prevent infinite loop if profile also returns 403
        // But profile is THE thing we need to check.
        // Prompt says: "call the consumer/profile api you will get a response like this..."
        // If profile ALSO returns 403, we might be stuck.
        // But usually profile returns 200 with status=suspended, OR 403 with specific data.
        // The prompt implies we call profile *after* getting 403.

        final authService = AuthService();
        final token = await authService.getToken();
        if (token == null) return;

        final profileUrl = Uri.parse('$_baseUrl/consumer/profile');
        final profileResponse = await http.get(profileUrl, headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        });

        if (profileResponse.statusCode == 200) {
          final body = jsonDecode(profileResponse.body);
          final profile = UserProfile.fromJson(body['data']);

          if (profile.status == 'suspended') {
            print('🔴 Account Suspended. Redirecting to Suspended Page.');
            // Redirect to Suspended Page
            if (navigatorKey.currentContext != null) {
              Navigator.pushNamed(navigatorKey.currentContext!, '/suspended',
                  arguments: profile);
            }
          }
        }
      } catch (e) {
        print('❌ Error checking suspension status: $e');
      }
    }
  }
}
