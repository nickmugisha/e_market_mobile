import '../../../core/firestore/firestore_value.dart';

enum MarketCurrency {
  bif('BIF'),
  usd('USD'),
  eur('EUR');

  const MarketCurrency(this.code);

  final String code;

  static MarketCurrency fromValue(String? value) {
    return switch (value?.toUpperCase()) {
      'USD' => MarketCurrency.usd,
      'EUR' => MarketCurrency.eur,
      _ => MarketCurrency.bif,
    };
  }
}

class Product {
  const Product({
    required this.id,
    required this.sellerId,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    required this.price,
    required this.currency,
    required this.stock,
    required this.imageRef,
    required this.active,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String sellerId;
  final String name;
  final String description;
  final String categoryId;
  final String categoryName;
  final double price;
  final MarketCurrency currency;
  final int stock;
  final String imageRef;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get inStock => active && stock > 0;

  factory Product.fromMap(String id, Map<String, dynamic> data) {
    return Product(
      id: id,
      sellerId: data['sellerId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? '',
      categoryName: data['categoryName'] as String? ?? '',
      price: FirestoreValue.doubleValue(data['price']),
      currency: MarketCurrency.fromValue(data['currency'] as String?),
      stock: FirestoreValue.intValue(data['stock']),
      imageRef: data['imageRef'] as String? ?? '',
      active: data['active'] as bool? ?? false,
      createdAt: FirestoreValue.date(data['createdAt']),
      updatedAt: FirestoreValue.date(data['updatedAt']),
    );
  }

  Product copyWith({
    String? id,
    String? sellerId,
    String? name,
    String? description,
    String? categoryId,
    String? categoryName,
    double? price,
    MarketCurrency? currency,
    int? stock,
    String? imageRef,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      stock: stock ?? this.stock,
      imageRef: imageRef ?? this.imageRef,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
