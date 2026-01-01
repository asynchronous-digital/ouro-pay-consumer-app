import 'dart:convert';
import 'package:ouro_pay_consumer_app/config/app_config.dart';
import 'package:ouro_pay_consumer_app/models/appeal.dart';
import 'package:ouro_pay_consumer_app/services/http_service.dart';

class AppealService {
  static final AppealService _instance = AppealService._internal();
  factory AppealService() => _instance;
  AppealService._internal();

  String get _baseUrl => AppConfig.baseUrl;

  Future<AppealListResponse> getAppeals() async {
    try {
      final url = Uri.parse('$_baseUrl/appeals');
      final response = await HttpService.get(url);

      if (response.statusCode == 200) {
        return AppealListResponse.fromJson(jsonDecode(response.body));
      } else {
        return AppealListResponse(
            success: false, message: 'Failed to fetch appeals', data: []);
      }
    } catch (e) {
      return AppealListResponse(success: false, message: 'Error: $e', data: []);
    }
  }

  Future<AppealDetailResponse> getAppealDetails(int id) async {
    try {
      final url = Uri.parse('$_baseUrl/appeals/$id');
      final response = await HttpService.get(url);

      if (response.statusCode == 200) {
        return AppealDetailResponse.fromJson(jsonDecode(response.body));
      } else {
        return AppealDetailResponse(
            success: false, message: 'Failed to fetch appeal details');
      }
    } catch (e) {
      return AppealDetailResponse(success: false, message: 'Error: $e');
    }
  }

  Future<Map<String, dynamic>> submitAppeal({
    required String subject,
    required String appealDetails,
    String? additionalNotes,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/appeals');
      final body = jsonEncode({
        'subject': subject,
        'appeal_details': appealDetails,
        'additional_notes': additionalNotes,
      });

      final response = await HttpService.post(url, body: body);

      print('📥 Submit Appeal Response Status: ${response.statusCode}');
      print('📥 Submit Appeal Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true};
      }

      // Handle specific errors
      final responseData = jsonDecode(response.body);
      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to submit appeal'
      };
    } catch (e) {
      print('Error submitting appeal: $e');
      return {'success': false, 'message': 'An unexpected error occurred: $e'};
    }
  }
}
