import 'package:e_market/features/catalogue/domain/catalogue_filter.dart';
import 'package:e_market/features/catalogue/domain/product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const products = [
    Product(
      id: 'p1',
      sellerId: 's1',
      sellerName: 'Aline Shop',
      sellerWhatsapp: '+25770000001',
      name: 'Blue Shoes',
      description: 'Comfortable everyday shoes',
      categoryId: 'fashion',
      categoryName: 'Fashion',
      price: 50000,
      currency: MarketCurrency.bif,
      stock: 4,
      imageRef: '',
      active: true,
    ),
    Product(
      id: 'p2',
      sellerId: 's2',
      sellerName: 'Tech House',
      sellerWhatsapp: '+25770000002',
      name: 'Wireless Headphones',
      description: 'Bluetooth audio',
      categoryId: 'electronics',
      categoryName: 'Electronics',
      price: 40,
      currency: MarketCurrency.usd,
      stock: 0,
      imageRef: '',
      active: true,
    ),
  ];

  test('search matches product name, category and seller', () {
    expect(
      CatalogueFilter.apply(products: products, query: 'shoes')
          .map((product) => product.id),
      ['p1'],
    );
    expect(
      CatalogueFilter.apply(products: products, query: 'electronics')
          .map((product) => product.id),
      ['p2'],
    );
    expect(
      CatalogueFilter.apply(products: products, query: 'aline')
          .map((product) => product.id),
      ['p1'],
    );
  });

  test('category and in-stock filters combine', () {
    expect(
      CatalogueFilter.apply(
        products: products,
        categoryId: 'electronics',
        inStockOnly: true,
      ),
      isEmpty,
    );
    expect(
      CatalogueFilter.apply(
        products: products,
        categoryId: 'fashion',
        inStockOnly: true,
      ).map((product) => product.id),
      ['p1'],
    );
  });

  test('legacy products keep a safe seller label', () {
    final product = Product.fromMap('legacy', {
      'sellerId': 's1',
      'name': 'Legacy product',
      'description': 'Old LOT 4 product',
      'categoryId': 'other',
      'categoryName': 'Other',
      'price': 1000,
      'currency': 'BIF',
      'stock': 1,
      'imageRef': '',
      'active': true,
    });

    expect(product.displaySellerName, 'e-market seller');
    expect(product.sellerWhatsapp, isEmpty);
  });
}
