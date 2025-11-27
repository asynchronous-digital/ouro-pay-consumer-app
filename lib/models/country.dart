class Country {
  final int id;
  final String name;
  final String code;
  final String phoneCode;
  final String currencyCode;
  final String language;

  Country({
    required this.id,
    required this.name,
    required this.code,
    required this.phoneCode,
    required this.currencyCode,
    required this.language,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
      phoneCode: json['phone_code'] as String,
      currencyCode: json['currency_code'] as String,
      language: json['language'] as String,
    );
  }
}
