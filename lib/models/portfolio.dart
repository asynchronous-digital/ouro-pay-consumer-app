class Wallet {
  final String currency;
  final double amount;
  final String symbol;
  final String displayName;

  const Wallet({
    required this.currency,
    required this.amount,
    required this.symbol,
    required this.displayName,
  });

  Wallet copyWith({
    String? currency,
    double? amount,
    String? symbol,
    String? displayName,
  }) {
    return Wallet(
      currency: currency ?? this.currency,
      amount: amount ?? this.amount,
      symbol: symbol ?? this.symbol,
      displayName: displayName ?? this.displayName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currency': currency,
      'amount': amount,
      'symbol': symbol,
      'displayName': displayName,
    };
  }

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      currency: json['currency'],
      amount: json['amount'].toDouble(),
      symbol: json['symbol'],
      displayName: json['displayName'],
    );
  }

  String get formattedAmount {
    return '$symbol${amount.toStringAsFixed(2)}';
  }
}

class GoldHolding {
  final double grams;
  final double currentPricePerGram;
  final DateTime lastUpdated;

  const GoldHolding({
    required this.grams,
    required this.currentPricePerGram,
    required this.lastUpdated,
  });

  GoldHolding copyWith({
    double? grams,
    double? currentPricePerGram,
    DateTime? lastUpdated,
  }) {
    return GoldHolding(
      grams: grams ?? this.grams,
      currentPricePerGram: currentPricePerGram ?? this.currentPricePerGram,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  double get totalValue => grams * currentPricePerGram;

  double get kilograms => grams / 1000.0;

  String get formattedGrams {
    if (grams >= 1000) {
      return '${kilograms.toStringAsFixed(3)} kg';
    }
    return '${grams.toStringAsFixed(3)} g';
  }

  String get formattedValue {
    return '\$${totalValue.toStringAsFixed(2)}';
  }
}

class UserPortfolio {
  final List<Wallet> wallets;
  final GoldHolding goldHolding;
  final String userId;
  final DateTime lastUpdated;

  const UserPortfolio({
    required this.wallets,
    required this.goldHolding,
    required this.userId,
    required this.lastUpdated,
  });

  UserPortfolio copyWith({
    List<Wallet>? wallets,
    GoldHolding? goldHolding,
    String? userId,
    DateTime? lastUpdated,
  }) {
    return UserPortfolio(
      wallets: wallets ?? this.wallets,
      goldHolding: goldHolding ?? this.goldHolding,
      userId: userId ?? this.userId,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Wallet? getWalletByCurrency(String currency) {
    try {
      return wallets.firstWhere((wallet) => wallet.currency == currency);
    } catch (e) {
      return null;
    }
  }

  double get totalWalletValue {
    return wallets.fold(0.0, (sum, wallet) => sum + wallet.amount);
  }

  double get totalPortfolioValue {
    return totalWalletValue + goldHolding.totalValue;
  }

  static UserPortfolio createDefault(String userId) {
    return UserPortfolio(
      userId: userId,
      wallets: [
        const Wallet(
          currency: 'USD',
          amount: 0.0,
          symbol: '\$',
          displayName: 'US Dollar',
        ),
        const Wallet(
          currency: 'EUR',
          amount: 0.0,
          symbol: '€',
          displayName: 'Euro',
        ),
        const Wallet(
          currency: 'SRD',
          amount: 0.0,
          symbol: 'Sr\$',
          displayName: 'Surinamese Dollar',
        ),
      ],
      goldHolding: GoldHolding(
        grams: 0.0,
        currentPricePerGram: 65.0, // Default gold price per gram in USD
        lastUpdated: DateTime.now(),
      ),
      lastUpdated: DateTime.now(),
    );
  }
}
