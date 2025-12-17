class PaymentHistoryResponse {
  final bool success;
  final String message;
  final PaymentHistoryData? data;

  PaymentHistoryResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory PaymentHistoryResponse.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? PaymentHistoryData.fromJson(json['data'])
          : null,
    );
  }
}

class PaymentHistoryData {
  final List<PaymentHistoryItem> payments;
  final Pagination? pagination;

  PaymentHistoryData({
    required this.payments,
    this.pagination,
  });

  factory PaymentHistoryData.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryData(
      payments: (json['payments'] as List?)
              ?.map((item) => PaymentHistoryItem.fromJson(item))
              .toList() ??
          [],
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
    );
  }
}

class PaymentHistoryItem {
  final int id;
  final String reference;
  final PaymentMerchant merchant;
  final PaymentRequest? paymentRequest;
  final PaymentGold gold;
  final PaymentFiat fiat;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentHistoryItem({
    required this.id,
    required this.reference,
    required this.merchant,
    this.paymentRequest,
    required this.gold,
    required this.fiat,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentHistoryItem.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryItem(
      id: json['id'],
      reference: json['reference'],
      merchant: PaymentMerchant.fromJson(json['merchant']),
      paymentRequest: json['payment_request'] != null
          ? PaymentRequest.fromJson(json['payment_request'])
          : null,
      gold: PaymentGold.fromJson(json['gold']),
      fiat: PaymentFiat.fromJson(json['fiat']),
      status: json['status'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class PaymentMerchant {
  final int id;
  final String name;
  final String? logoUrl;

  PaymentMerchant({
    required this.id,
    required this.name,
    this.logoUrl,
  });

  factory PaymentMerchant.fromJson(Map<String, dynamic> json) {
    return PaymentMerchant(
      id: json['id'],
      name: json['name'],
      logoUrl: json['logo_url'],
    );
  }
}

class PaymentRequest {
  final String? reference;
  final String? description;
  final String? invoiceNumber;

  PaymentRequest({
    this.reference,
    this.description,
    this.invoiceNumber,
  });

  factory PaymentRequest.fromJson(Map<String, dynamic> json) {
    return PaymentRequest(
      reference: json['reference'],
      description: json['description'],
      invoiceNumber: json['invoice_number'],
    );
  }
}

class PaymentGold {
  final double amount;
  final double pricePerGram;
  final String currencyCode;

  PaymentGold({
    required this.amount,
    required this.pricePerGram,
    required this.currencyCode,
  });

  factory PaymentGold.fromJson(Map<String, dynamic> json) {
    return PaymentGold(
      amount: (json['amount'] as num).toDouble(),
      pricePerGram: (json['price_per_gram'] as num).toDouble(),
      currencyCode: json['currency_code'],
    );
  }
}

class PaymentFiat {
  final double amount;
  final String currencyCode;
  final String formatted;

  PaymentFiat({
    required this.amount,
    required this.currencyCode,
    required this.formatted,
  });

  factory PaymentFiat.fromJson(Map<String, dynamic> json) {
    return PaymentFiat(
      amount: (json['amount'] as num).toDouble(),
      currencyCode: json['currency_code'],
      formatted: json['formatted'],
    );
  }
}

class Pagination {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  Pagination({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      currentPage: json['current_page'],
      lastPage: json['last_page'],
      perPage: json['per_page'],
      total: json['total'],
    );
  }
}
