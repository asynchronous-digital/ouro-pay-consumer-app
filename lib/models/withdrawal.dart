class Withdrawal {
  final String id;
  final double amount;
  final String currency;
  final String status; // 'pending', 'completed', 'failed', 'cancelled'
  final String bankName;
  final String accountNumber;
  final DateTime createdAt;
  final DateTime? processedAt;

  const Withdrawal({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.bankName,
    required this.accountNumber,
    required this.createdAt,
    this.processedAt,
  });

  String get formattedAmount => '$currency${amount.toStringAsFixed(2)}';

  String get statusDisplay {
    return status[0].toUpperCase() + status.substring(1);
  }

  String get maskedAccountNumber {
    if (accountNumber.length <= 4) return accountNumber;
    return '****${accountNumber.substring(accountNumber.length - 4)}';
  }

  factory Withdrawal.fromJson(Map<String, dynamic> json) {
    return Withdrawal(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      status: json['status'] as String,
      bankName: json['bank_name'] as String,
      accountNumber: json['account_number'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'] as String)
          : null,
    );
  }

  // Dummy data for testing
  static List<Withdrawal> dummyList() {
    return [
      Withdrawal(
        id: '1',
        amount: 100.00,
        currency: '\$',
        status: 'completed',
        bankName: 'Chase Bank',
        accountNumber: '1234567890',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        processedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Withdrawal(
        id: '2',
        amount: 50.00,
        currency: '€',
        status: 'pending',
        bankName: 'Deutsche Bank',
        accountNumber: '987654321',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      Withdrawal(
        id: '3',
        amount: 2500.00,
        currency: 'Sr\$',
        status: 'failed',
        bankName: 'DSB Bank',
        accountNumber: '1122334455',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        processedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
  }
}
