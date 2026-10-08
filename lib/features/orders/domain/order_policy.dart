import '../../../core/currency/currency_service.dart';
import '../../cart/domain/cart_item.dart';
import '../../catalogue/domain/product.dart';
import 'order_models.dart';

abstract final class OrderPolicy {
  static const double deliveryFeeBif = 5000;

  static bool canTransition(OrderStatus from, OrderStatus to) {
    if (from == to) return true;

    return switch (from) {
      OrderStatus.pending =>
        to == OrderStatus.confirmed || to == OrderStatus.cancelled,
      OrderStatus.confirmed =>
        to == OrderStatus.preparing || to == OrderStatus.cancelled,
      OrderStatus.preparing =>
        to == OrderStatus.ready || to == OrderStatus.cancelled,
      OrderStatus.ready =>
        to == OrderStatus.completed || to == OrderStatus.cancelled,
      OrderStatus.completed || OrderStatus.cancelled => false,
    };
  }

  static bool shouldReserveStock(OrderStatus from, OrderStatus to) {
    return from == OrderStatus.pending && to == OrderStatus.confirmed;
  }

  static bool shouldRestoreStock(OrderStatus from, OrderStatus to) {
    return to == OrderStatus.cancelled &&
        (from == OrderStatus.confirmed ||
            from == OrderStatus.preparing ||
            from == OrderStatus.ready);
  }

  /// Existing calculation kept for compatibility.
  /// This represents the products subtotal only.
  static double displayTotal({
    required List<CartItem> items,
    required MarketCurrency displayCurrency,
    CurrencyService currencyService = const CurrencyService(),
  }) {
    return items.fold<double>(
      0,
      (total, item) =>
          total +
          currencyService.convert(
            amount: item.subtotal,
            from: item.currency,
            to: displayCurrency,
          ),
    );
  }

  static double displaySubtotal({
    required List<CartItem> items,
    required MarketCurrency displayCurrency,
    CurrencyService currencyService = const CurrencyService(),
  }) {
    return displayTotal(
      items: items,
      displayCurrency: displayCurrency,
      currencyService: currencyService,
    );
  }

  static double deliveryFee({
    required FulfillmentType fulfillmentType,
    required MarketCurrency displayCurrency,
    CurrencyService currencyService = const CurrencyService(),
  }) {
    if (fulfillmentType == FulfillmentType.pickup) {
      return 0;
    }

    return currencyService.convert(
      amount: deliveryFeeBif,
      from: MarketCurrency.bif,
      to: displayCurrency,
    );
  }

  static double checkoutTotal({
    required List<CartItem> items,
    required FulfillmentType fulfillmentType,
    required MarketCurrency displayCurrency,
    CurrencyService currencyService = const CurrencyService(),
  }) {
    final subtotal = displaySubtotal(
      items: items,
      displayCurrency: displayCurrency,
      currencyService: currencyService,
    );

    final fee = deliveryFee(
      fulfillmentType: fulfillmentType,
      displayCurrency: displayCurrency,
      currencyService: currencyService,
    );

    return subtotal + fee;
  }
}
