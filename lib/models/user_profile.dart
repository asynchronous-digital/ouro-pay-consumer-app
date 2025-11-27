/// User Profile models for handling the /user/profile API response
class UserProfile {
  final int id;
  final String name;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String status;
  final String preferredCurrency;
  final String? profilePhoto;
  final String? emailVerifiedAt;
  final String? phoneVerifiedAt;
  final String? lastLoginAt;
  final String createdAt;
  final String updatedAt;
  final UserAuthorization authorization;

  const UserProfile({
    required this.id,
    required this.name,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.status,
    required this.preferredCurrency,
    this.profilePhoto,
    this.emailVerifiedAt,
    this.phoneVerifiedAt,
    this.lastLoginAt,
    required this.createdAt,
    required this.updatedAt,
    required this.authorization,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      status: json['status'] ?? 'inactive',
      preferredCurrency: json['preferred_currency'] ?? 'USD',
      profilePhoto: json['profile_photo'],
      emailVerifiedAt: json['email_verified_at'],
      phoneVerifiedAt: json['phone_verified_at'],
      lastLoginAt: json['last_login_at'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      authorization: UserAuthorization.fromJson(json['authorization'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'status': status,
      'preferred_currency': preferredCurrency,
      'profile_photo': profilePhoto,
      'email_verified_at': emailVerifiedAt,
      'phone_verified_at': phoneVerifiedAt,
      'last_login_at': lastLoginAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'authorization': authorization.toJson(),
    };
  }
}

class UserAuthorization {
  final bool isActive;
  final bool emailVerified;
  final bool phoneVerified;
  final KYCStatus kycStatus;
  final UserPermissions permissions;
  final AccountLimits accountLimits;

  const UserAuthorization({
    required this.isActive,
    required this.emailVerified,
    required this.phoneVerified,
    required this.kycStatus,
    required this.permissions,
    required this.accountLimits,
  });

  factory UserAuthorization.fromJson(Map<String, dynamic> json) {
    return UserAuthorization(
      isActive: json['is_active'] ?? false,
      emailVerified: json['email_verified'] ?? false,
      phoneVerified: json['phone_verified'] ?? false,
      kycStatus: KYCStatus.fromJson(json['kyc_status'] ?? {}),
      permissions: UserPermissions.fromJson(json['permissions'] ?? {}),
      accountLimits: AccountLimits.fromJson(json['account_limits'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_active': isActive,
      'email_verified': emailVerified,
      'phone_verified': phoneVerified,
      'kyc_status': kycStatus.toJson(),
      'permissions': permissions.toJson(),
      'account_limits': accountLimits.toJson(),
    };
  }
}

class KYCStatus {
  final String status; // not_submitted, pending, approved, rejected
  final String? verifiedAt;
  final String level; // none, basic, advanced

  const KYCStatus({
    required this.status,
    this.verifiedAt,
    required this.level,
  });

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
  bool get isNotSubmitted => status == 'not_submitted';

  factory KYCStatus.fromJson(Map<String, dynamic> json) {
    return KYCStatus(
      status: json['status'] ?? 'not_submitted',
      verifiedAt: json['verified_at'],
      level: json['level'] ?? 'none',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'verified_at': verifiedAt,
      'level': level,
    };
  }
}

class UserPermissions {
  final bool canViewProfile;
  final bool canUpdateProfile;
  final bool canChangePassword;
  final bool canViewWallets;
  final bool canViewTransactions;
  final bool canDeposit;
  final bool canWithdraw;
  final bool canConvertCurrency;
  final bool canViewGoldPrice;
  final bool canBuyGold;
  final bool canSellGold;
  final bool canAddBankAccount;
  final bool canSubmitKyc;
  final bool canExportData;

  const UserPermissions({
    required this.canViewProfile,
    required this.canUpdateProfile,
    required this.canChangePassword,
    required this.canViewWallets,
    required this.canViewTransactions,
    required this.canDeposit,
    required this.canWithdraw,
    required this.canConvertCurrency,
    required this.canViewGoldPrice,
    required this.canBuyGold,
    required this.canSellGold,
    required this.canAddBankAccount,
    required this.canSubmitKyc,
    required this.canExportData,
  });

  factory UserPermissions.fromJson(Map<String, dynamic> json) {
    return UserPermissions(
      canViewProfile: json['can_view_profile'] ?? false,
      canUpdateProfile: json['can_update_profile'] ?? false,
      canChangePassword: json['can_change_password'] ?? false,
      canViewWallets: json['can_view_wallets'] ?? false,
      canViewTransactions: json['can_view_transactions'] ?? false,
      canDeposit: json['can_deposit'] ?? false,
      canWithdraw: json['can_withdraw'] ?? false,
      canConvertCurrency: json['can_convert_currency'] ?? false,
      canViewGoldPrice: json['can_view_gold_price'] ?? false,
      canBuyGold: json['can_buy_gold'] ?? false,
      canSellGold: json['can_sell_gold'] ?? false,
      canAddBankAccount: json['can_add_bank_account'] ?? false,
      canSubmitKyc: json['can_submit_kyc'] ?? false,
      canExportData: json['can_export_data'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'can_view_profile': canViewProfile,
      'can_update_profile': canUpdateProfile,
      'can_change_password': canChangePassword,
      'can_view_wallets': canViewWallets,
      'can_view_transactions': canViewTransactions,
      'can_deposit': canDeposit,
      'can_withdraw': canWithdraw,
      'can_convert_currency': canConvertCurrency,
      'can_view_gold_price': canViewGoldPrice,
      'can_buy_gold': canBuyGold,
      'can_sell_gold': canSellGold,
      'can_add_bank_account': canAddBankAccount,
      'can_submit_kyc': canSubmitKyc,
      'can_export_data': canExportData,
    };
  }
}

class AccountLimits {
  final double dailyDepositLimit;
  final double dailyWithdrawalLimit;
  final double monthlyDepositLimit;
  final double monthlyWithdrawalLimit;
  final double goldTradingLimit;

  const AccountLimits({
    required this.dailyDepositLimit,
    required this.dailyWithdrawalLimit,
    required this.monthlyDepositLimit,
    required this.monthlyWithdrawalLimit,
    required this.goldTradingLimit,
  });

  factory AccountLimits.fromJson(Map<String, dynamic> json) {
    return AccountLimits(
      dailyDepositLimit: (json['daily_deposit_limit'] ?? 0).toDouble(),
      dailyWithdrawalLimit: (json['daily_withdrawal_limit'] ?? 0).toDouble(),
      monthlyDepositLimit: (json['monthly_deposit_limit'] ?? 0).toDouble(),
      monthlyWithdrawalLimit:
          (json['monthly_withdrawal_limit'] ?? 0).toDouble(),
      goldTradingLimit: (json['gold_trading_limit'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'daily_deposit_limit': dailyDepositLimit,
      'daily_withdrawal_limit': dailyWithdrawalLimit,
      'monthly_deposit_limit': monthlyDepositLimit,
      'monthly_withdrawal_limit': monthlyWithdrawalLimit,
      'gold_trading_limit': goldTradingLimit,
    };
  }
}

/// Response model for user profile API call
class UserProfileResponse {
  final bool success;
  final String message;
  final UserProfile? data;

  const UserProfileResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    return UserProfileResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? UserProfile.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.toJson(),
    };
  }
}
