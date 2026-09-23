import 'package:e_market/features/cart/domain/cart_item.dart';
import 'package:e_market/features/catalogue/domain/product.dart';
import 'package:e_market/features/orders/domain/order_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LOT 3 models', () {
    test('currency parsing is stable', () {
      expect(MarketCurrency.fromValue('USD'), MarketCurrency.usd);
      expect(MarketCurrency.fromValue('eur'), MarketCurrency.eur);
      expect(MarketCurrency.fromValue(null), MarketCurrency.bif);
    });

    test('cart subtotal uses quantity and unit price', () {
      final item = CartItem(
        productId: 'p1',
        sellerId: 'seller1',
        productName: 'Test',
        imageRef: '',
        quantity: 3,
        unitPrice: 2500,
        currency: MarketCurrency.bif,
      );

      expect(item.subtotal, 7500);
    });

    test('order enum parsing has safe defaults', () {
      expect(OrderStatus.fromValue('ready'), OrderStatus.ready);
      expect(OrderStatus.fromValue('unknown'), OrderStatus.pending);
      expect(FulfillmentType.fromValue('pickup'), FulfillmentType.pickup);
      expect(PaymentMethod.fromValue('mobile_money'), PaymentMethod.mobileMoney);
      expect(PaymentStatus.fromValue('paid'), PaymentStatus.paid);
    });
  });
}
