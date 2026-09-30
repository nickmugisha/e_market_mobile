import 'package:e_market/features/home/presentation/widgets/featured_card.dart';
import 'package:e_market/features/home/presentation/widgets/stacked_featured_deck.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const items = [
    FeaturedCardData(
      eyebrow: 'One',
      title: 'Fresh picks',
      subtitle: 'First card',
      icon: Icons.auto_awesome_rounded,
      gradientStart: Color(0xFF101826),
      gradientEnd: Color(0xFF243A59),
      accent: Color(0xFF4C9BFF),
    ),
    FeaturedCardData(
      eyebrow: 'Two',
      title: 'Electronics',
      subtitle: 'Second card',
      icon: Icons.headphones_rounded,
      gradientStart: Color(0xFF073B4C),
      gradientEnd: Color(0xFF116B86),
      accent: Color(0xFF27B8E6),
    ),
    FeaturedCardData(
      eyebrow: 'Three',
      title: 'Style drop',
      subtitle: 'Third card',
      icon: Icons.checkroom_rounded,
      gradientStart: Color(0xFF2A1738),
      gradientEnd: Color(0xFF6F3A88),
      accent: Color(0xFFC16BF0),
    ),
    FeaturedCardData(
      eyebrow: 'Four',
      title: 'Home essentials',
      subtitle: 'Fourth card',
      icon: Icons.chair_alt_rounded,
      gradientStart: Color(0xFF153229),
      gradientEnd: Color(0xFF2D6B59),
      accent: Color(0xFF55C59F),
    ),
  ];

  testWidgets('top featured card swipes away and reveals the next card',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 380,
              child: FeaturedCardDeck(items: items),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Fresh picks'), findsOneWidget);

    await tester.fling(
      find.byType(FeaturedCardDeck),
      const Offset(-520, 0),
      1200,
    );
    await tester.pumpAndSettle();

    expect(find.text('Fresh picks'), findsNothing);
    expect(find.text('Electronics'), findsOneWidget);
  });
}
