import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:ouro_pay_consumer_app/config/app_config.dart';
import 'package:ouro_pay_consumer_app/services/auth_service.dart';

/// Enum for KYC verification status
enum KycStatus {
  notStarted,
  inProgress,
  pending,
  approved,
  rejected,
  expired,
}

/// Enum for document types supported for verification
enum DocumentType {
  passport,
  driversLicense,
  nationalId,
  residencePermit,
}

/// Model for document verification result
class DocumentVerificationResult {
  final String documentId;
  final DocumentType documentType;
  final bool isValid;
  final String? errorMessage;
  final Map<String, dynamic>? extractedData;

  DocumentVerificationResult({
    required this.documentId,
    required this.documentType,
    required this.isValid,
    this.errorMessage,
    this.extractedData,
  });
}

/// Model for selfie verification result
class SelfieVerificationResult {
  final String selfieId;
  final bool isValid;
  final double? confidenceScore;
  final String? errorMessage;
  final bool? livenessDetected;

  SelfieVerificationResult({
    required this.selfieId,
    required this.isValid,
    this.confidenceScore,
    this.errorMessage,
    this.livenessDetected,
  });
}

/// Model for complete KYC verification result
class KycVerificationResult {
  final String verificationId;
  final KycStatus status;
  final DocumentVerificationResult? documentResult;
  final SelfieVerificationResult? selfieResult;
  final String? rejectionReason;
  final DateTime? completedAt;
  final Map<String, dynamic>? metadata;

  KycVerificationResult({
    required this.verificationId,
    required this.status,
    this.documentResult,
    this.selfieResult,
    this.rejectionReason,
    this.completedAt,
    this.metadata,
  });
}

/// Abstract interface for KYC service providers (Sumsub, Veriff, etc.)
abstract class KycServiceProvider {
  /// Initialize the KYC service with API credentials
  Future<void> initialize({
    required String apiKey,
    required String secretKey,
    String? baseUrl,
    bool isProduction = false,
  });

  /// Start a new KYC verification process
  Future<String> startVerification({
    required String userId,
    required String userEmail,
    Map<String, dynamic>? additionalData,
  });

  /// Upload and verify a document
  Future<DocumentVerificationResult> verifyDocument({
    required String verificationId,
    required File documentFile,
    required DocumentType documentType,
    String? documentSide, // front, back, etc.
  });

  /// Capture and verify selfie
  Future<SelfieVerificationResult> verifySelfie({
    required String verificationId,
    required File selfieFile,
    bool requireLiveness = true,
  });

  /// Get current verification status
  Future<KycVerificationResult> getVerificationStatus(String verificationId);

  /// Get verification history for a user
  Future<List<KycVerificationResult>> getVerificationHistory(String userId);

  /// Cancel ongoing verification
  Future<bool> cancelVerification(String verificationId);

  /// Check if service is available and configured
  Future<bool> isServiceAvailable();
}

/// KYC Service Manager - handles different providers
class KycServiceManager {
  static KycServiceManager? _instance;
  static KycServiceManager get instance => _instance ??= KycServiceManager._();

  KycServiceManager._();

  KycServiceProvider? _currentProvider;

  /// Initialize with a specific provider (Sumsub, Veriff, etc.)
  Future<void> initializeProvider(
    KycServiceProvider provider, {
    required String apiKey,
    required String secretKey,
    String? baseUrl,
    bool isProduction = false,
  }) async {
    await provider.initialize(
      apiKey: apiKey,
      secretKey: secretKey,
      baseUrl: baseUrl,
      isProduction: isProduction,
    );
    _currentProvider = provider;
  }

  /// Get the current KYC provider
  KycServiceProvider? get currentProvider => _currentProvider;

  /// Check if KYC service is configured and ready
  Future<bool> isReady() async {
    if (_currentProvider == null) return false;
    return await _currentProvider!.isServiceAvailable();
  }

