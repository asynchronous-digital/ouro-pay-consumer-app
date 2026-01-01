import 'dart:convert';
import 'package:ouro_pay_consumer_app/services/http_service.dart';
import 'package:ouro_pay_consumer_app/config/app_config.dart';
import 'package:ouro_pay_consumer_app/models/withdrawal.dart';

class WithdrawalService {
  final String _baseUrl = AppConfig.baseUrl;

  Future<Map<String, dynamic>> getWithdrawals({int page = 1}) async {
    final url = '$_baseUrl/withdrawals?page=$page';
    print('🔵 GET WITHDRAWALS API CALL');
    print('📍 URL: $url');

    final response = await HttpService.get(Uri.parse(url));

    print('📥 Response Status Code: ${response.statusCode}');
    print('📥 Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data[
            'data']; // Returns the object containing 'data' list and 'meta'
      } else {
        throw Exception(data['message'] ?? 'Failed to load withdrawals');
      }
    } else {
      throw Exception('Failed to load withdrawals: ${response.statusCode}');
    }
  }

  Future<Withdrawal> getWithdrawalDetails(int id) async {
    final url = '$_baseUrl/withdrawals/$id';
    print('🔵 GET WITHDRAWAL DETAILS API CALL');
    print('📍 URL: $url');

    final response = await HttpService.get(Uri.parse(url));

    print('📥 Response Status Code: ${response.statusCode}');
    print('📥 Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return Withdrawal.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to load withdrawal details');
      }
    } else {
      throw Exception('Failed to load withdrawal details');
    }
  }

  Future<bool> createWithdrawal(Map<String, dynamic> data) async {
    final url = '$_baseUrl/withdrawals';
    print('🔵 CREATE WITHDRAWAL API CALL');
    print('📍 URL: $url');
    print('📤 Request Body: ${jsonEncode(data)}');

    final response = await HttpService.post(
      Uri.parse(url),
      body: jsonEncode(data),
    );

    print('📥 Response Status Code: ${response.statusCode}');
    print('📥 Response Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      return responseData['success'] == true;
    } else {
      final responseData = jsonDecode(response.body);
      throw Exception(responseData['message'] ?? 'Failed to create withdrawal');
    }
  }

  Future<bool> cancelWithdrawal(int id) async {
    final url = '$_baseUrl/withdrawals/$id/cancel';
    print('🔵 CANCEL WITHDRAWAL API CALL');
    print('📍 URL: $url');

    final response = await HttpService.post(
      // Assuming POST for cancellation action usually
      Uri.parse(url),
    );

    print('📥 Response Status Code: ${response.statusCode}');
    print('📥 Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to cancel withdrawal');
    }
  }
}
