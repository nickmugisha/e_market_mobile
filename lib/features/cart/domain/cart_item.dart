import '../../../core/firestore/firestore_value.dart';
import '../../catalogue/domain/product.dart';

class CartItem {
  const CartItem({
    required this.productId,
    required this.sellerId,
    required this.productName,
    required this.imageRef,
    required this.quantity,
    required this.unitPrice,
    required this.currency,
    this.addedAt,
    this.updatedAt,
  });

  final String productId;
  final String sellerId;
  final String productName;
  final String imageRef;
  final int quantity;
  final double unitPrice;
  final MarketCurrency currency;
  final DateTime? addedAt;
  final DateTime? updatedAt;

  double get subtotal => unitPrice * quantity;

  factory CartItem.fromMap(String productId, Map<String, dynamic> data) {
    return CartItem(
      productId: productId,
      sellerId: data['sellerId'] as String? ?? '',
      productName: data['productName'] as String? ?? '',
      imageRef: data['imageRef'] as String? ?? '',
      quantity: FirestoreValue.intValue(data['quantity']),
      unitPrice: FirestoreValue.doubleValue(data['unitPrice']),
      currency: MarketCurrency.fromValue(data['currency'] as String?),
      addedAt: FirestoreValue.date(data['addedAt']),
      updatedAt: FirestoreValue.date(data['updatedAt']),
    );
  }
}