  /// Start verification process
  Future<String> startVerification({
    required String userId,
    required String userEmail,
    Map<String, dynamic>? additionalData,
  }) async {
    if (_currentProvider == null) {
      throw Exception(
          'KYC service not initialized. Please configure a provider first.');
    }

    return await _currentProvider!.startVerification(
      userId: userId,
      userEmail: userEmail,
      additionalData: additionalData,
    );
  }

  /// Verify document
  Future<DocumentVerificationResult> verifyDocument({
    required String verificationId,
    required File documentFile,
    required DocumentType documentType,
    String? documentSide,
  }) async {
    if (_currentProvider == null) {
      throw Exception(
          'KYC service not initialized. Please configure a provider first.');
    }

    return await _currentProvider!.verifyDocument(
      verificationId: verificationId,
      documentFile: documentFile,
      documentType: documentType,
      documentSide: documentSide,
    );
  }

  /// Verify selfie
  Future<SelfieVerificationResult> verifySelfie({
    required String verificationId,
    required File selfieFile,
    bool requireLiveness = true,
  }) async {
    if (_currentProvider == null) {
      throw Exception(
          'KYC service not initialized. Please configure a provider first.');
    }

    return await _currentProvider!.verifySelfie(
      verificationId: verificationId,
      selfieFile: selfieFile,
      requireLiveness: requireLiveness,
    );
  }

  /// Get verification status
  Future<KycVerificationResult> getVerificationStatus(
      String verificationId) async {
    if (_currentProvider == null) {
      throw Exception(
          'KYC service not initialized. Please configure a provider first.');
    }

    return await _currentProvider!.getVerificationStatus(verificationId);
  }

  /// Get user's verification history
  Future<List<KycVerificationResult>> getVerificationHistory(
      String userId) async {
    if (_currentProvider == null) {
      throw Exception(
          'KYC service not initialized. Please configure a provider first.');
    }

    return await _currentProvider!.getVerificationHistory(userId);
  }

  /// Cancel verification
  Future<bool> cancelVerification(String verificationId) async {
    if (_currentProvider == null) {
      throw Exception(
          'KYC service not initialized. Please configure a provider first.');
    }

    return await _currentProvider!.cancelVerification(verificationId);
  }
}

/// Mock KYC provider for development/testing
class MockKycProvider implements KycServiceProvider {
  bool _isInitialized = false;

  @override
  Future<void> initialize({
    required String apiKey,
    required String secretKey,
    String? baseUrl,
    bool isProduction = false,
  }) async {
    // Simulate initialization delay
    await Future.delayed(const Duration(milliseconds: 500));
    _isInitialized = true;
  }

  @override
  Future<String> startVerification({
    required String userId,
    required String userEmail,
    Map<String, dynamic>? additionalData,
  }) async {
    if (!_isInitialized) throw Exception('Service not initialized');

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    return 'mock_verification_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<DocumentVerificationResult> verifyDocument({
    required String verificationId,
    required File documentFile,
    required DocumentType documentType,
    String? documentSide,
  }) async {
    if (!_isInitialized) throw Exception('Service not initialized');

    // Simulate document processing
    await Future.delayed(const Duration(seconds: 2));

    return DocumentVerificationResult(
      documentId: 'mock_doc_${DateTime.now().millisecondsSinceEpoch}',
      documentType: documentType,
      isValid: true,
      extractedData: {
        'name': 'John Doe',
        'dateOfBirth': '1990-01-01',
        'documentNumber': 'AB123456',
        'expiryDate': '2030-01-01',
      },
    );
  }

  @override
  Future<SelfieVerificationResult> verifySelfie({
    required String verificationId,
    required File selfieFile,
    bool requireLiveness = true,
  }) async {
    if (!_isInitialized) throw Exception('Service not initialized');

    // Simulate selfie processing
    await Future.delayed(const Duration(seconds: 2));

    return SelfieVerificationResult(
      selfieId: 'mock_selfie_${DateTime.now().millisecondsSinceEpoch}',
      isValid: true,
      confidenceScore: 0.95,
      livenessDetected: requireLiveness ? true : null,
    );
  }

  @override
  Future<KycVerificationResult> getVerificationStatus(
      String verificationId) async {
    if (!_isInitialized) throw Exception('Service not initialized');

    // Simulate status check
    await Future.delayed(const Duration(milliseconds: 500));

    return KycVerificationResult(
      verificationId: verificationId,
      status: KycStatus.approved,
      completedAt: DateTime.now(),
    );
  }

  @override
  Future<List<KycVerificationResult>> getVerificationHistory(
      String userId) async {
    if (!_isInitialized) throw Exception('Service not initialized');

    // Simulate history fetch
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      KycVerificationResult(
        verificationId: 'mock_verification_1',
        status: KycStatus.approved,
        completedAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
    ];
  }

  @override
  Future<bool> cancelVerification(String verificationId) async {
    if (!_isInitialized) throw Exception('Service not initialized');

    // Simulate cancellation
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  @override
  Future<bool> isServiceAvailable() async {
    return _isInitialized;
  }
}

