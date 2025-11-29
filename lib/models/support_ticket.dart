class SupportTicket {
  final String id;
  final String subject;
  final String message;
  final String status; // 'open', 'closed', 'pending'
  final String priority; // 'low', 'medium', 'high'
  final DateTime createdAt;
  final DateTime? updatedAt;

  const SupportTicket({
    required this.id,
    required this.subject,
    required this.message,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.updatedAt,
  });

  String get statusDisplay {
    return status[0].toUpperCase() + status.substring(1);
  }

  String get priorityDisplay {
    return priority[0].toUpperCase() + priority.substring(1);
  }

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'] as String,
      subject: json['subject'] as String,
      message: json['message'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  // Dummy data for testing
  static List<SupportTicket> dummyList() {
    return [
      SupportTicket(
        id: '101',
        subject: 'Deposit not received',
        message: 'I made a deposit 2 days ago but it is not showing up.',
        status: 'open',
        priority: 'high',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      SupportTicket(
        id: '102',
        subject: 'How to change password?',
        message: 'I cannot find the option to change my password.',
        status: 'closed',
        priority: 'low',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
      SupportTicket(
        id: '103',
        subject: 'Withdrawal limit',
        message: 'What is the daily withdrawal limit?',
        status: 'pending',
        priority: 'medium',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
    ];
  }
}
