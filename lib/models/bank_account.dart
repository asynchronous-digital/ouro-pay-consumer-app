class BankAccount {
  final int id;
  final String bankName;
  final String accountHolderName;
  final String accountNumber;
  final String accountNumberFull;
  final String swiftCode;
  final String iban;
  final Currency? currency;
  final bool isDefault;
  final String createdAt;

  BankAccount({
    required this.id,
    required this.bankName,
    required this.accountHolderName,
    required this.accountNumber,
    required this.accountNumberFull,
    required this.swiftCode,
    required this.iban,
    this.currency,
    required this.isDefault,
    required this.createdAt,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      bankName: json['bank_name'] ?? '',
      accountHolderName: json['account_holder_name'] ?? '',
      accountNumber: json['account_number'] ?? '',
      accountNumberFull: json['account_number_full'] ?? '',
      swiftCode: json['swift_code'] ?? '',
      iban: json['iban'] ?? '',
      currency:
          json['currency'] != null ? Currency.fromJson(json['currency']) : null,
      isDefault: json['is_default'] ?? json['is_primary'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }

  // Compatibility getters for existing UI
  String get maskedAccountNumber => accountNumber;
  String get routingNumber => swiftCode;
  String get status => 'verified';
  bool get isVerified => true;
}

class Currency {
  final int id;
  final String code;
  final String name;
  final String symbol;

  Currency({
    required this.id,
    required this.code,
    required this.name,
    required this.symbol,
  });

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      symbol: json['symbol'] ?? '',
    );
  }
}