/// Model for the KYC status API response data
/// Alias to KycDetails for backward compatibility if needed, using KycData as primary name
class KycData {
  final int? id;
  final String? documentType;
  final String? documentNumber;
  final String? rejectionReason;
  final String? adminNotes;
  final String? submittedAt;
  final String? reviewedAt;
  final String? status; // In case the API returns a status field

  KycData({
    this.id,
    this.documentType,
    this.documentNumber,
    this.rejectionReason,
    this.adminNotes,
    this.submittedAt,
    this.reviewedAt,
    this.status,
  });

  factory KycData.fromJson(Map<String, dynamic> json) {
    return KycData(
      id: json['id'],
      documentType: json['document_type'],
      documentNumber: json['document_number'],
      rejectionReason: json['rejection_reason'],
      adminNotes: json['admin_notes'],
      submittedAt: json['submitted_at'],
      reviewedAt: json['reviewed_at'],
      status: json['status'],
    );
  }

  KycStatus get computedStatus {
    // If we have an explicit status field, map it
    if (status != null) {
      switch (status!.toLowerCase()) {
        case 'approved':
          return KycStatus.approved;
        case 'rejected':
          return KycStatus.rejected;
        case 'pending':
        case 'submitted':
        case 'under_review':
          return KycStatus.pending;
        default:
          return KycStatus.notStarted;
      }
    }

    // Otherwise infer from timestamps and reason
    if (reviewedAt != null) {
      if (rejectionReason != null) {
        return KycStatus.rejected;
      }
      return KycStatus.approved;
    }

    if (submittedAt != null) {
      return KycStatus.pending;
    }

    return KycStatus.notStarted;
  }

  bool get canResubmit => computedStatus == KycStatus.rejected;
}

/// Service to handle KYC API interactions
class KycService {
  final AuthService _authService = AuthService();

  String get _baseUrl => AppConfig.baseUrl;

  /// Get current KYC status from backend
  Future<KycData?> getKycStatus() async {
    try {
      final token = await _authService.getToken();
      if (token == null) return null;

      final url = Uri.parse('$_baseUrl/kyc/status');

      print('🔍 Checking KYC Status: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print(
          '📥 KYC Status Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return KycData.fromJson(data['data']);
        } else if (data['success'] == false && data['message'] != null) {
          // Handle known error responses if needed
          print('⚠️ KYC Status API returned false success: ${data['message']}');
        }
      }
      return null;
    } catch (e) {
      print('❌ Error checking KYC status: $e');
      return null;
    }
  }

  /// Resubmit KYC documents
  Future<bool> resubmitKyc({
    required File? documentFront,
    required File? documentBack,
    required File? selfie,
  }) async {
    try {
      // Implementation pending - just return false or throw for now
      // Or implement actual resubmission logic if endpoint known
      print('⚠️ resubmitKyc not fully implemented yet');
      await Future.delayed(const Duration(seconds: 1));
      return false;
    } catch (e) {
      print('❌ Error resubmitting KYC: $e');
      return false;
    }
  }
}
