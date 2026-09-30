import 'package:e_market/core/currency/currency_service.dart';
import 'package:e_market/features/cart/domain/cart_item.dart';
import 'package:e_market/features/cart/domain/cart_policy.dart';
import 'package:e_market/features/catalogue/domain/product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const currency = CurrencyService();

  test('currency conversion uses BIF as the pivot', () {
    expect(
      currency.convert(
        amount: 2900,
        from: MarketCurrency.bif,
        to: MarketCurrency.usd,
      ),
      closeTo(1, 0.0001),
    );

    expect(
      currency.convert(
        amount: 1,
        from: MarketCurrency.usd,
        to: MarketCurrency.bif,
      ),
      2900,
    );

    expect(
      currency.convert(
        amount: 3150,
        from: MarketCurrency.bif,
        to: MarketCurrency.eur,
      ),
      closeTo(1, 0.0001),
    );
  });

  test('single-seller policy rejects a different seller', () {
    const items = [
      CartItem(
        productId: 'p1',
        sellerId: 'seller-a',
        productName: 'Product A',
        imageRef: '',
        quantity: 1,
        unitPrice: 1000,
        currency: MarketCurrency.bif,
      ),
    ];

    expect(
      CartPolicy.conflictingSellerId(
        currentItems: items,
        newSellerId: 'seller-a',
      ),
      isNull,
    );

    expect(
      CartPolicy.conflictingSellerId(
        currentItems: items,
        newSellerId: 'seller-b',
      ),
      'seller-a',
    );
  });

  test('stock validation catches unavailable and insufficient stock', () {
    const items = [
      CartItem(
        productId: 'p1',
        sellerId: 'seller-a',
        productName: 'Product A',
        imageRef: '',
        quantity: 3,
        unitPrice: 1000,
        currency: MarketCurrency.bif,
      ),
      CartItem(
        productId: 'p2',
        sellerId: 'seller-a',
        productName: 'Product B',
        imageRef: '',
        quantity: 1,
        unitPrice: 2000,
        currency: MarketCurrency.bif,
      ),
    ];

    const activeProducts = [
      Product(
        id: 'p1',
        sellerId: 'seller-a',
        name: 'Product A',
        description: '',
        categoryId: 'cat',
        categoryName: 'Category',
        price: 1000,
        currency: MarketCurrency.bif,
        stock: 2,
        imageRef: '',
        active: true,
      ),
    ];

    final issues = CartPolicy.validateStock(
      items: items,
      activeProducts: activeProducts,
    );

    expect(issues, hasLength(2));
    expect(
      issues.any(
        (issue) =>
            issue.productId == 'p1' &&
            issue.type == CartIssueType.insufficientStock,
      ),
      isTrue,
    );
    expect(
      issues.any(
        (issue) =>
            issue.productId == 'p2' &&
            issue.type == CartIssueType.unavailable,
      ),
      isTrue,
    );
  });
}
