class Withdrawal {
  final int id;
  final double amount;
  final String status; // 'pending', 'processed', 'cancelled', 'rejected'
  final String? notes;
  final String? adminNote;

  // Full objects (optional)
  final BankAccountSnapshot? bankAccount;
  final CurrencySnapshot? currency;

  // Simple fields (fallback)
  final String? currencyCode;
  final int? bankAccountId;

  // Additional fields from API
  final String? reference;
  final double? fee;
  final double? netAmount;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Withdrawal({
    required this.id,
    required this.amount,
    required this.status,
    this.notes,
    this.adminNote,
    this.bankAccount,
    this.currency,
    this.currencyCode,
    this.bankAccountId,
    this.reference,
    this.fee,
    this.netAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  String get formattedAmount {
    // Try to use symbol from object, else code, else empty
    final symbol = currency?.symbol ?? currencyCode ?? '';
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  String get formattedFee {
    final symbol = currency?.symbol ?? currencyCode ?? '';
    return '$symbol${(fee ?? 0).toStringAsFixed(2)}';
  }

  String get formattedNetAmount {
    final symbol = currency?.symbol ?? currencyCode ?? '';
    return '$symbol${(netAmount ?? 0).toStringAsFixed(2)}';
  }

  String get statusDisplay {
    if (status.isEmpty) return '';
    return status[0].toUpperCase() + status.substring(1);
  }

  String get bankName => bankAccount?.bankName ?? 'Bank Acct #$bankAccountId';
  String get maskedAccountNumber => bankAccount?.accountNumber ?? '...';
  // Assuming the snapshot has the full account number based on previous bank account model,
  // but let's check what the backend sends for snapshot. Usually it's limited data.
  // For now, simple getter compatible with UI.

  factory Withdrawal.fromJson(Map<String, dynamic> json) {
    return Withdrawal(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      amount: double.parse(json['amount'].toString()),
      status: json['status'] ?? '',
      notes: json['notes'],
      adminNote: json['admin_note'],

      // Handle optional objects
      bankAccount: json['bank_account'] != null
          ? BankAccountSnapshot.fromJson(json['bank_account'])
          : null,
      currency: json['currency'] != null
          ? CurrencySnapshot.fromJson(json['currency'])
          : null,

      // Handle simple fields
      currencyCode: json['currency_code'],
      bankAccountId: json['bank_account_id'] is int
          ? json['bank_account_id']
          : int.tryParse(json['bank_account_id'].toString()),

      reference: json['reference'],
      fee: json['fee'] != null ? double.tryParse(json['fee'].toString()) : 0,
      netAmount: json['net_amount'] != null
          ? double.tryParse(json['net_amount'].toString())
          : 0,

      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class BankAccountSnapshot {
  final int id;
  final String bankName;
  final String accountHolderName;
  final String accountNumber;

  BankAccountSnapshot({
    required this.id,
    required this.bankName,
    required this.accountHolderName,
    required this.accountNumber,
  });

  factory BankAccountSnapshot.fromJson(Map<String, dynamic> json) {
    return BankAccountSnapshot(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      bankName: json['bank_name'] ?? '',
      accountHolderName: json['account_holder_name'] ?? '',
      accountNumber: json['account_number'] ?? '',
    );
  }
}

class CurrencySnapshot {
  final int id;
  final String code;
  final String name;
  final String symbol;

  CurrencySnapshot({
    required this.id,
    required this.code,
    required this.name,
    required this.symbol,
  });

  factory CurrencySnapshot.fromJson(Map<String, dynamic> json) {
    return CurrencySnapshot(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      symbol: json['symbol'] ?? '',
    );
  }
}
