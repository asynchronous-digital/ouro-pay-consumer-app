import 'dart:convert';
import 'package:ouro_pay_consumer_app/services/http_service.dart';
import 'package:ouro_pay_consumer_app/config/app_config.dart';
import 'package:ouro_pay_consumer_app/models/bank_account.dart';

class BankService {
  final String _baseUrl = AppConfig.baseUrl;

  Future<List<BankAccount>> getBankAccounts() async {
    final url = '$_baseUrl/bank-accounts';
    print('🔵 GET BANK ACCOUNTS API CALL');
    print('📍 URL: $url');

    final response = await HttpService.get(Uri.parse(url));

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
    final url = '$_baseUrl/bank-accounts';
    print('🔵 ADD BANK ACCOUNT API CALL');
    print('📍 URL: $url');
    print('📤 Request Body: ${jsonEncode(accountData)}');

    final response = await HttpService.post(
      Uri.parse(url),
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
    final url = '$_baseUrl/bank-accounts/$id';
    print('🔵 DELETE BANK ACCOUNT API CALL');
    print('📍 URL: $url');

    final response = await HttpService.delete(Uri.parse(url));

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
