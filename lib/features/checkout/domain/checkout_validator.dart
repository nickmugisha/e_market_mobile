import '../../cart/domain/cart_item.dart';
import '../../cart/domain/cart_policy.dart';
import '../../catalogue/domain/product.dart';
import '../../orders/domain/order_models.dart';

class CheckoutValidationResult {
  const CheckoutValidationResult(this.errors);

  final List<String> errors;

  bool get isValid => errors.isEmpty;
}

abstract final class CheckoutValidator {
  static CheckoutValidationResult validate({
    required List<CartItem> items,
    required List<Product> activeProducts,
    required FulfillmentType fulfillmentType,
    required String deliveryAddress,
  }) {
    final errors = <String>[];

    if (items.isEmpty) {
      errors.add('Your cart is empty.');
      return CheckoutValidationResult(errors);
    }

    final sellerIds = items.map((item) => item.sellerId).toSet();
    if (sellerIds.length != 1) {
      errors.add('Checkout can only contain products from one seller.');
    }

    final stockIssues = CartPolicy.validateStock(
      items: items,
      activeProducts: activeProducts,
    );
    errors.addAll(stockIssues.map((issue) => issue.message));

    if (fulfillmentType == FulfillmentType.delivery) {
      final address = deliveryAddress.trim();
      if (address.length < 5) {
        errors.add('Enter a complete delivery address.');
      }
    }

    return CheckoutValidationResult(List<String>.unmodifiable(errors));
  }
}
