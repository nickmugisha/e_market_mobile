import '../../../core/currency/currency_service.dart';
import '../../cart/domain/cart_item.dart';
import '../../catalogue/domain/product.dart';
import 'order_models.dart';

abstract final class OrderPolicy {
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

  static bool shouldReserveStock(
    OrderStatus from,
    OrderStatus to,
  ) {
    return from == OrderStatus.pending && to == OrderStatus.confirmed;
  }

  static bool shouldRestoreStock(
    OrderStatus from,
    OrderStatus to,
  ) {
    return to == OrderStatus.cancelled &&
        (from == OrderStatus.confirmed ||
            from == OrderStatus.preparing ||
            from == OrderStatus.ready);
  }

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
}
