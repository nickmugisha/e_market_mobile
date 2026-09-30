import 'package:e_market/features/cart/domain/cart_item.dart';
import 'package:e_market/features/catalogue/domain/product.dart';
import 'package:e_market/features/orders/domain/order_models.dart';
import 'package:e_market/features/orders/domain/order_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('seller order status transitions follow the workflow', () {
    expect(
      OrderPolicy.canTransition(
        OrderStatus.pending,
        OrderStatus.confirmed,
      ),
      isTrue,
    );
    expect(
      OrderPolicy.canTransition(
        OrderStatus.confirmed,
        OrderStatus.preparing,
      ),
      isTrue,
    );
    expect(
      OrderPolicy.canTransition(
        OrderStatus.preparing,
        OrderStatus.ready,
      ),
      isTrue,
    );
    expect(
      OrderPolicy.canTransition(
        OrderStatus.ready,
        OrderStatus.completed,
      ),
      isTrue,
    );
    expect(
      OrderPolicy.canTransition(
        OrderStatus.completed,
        OrderStatus.cancelled,
      ),
      isFalse,
    );
  });

  test('stock is reserved only on pending to confirmed', () {
    expect(
      OrderPolicy.shouldReserveStock(
        OrderStatus.pending,
        OrderStatus.confirmed,
      ),
      isTrue,
    );
    expect(
      OrderPolicy.shouldReserveStock(
        OrderStatus.confirmed,
        OrderStatus.preparing,
      ),
      isFalse,
    );
  });

  test('reserved stock is restored when an active order is cancelled', () {
    expect(
      OrderPolicy.shouldRestoreStock(
        OrderStatus.confirmed,
        OrderStatus.cancelled,
      ),
      isTrue,
    );
    expect(
      OrderPolicy.shouldRestoreStock(
        OrderStatus.preparing,
        OrderStatus.cancelled,
      ),
      isTrue,
    );
    expect(
      OrderPolicy.shouldRestoreStock(
        OrderStatus.pending,
        OrderStatus.cancelled,
      ),
      isFalse,
    );
  });

  test('mixed item currencies produce one display-currency total', () {
    const items = [
      CartItem(
        productId: 'p1',
        sellerId: 'seller-a',
        productName: 'BIF item',
        imageRef: '',
        quantity: 1,
        unitPrice: 2900,
        currency: MarketCurrency.bif,
      ),
      CartItem(
        productId: 'p2',
        sellerId: 'seller-a',
        productName: 'USD item',
        imageRef: '',
        quantity: 1,
        unitPrice: 1,
        currency: MarketCurrency.usd,
      ),
    ];

    final total = OrderPolicy.displayTotal(
      items: items,
      displayCurrency: MarketCurrency.usd,
    );

    expect(total, closeTo(2, 0.0001));
  });
}
