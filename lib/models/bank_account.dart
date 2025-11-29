class BankAccount {
  final String id;
  final String accountHolderName;
  final String bankName;
  final String accountNumber;
  final String routingNumber;
  final String status; // 'verified', 'pending', 'unverified'

  const BankAccount({
    required this.id,
    required this.accountHolderName,
    required this.bankName,
    required this.accountNumber,
    required this.routingNumber,
    required this.status,
  });

  bool get isVerified => status == 'verified';

  String get maskedAccountNumber {
    if (accountNumber.length <= 4) return accountNumber;
    return '****${accountNumber.substring(accountNumber.length - 4)}';
  }

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'] as String,
      accountHolderName: json['account_holder_name'] as String,
      bankName: json['bank_name'] as String,
      accountNumber: json['account_number'] as String,
      routingNumber: json['routing_number'] as String,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'account_holder_name': accountHolderName,
      'bank_name': bankName,
      'account_number': accountNumber,
      'routing_number': routingNumber,
      'status': status,
    };
  }

  // Dummy data for testing
  factory BankAccount.dummy() {
    return const BankAccount(
      id: '1',
      accountHolderName: 'John Doe',
      bankName: 'Chase Bank',
      accountNumber: '1234567890',
      routingNumber: '987654321',
      status: 'verified',
    );
  }
}
