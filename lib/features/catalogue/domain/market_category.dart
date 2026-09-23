import '../../../core/firestore/firestore_value.dart';

class MarketCategory {
  const MarketCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.active,
    required this.createdBy,
    this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final bool active;
  final String createdBy;
  final DateTime? createdAt;

  factory MarketCategory.fromMap(String id, Map<String, dynamic> data) {
    return MarketCategory(
      id: id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      active: data['active'] as bool? ?? false,
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: FirestoreValue.date(data['createdAt']),
    );
  }
}
