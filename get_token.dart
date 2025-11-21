import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  if (token != null) {
    print('='.padRight(80, '='));
    print('ACCESS TOKEN:');
    print(token);
    print('='.padRight(80, '='));
  } else {
    print('No token found in SharedPreferences');
  }
}
