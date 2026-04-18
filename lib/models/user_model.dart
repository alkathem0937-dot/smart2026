import 'dart:convert';

/// User Model
class UserModel {
  final int id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String role; // main_lawyer, assistant, client, judge, citizen, admin
  final String? nationalId;
  final String? phone;
  final String? address;
  final int? courtId;
  final String? courtName;
  final String? subscriptionPlan; // free, starter, professional, enterprise
  final bool isTrial;
  final DateTime? subscriptionExpiry;
  final List<String>? permissions;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    required this.role,
    this.nationalId,
    this.phone,
    this.address,
    this.courtId,
    this.courtName,
    this.subscriptionPlan = 'free',
    this.isTrial = true,
    this.subscriptionExpiry,
    this.permissions,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final userData = json['user'] ?? json;
    
    return UserModel(
      id: userData['id'] ?? json['id'] ?? 0,
      username: json['username'] ?? userData['username'] ?? '',
      email: json['email'] ?? userData['email'] ?? '',
      firstName: json['first_name'] ?? userData['first_name'],
      lastName: json['last_name'] ?? userData['last_name'],
      role: json['role'] ?? 'citizen',
      nationalId: json['national_id'],
      phone: json['phone_number'] ?? json['phone'],
      address: json['address'],
      courtId: json['court'] ?? json['court_id'],
      courtName: json['court_name'],
      subscriptionPlan: json['subscription_plan'] ?? 'free',
      isTrial: _parseBool(json['is_trial'], defaultValue: true),
      subscriptionExpiry: json['subscription_expiry'] != null 
          ? DateTime.parse(json['subscription_expiry']) 
          : null,
      permissions: json['permissions'] != null 
          ? List<String>.from(json['permissions']) 
          : [],
    );
  }

  static bool _parseBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final s = value.toLowerCase();
      return s == '1' || s == 'true';
    }
    return defaultValue;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'role': role,
      'national_id': nationalId,
      'phone': phone,
      'address': address,
      'court_id': courtId,
      'court_name': courtName,
      'subscription_plan': subscriptionPlan,
      'is_trial': isTrial,
      'subscription_expiry': subscriptionExpiry?.toIso8601String(),
      'permissions': permissions,
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  factory UserModel.fromJsonString(String source) {
    return UserModel.fromJson(jsonDecode(source));
  }

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return username;
  }

  // Role Helpers
  bool get isMainLawyer => role == 'main_lawyer' || role == 'lawyer';
  bool get isAssistant => role == 'assistant';
  bool get isClient => role == 'client' || role == 'citizen';
  bool get isJudge => role == 'judge';
  bool get isAdmin => role == 'admin';
  bool get isLawyer => role == 'lawyer' || role == 'main_lawyer';
  bool get isCitizen => role == 'citizen' || role == 'client';
  bool get isNotary => role == 'notary';

  // Subscription Helpers
  bool get hasProFeatures => subscriptionPlan != 'free';
  bool get isSubscriptionActive {
    if (subscriptionExpiry == null) return isTrial;
    return subscriptionExpiry!.isAfter(DateTime.now());
  }
}

