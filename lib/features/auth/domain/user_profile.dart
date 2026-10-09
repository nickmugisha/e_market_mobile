import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  client,
  seller;

  String get label => switch (this) {
    UserRole.client => 'Client',
    UserRole.seller => 'Seller',
  };

  static UserRole fromValue(String? value) {
    return value == 'seller' ? UserRole.seller : UserRole.client;
  }
}

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.whatsappNumber,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String whatsappNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get firstName {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return role.label;
    return trimmed.split(RegExp(r'\s+')).first;
  }

  factory UserProfile.fromMap(Map<String, dynamic> data) {
    DateTime? asDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      return null;
    }

    return UserProfile(
      uid: data['uid'] as String? ?? '',
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      role: UserRole.fromValue(data['role'] as String?),
      whatsappNumber: data['whatsappNumber'] as String? ?? '',
      createdAt: asDate(data['createdAt']),
      updatedAt: asDate(data['updatedAt']),
    );
  }
}
