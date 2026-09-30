import 'package:e_market/features/catalogue/domain/product.dart';
import 'package:e_market/features/catalogue/presentation/widgets/catalogue_product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('premium product card keeps key shopping information visible',
      (tester) async {
    const product = Product(
      id: 'p1',
      sellerId: 'seller-a',
      sellerName: 'Test Seller',
      sellerWhatsapp: '25779123456',
      name: 'Premium Headphones',
      description: 'A test product',
      categoryId: 'electronics',
      categoryName: 'Electronics',
      price: 25000,
      currency: MarketCurrency.bif,
      stock: 5,
      imageRef: '',
      active: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 190,
              height: 285,
              child: CatalogueProductCard(
                product: product,
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Premium Headphones'), findsOneWidget);
    expect(find.text('Test Seller'), findsOneWidget);
    expect(find.text('5 left'), findsOneWidget);
    expect(find.text('BIF 25000'), findsOneWidget);
    expect(find.text('ELECTRONICS'), findsOneWidget);
  });
}
