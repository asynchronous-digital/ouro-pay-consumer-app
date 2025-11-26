import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Debug utility to print all saved SharedPreferences data
class DebugPrefs {
  static Future<void> printAllSavedData() async {
    final prefs = await SharedPreferences.getInstance();

    print('🔍 ========== SHARED PREFERENCES DEBUG ==========');

    // Get auth token
    final token = prefs.getString('auth_token');
    print('🔑 Auth Token: ${token ?? "NOT SET"}');

    // Get user data
    final userDataString = prefs.getString('user_data');
    if (userDataString != null) {
      try {
        final userData = jsonDecode(userDataString) as Map<String, dynamic>;
        print('👤 User Data (Raw JSON): $userDataString');
        print('👤 User Data (Parsed):');
        userData.forEach((key, value) {
          print('   - $key: $value');
        });
      } catch (e) {
        print('❌ Failed to parse user data: $e');
        print('   Raw value: $userDataString');
      }
    } else {
      print('👤 User Data: NOT SET');
    }

    // Show all keys
    final allKeys = prefs.getKeys();
    print('📋 All SharedPreferences Keys: $allKeys');

    print('🔍 ===============================================');
  }
}
