import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ouro_pay_consumer_app/config/app_config.dart';
import 'package:ouro_pay_consumer_app/models/bank_account.dart';
import 'package:ouro_pay_consumer_app/services/auth_service.dart';

class BankService {
  final String _baseUrl = AppConfig.baseUrl;
  final AuthService _authService = AuthService();

  Future<List<BankAccount>> getBankAccounts() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final url = '$_baseUrl/bank-accounts';
    print('🔵 GET BANK ACCOUNTS API CALL');
    print('📍 URL: $url');

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    print('📥 Response Status Code: ${response.statusCode}');
    print('📥 Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final List<dynamic> accountsJson = data['data'];
        return accountsJson.map((json) => BankAccount.fromJson(json)).toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to load bank accounts');
      }
    } else {
      throw Exception('Failed to load bank accounts: ${response.statusCode}');
    }
  }

  Future<bool> addBankAccount(Map<String, dynamic> accountData) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final url = '$_baseUrl/bank-accounts';
    print('🔵 ADD BANK ACCOUNT API CALL');
    print('📍 URL: $url');
    print('📤 Request Body: ${jsonEncode(accountData)}');

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(accountData),
    );

    print('📥 Response Status Code: ${response.statusCode}');
    print('📥 Response Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to add bank account');
    }
  }

  Future<bool> deleteBankAccount(int id) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final url = '$_baseUrl/bank-accounts/$id';
    print('🔵 DELETE BANK ACCOUNT API CALL');
    print('📍 URL: $url');

    final response = await http.delete(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    print('📥 Response Status Code: ${response.statusCode}');
    print('📥 Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    } else {
      throw Exception('Failed to delete bank account');
    }
  }
}
