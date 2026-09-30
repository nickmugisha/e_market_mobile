import '../../catalogue/domain/product.dart';
import 'cart_item.dart';

enum CartIssueType {
  unavailable,
  insufficientStock,
  sellerMismatch,
}

class CartIssue {
  const CartIssue({
    required this.productId,
    required this.type,
    required this.message,
  });

  final String productId;
  final CartIssueType type;
  final String message;
}

abstract final class CartPolicy {
  static String? conflictingSellerId({
    required List<CartItem> currentItems,
    required String newSellerId,
  }) {
    if (currentItems.isEmpty) return null;

    final existingSellerId = currentItems.first.sellerId;
    if (existingSellerId == newSellerId) return null;

    return existingSellerId;
  }

  static List<CartIssue> validateStock({
    required List<CartItem> items,
    required List<Product> activeProducts,
  }) {
    final productsById = {
      for (final product in activeProducts) product.id: product,
    };

    final issues = <CartIssue>[];
    String? sellerId;

    for (final item in items) {
      sellerId ??= item.sellerId;

      if (item.sellerId != sellerId) {
        issues.add(
          CartIssue(
            productId: item.productId,
            type: CartIssueType.sellerMismatch,
            message: 'This cart contains products from more than one seller.',
          ),
        );
        continue;
      }

      final product = productsById[item.productId];
      if (product == null || !product.active) {
        issues.add(
          CartIssue(
            productId: item.productId,
            type: CartIssueType.unavailable,
            message: '${item.productName} is no longer available.',
          ),
        );
        continue;
      }

      if (item.quantity > product.stock) {
        issues.add(
          CartIssue(
            productId: item.productId,
            type: CartIssueType.insufficientStock,
            message:
                '${item.productName} only has ${product.stock} item${product.stock == 1 ? '' : 's'} left.',
          ),
        );
      }
    }

    return issues;
  }
}
