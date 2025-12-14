import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { customer, provider, admin }

class AppUser {
  final String id;
  final String? name;
  final String? phone;
  final String? email;
  final UserRole role;
  final String status; // Active | Suspended
  final String? profileImageUrl;
  final bool verified;
  final num walletBalance;
  final DateTime? createdAt;
  final DateTime? lastSeen;
  final String? city;
  final String? addressLine1;
  final String? town;
  final double? locationLat;
  final double? locationLng;

  const AppUser({
    required this.id,
    this.name,
    this.phone,
    this.email,
    required this.role,
    this.status = 'Active',
    this.profileImageUrl,
    this.verified = false,
    this.walletBalance = 0,
    this.createdAt,
    this.lastSeen,
    this.city,
    this.addressLine1,
    this.town,
    this.locationLat,
    this.locationLng,
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> data) {
    return AppUser(
      id: id,
      name: data['name'] as String?,
      phone: data['phone'] as String?,
      email: data['email'] as String?,
      role: _roleFromString(data['role'] as String?),
      status: data['status'] as String? ?? 'Active',
      profileImageUrl: data['profileImageUrl'] as String?,
      verified: (data['verified'] as bool?) ?? false,
      walletBalance: (data['walletBalance'] as num?) ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
      city: data['city'] as String?,
      addressLine1: data['addressLine1'] as String?,
      town: data['town'] as String?,
      locationLat: (data['locationLat'] as num?)?.toDouble(),
      locationLng: (data['locationLng'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'role': role.name,
      'status': status,
      'profileImageUrl': profileImageUrl,
      'verified': verified,
      'walletBalance': walletBalance,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'lastSeen': lastSeen == null ? null : Timestamp.fromDate(lastSeen!),
      'city': city,
      'addressLine1': addressLine1,
      'town': town,
      'locationLat': locationLat,
      'locationLng': locationLng,
    };
  }

  static UserRole _roleFromString(String? value) {
    switch (value) {
      case 'provider':
        return UserRole.provider;
      case 'admin':
        return UserRole.admin;
      case 'customer':
      default:
        return UserRole.customer;
    }
  }
}
