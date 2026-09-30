import '../../auth/domain/user_profile.dart';
import '../../cart/domain/cart_item.dart';
import '../../catalogue/domain/product.dart';
import '../../orders/domain/order_models.dart';

class CheckoutDraft {
  const CheckoutDraft({
    required this.clientId,
    required this.clientName,
    required this.clientPhone,
    required this.sellerId,
    required this.items,
    required this.fulfillmentType,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.displayCurrency,
    required this.displayTotal,
  });

  final String clientId;
  final String clientName;
  final String clientPhone;
  final String sellerId;
  final List<CartItem> items;
  final FulfillmentType fulfillmentType;
  final String deliveryAddress;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final MarketCurrency displayCurrency;
  final double displayTotal;

  factory CheckoutDraft.fromValidatedCart({
    required UserProfile profile,
    required List<CartItem> items,
    required FulfillmentType fulfillmentType,
    required String deliveryAddress,
    required PaymentMethod paymentMethod,
    required PaymentStatus paymentStatus,
    required MarketCurrency displayCurrency,
    required double displayTotal,
  }) {
    if (items.isEmpty) {
      throw ArgumentError('A checkout draft needs at least one cart item.');
    }

    return CheckoutDraft(
      clientId: profile.uid,
      clientName: profile.name.trim(),
      clientPhone: profile.phone.trim(),
      sellerId: items.first.sellerId,
      items: List<CartItem>.unmodifiable(items),
      fulfillmentType: fulfillmentType,
      deliveryAddress: fulfillmentType == FulfillmentType.delivery
          ? deliveryAddress.trim()
          : '',
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      displayCurrency: displayCurrency,
      displayTotal: displayTotal,
    );
  }
}
