class Deposit {
  final int id;
  final String reference;
  final String currencyCode;
  final double amount;
  final double fee;
  final double netAmount;
  final String paymentMethod;
  final String status;
  final String? notes;
  final String? processedAt;
  final String createdAt;
  final String updatedAt;

  Deposit({
    required this.id,
    required this.reference,
    required this.currencyCode,
    required this.amount,
    required this.fee,
    required this.netAmount,
    required this.paymentMethod,
    required this.status,
    this.notes,
    this.processedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Deposit.fromJson(Map<String, dynamic> json) {
    return Deposit(
      id: json['id'],
      reference: json['reference'],
      currencyCode: json['currency_code'],
      amount: (json['amount'] as num).toDouble(),
      fee: (json['fee'] as num).toDouble(),
      netAmount: (json['net_amount'] as num).toDouble(),
      paymentMethod: json['payment_method'],
      status: json['status'],
      notes: json['notes'],
      processedAt: json['processed_at'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'completed':
        return 'Completed';
      case 'failed':
        return 'Failed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String get formattedAmount {
    return '${_getCurrencySymbol(currencyCode)}${amount.toStringAsFixed(2)}';
  }

  String get formattedNetAmount {
    return '${_getCurrencySymbol(currencyCode)}${netAmount.toStringAsFixed(2)}';
  }

  String _getCurrencySymbol(String code) {
    switch (code.toUpperCase()) {
      case 'EUR':
        return '€';
      case 'USD':
        return '\$';
      case 'SRD':
        return 'Sr\$';
      default:
        return code;
    }
  }
}

class DepositRequest {
  final String currencyCode;
  final double amount;
  final String paymentMethod;
  final String? notes;

  DepositRequest({
    required this.currencyCode,
    required this.amount,
    required this.paymentMethod,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'currency_code': currencyCode,
      'amount': amount,
      'payment_method': paymentMethod,
      if (notes != null) 'notes': notes,
    };
  }
}
