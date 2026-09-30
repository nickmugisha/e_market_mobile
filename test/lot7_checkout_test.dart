import 'package:e_market/features/cart/domain/cart_item.dart';
import 'package:e_market/features/catalogue/domain/product.dart';
import 'package:e_market/features/checkout/domain/checkout_validator.dart';
import 'package:e_market/features/checkout/services/payment_simulator.dart';
import 'package:e_market/features/orders/domain/order_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const item = CartItem(
    productId: 'p1',
    sellerId: 'seller-a',
    productName: 'Product A',
    imageRef: '',
    quantity: 2,
    unitPrice: 1000,
    currency: MarketCurrency.bif,
  );

  const product = Product(
    id: 'p1',
    sellerId: 'seller-a',
    name: 'Product A',
    description: '',
    categoryId: 'cat',
    categoryName: 'Category',
    price: 1000,
    currency: MarketCurrency.bif,
    stock: 5,
    imageRef: '',
    active: true,
  );

  test('delivery checkout requires an address', () {
    final result = CheckoutValidator.validate(
      items: const [item],
      activeProducts: const [product],
      fulfillmentType: FulfillmentType.delivery,
      deliveryAddress: '',
    );

    expect(result.isValid, isFalse);
    expect(
      result.errors,
      contains('Enter a complete delivery address.'),
    );
  });

  test('pickup checkout does not require an address', () {
    final result = CheckoutValidator.validate(
      items: const [item],
      activeProducts: const [product],
      fulfillmentType: FulfillmentType.pickup,
      deliveryAddress: '',
    );

    expect(result.isValid, isTrue);
  });

  test('checkout rejects changed stock', () {
    final result = CheckoutValidator.validate(
      items: const [item],
      activeProducts: const [
        Product(
          id: 'p1',
          sellerId: 'seller-a',
          name: 'Product A',
          description: '',
          categoryId: 'cat',
          categoryName: 'Category',
          price: 1000,
          currency: MarketCurrency.bif,
          stock: 1,
          imageRef: '',
          active: true,
        ),
      ],
      fulfillmentType: FulfillmentType.pickup,
      deliveryAddress: '',
    );

    expect(result.isValid, isFalse);
    expect(
      result.errors.any((error) => error.contains('only has 1 item left')),
      isTrue,
    );
  });

  test('simulated cash remains pending', () async {
    const simulator = PaymentSimulator();

    final result = await simulator.process(PaymentMethod.cash);

    expect(result.status, PaymentStatus.pending);
    expect(result.reference, startsWith('SIM-'));
  });

  test('simulated digital payments are marked paid', () async {
    const simulator = PaymentSimulator();

    final mobile = await simulator.process(PaymentMethod.mobileMoney);
    final card = await simulator.process(PaymentMethod.card);

    expect(mobile.status, PaymentStatus.paid);
    expect(card.status, PaymentStatus.paid);
  });
}
