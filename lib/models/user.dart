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
    if (email.isNotEmpty) {
      return email[0].toUpperCase();
    }
    return 'U'; // Default to 'U' for User if no email
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
    // Convert all values to strings to handle int/string type mismatches
    final idValue = json['id'] ?? json['_id'];
    final id = idValue != null ? idValue.toString() : '';
    
    final emailValue = json['email'];
    final email = emailValue != null ? emailValue.toString() : '';
    
    final firstNameValue = json['firstName'] ?? json['first_name'] ?? json['firstname'];
    final firstName = firstNameValue != null ? firstNameValue.toString() : '';
    
    final lastNameValue = json['lastName'] ?? json['last_name'] ?? json['lastname'];
    final lastName = lastNameValue != null ? lastNameValue.toString() : '';
    
    // Handle date parsing with fallbacks
    DateTime createdAt;
    try {
      final createdAtValue = json['createdAt'] ?? json['created_at'];
      if (createdAtValue != null) {
        createdAt = DateTime.parse(createdAtValue.toString());
      } else {
        createdAt = DateTime.now();
      }
    } catch (e) {
      createdAt = DateTime.now();
    }
    
    DateTime lastLoginAt;
    try {
      final lastLoginAtValue = json['lastLoginAt'] ?? json['last_login_at'];
      if (lastLoginAtValue != null) {
        lastLoginAt = DateTime.parse(lastLoginAtValue.toString());
      } else {
        lastLoginAt = DateTime.now();
      }
    } catch (e) {
      lastLoginAt = DateTime.now();
    }
    
    // Handle boolean with type safety
    final isVerifiedValue = json['isVerified'] ?? json['is_verified'] ?? json['verified'];
    final isVerified = isVerifiedValue is bool 
        ? isVerifiedValue 
        : (isVerifiedValue?.toString().toLowerCase() == 'true' ? true : false);
    
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
