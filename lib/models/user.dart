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
    final id = json['id'] ?? json['_id'] ?? '';
    final email = json['email'] ?? '';
    final firstName = json['firstName'] ?? json['first_name'] ?? json['firstname'] ?? '';
    final lastName = json['lastName'] ?? json['last_name'] ?? json['lastname'] ?? '';
    
    // Handle date parsing with fallbacks
    DateTime createdAt;
    try {
      createdAt = json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'].toString())
          : (json['created_at'] != null 
              ? DateTime.parse(json['created_at'].toString())
              : DateTime.now());
    } catch (e) {
      createdAt = DateTime.now();
    }
    
    DateTime lastLoginAt;
    try {
      lastLoginAt = json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'].toString())
          : (json['last_login_at'] != null
              ? DateTime.parse(json['last_login_at'].toString())
              : DateTime.now());
    } catch (e) {
      lastLoginAt = DateTime.now();
    }
    
    final isVerified = json['isVerified'] ?? json['is_verified'] ?? json['verified'] ?? false;
    
    return User(
      id: id,
      email: email,
      firstName: firstName,
      lastName: lastName,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
      isVerified: isVerified,
    );
  }
  
  /// Create a User from API response with flexible field mapping
  factory User.fromApiResponse(Map<String, dynamic> json) {
    return User.fromJson(json);
  }
}
