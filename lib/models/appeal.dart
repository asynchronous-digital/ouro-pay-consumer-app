class Appeal {
  final int id;
  final int userId;
  final String status;
  final String statusLabel;
  final String subject;
  final String appealDetails;
  final String? additionalNotes;
  final String? adminResponse;
  final String? reviewedBy;
  final String? reviewer;
  final String? reviewedAt;
  final String createdAt;
  final String updatedAt;

  Appeal({
    required this.id,
    required this.userId,
    required this.status,
    required this.statusLabel,
    required this.subject,
    required this.appealDetails,
    this.additionalNotes,
    this.adminResponse,
    this.reviewedBy,
    this.reviewer,
    this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Appeal.fromJson(Map<String, dynamic> json) {
    return Appeal(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      status: json['status'] ?? 'pending',
      statusLabel: json['status_label'] ?? 'Pending',
      subject: json['subject'] ?? '',
      appealDetails: json['appeal_details'] ?? '',
      additionalNotes: json['additional_notes']?.toString(),
      adminResponse: json['admin_response']?.toString(),
      reviewedBy: json['reviewed_by']?.toString(),
      reviewer: json['reviewer']?.toString(),
      reviewedAt: json['reviewed_at'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'status': status,
      'status_label': statusLabel,
      'subject': subject,
      'appeal_details': appealDetails,
      'additional_notes': additionalNotes,
      'admin_response': adminResponse,
      'reviewed_by': reviewedBy,
      'reviewer': reviewer,
      'reviewed_at': reviewedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class AppealListResponse {
  final bool success;
  final String message;
  final List<Appeal> data;
  final Map<String, dynamic>? meta;

  AppealListResponse({
    required this.success,
    required this.message,
    required this.data,
    this.meta,
  });

  factory AppealListResponse.fromJson(Map<String, dynamic> json) {
    List<Appeal> data = [];
    if (json['data'] != null && json['data']['data'] != null) {
      data = (json['data']['data'] as List)
          .map((i) => Appeal.fromJson(i))
          .toList();
    } else if (json['data'] is List) {
      data = (json['data'] as List).map((i) => Appeal.fromJson(i)).toList();
    }

    return AppealListResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: data,
      meta: json['data'] != null ? json['data']['meta'] : null,
    );
  }
}

class AppealDetailResponse {
  final bool success;
  final String message;
  final Appeal? data;

  AppealDetailResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory AppealDetailResponse.fromJson(Map<String, dynamic> json) {
    return AppealDetailResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? Appeal.fromJson(json['data']) : null,
    );
  }
}
