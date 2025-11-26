class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool isVerified;

  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.createdAt,
    required this.lastLoginAt,
    required this.isVerified,
  });

  User copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isVerified,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  String get fullName => '$firstName $lastName';

  String get displayName {
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return fullName;
    }
    return email;
  }

  String get initials {
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0]}${lastName[0]}'.toUpperCase();
    }
    return email[0].toUpperCase();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'isVerified': isVerified,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle different possible field names from API
    final id = (json['id'] ?? json['_id'] ?? '').toString();
    final email = json['email'] ?? '';
    final firstName =
        json['first_name'] ?? json['firstName'] ?? json['firstname'] ?? '';
    final lastName =
        json['last_name'] ?? json['lastName'] ?? json['lastname'] ?? '';

    // Handle date parsing with fallbacks
    DateTime createdAt;
    try {
      if (json['created_at'] != null) {
        createdAt = json['created_at'] is DateTime
            ? json['created_at']
            : DateTime.parse(json['created_at'].toString());
      } else if (json['createdAt'] != null) {
        createdAt = json['createdAt'] is DateTime
            ? json['createdAt']
            : DateTime.parse(json['createdAt'].toString());
      } else {
        createdAt = DateTime.now();
      }
    } catch (e) {
      print('⚠️ Failed to parse created_at: $e');
      createdAt = DateTime.now();
    }

    DateTime lastLoginAt;
    try {
      if (json['last_login_at'] != null) {
        lastLoginAt = json['last_login_at'] is DateTime
            ? json['last_login_at']
            : DateTime.parse(json['last_login_at'].toString());
      } else if (json['lastLoginAt'] != null) {
        lastLoginAt = json['lastLoginAt'] is DateTime
            ? json['lastLoginAt']
            : DateTime.parse(json['lastLoginAt'].toString());
      } else {
        lastLoginAt = DateTime.now();
      }
    } catch (e) {
      print('⚠️ Failed to parse last_login_at: $e');
      lastLoginAt = DateTime.now();
    }

    // Handle various boolean field formats
    final isVerified = json['email_verified_at'] != null ||
        json['isVerified'] == true ||
        json['is_verified'] == true ||
        json['verified'] == true;

    final user = User(
      id: id,
      email: email,
      firstName: firstName,
      lastName: lastName,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
      isVerified: isVerified,
    );

    print(
        '✅ User.fromJson parsed successfully: ${user.displayName} (${user.email})');
    return user;
  }

  /// Create a User from API response with flexible field mapping
  factory User.fromApiResponse(Map<String, dynamic> json) {
    return User.fromJson(json);
  }
}
