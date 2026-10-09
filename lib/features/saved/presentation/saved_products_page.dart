import 'package:flutter/material.dart';

import '../../../core/navigation/app_transitions.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/domain/user_profile.dart';
import '../../catalogue/data/product_repository.dart';
import '../../catalogue/domain/product.dart';
import '../../catalogue/presentation/product_detail_page.dart';
import '../../catalogue/presentation/widgets/catalogue_product_card.dart';
import '../data/saved_product_repository.dart';

class SavedProductsPage extends StatelessWidget {
  SavedProductsPage({super.key, required this.profile});

  final UserProfile profile;
  final SavedProductRepository _saved = SavedProductRepository();
  final ProductRepository _products = ProductRepository();

  @override
  Widget build(BuildContext context) {
    if (profile.role != UserRole.client) {
      return Scaffold(
        backgroundColor: AppColors.canvasFor(context),
        appBar: AppBar(
          title: const Text('Saved'),
          backgroundColor: AppColors.surfaceFor(context),
          surfaceTintColor: AppColors.surfaceFor(context),
        ),
        body: const _SavedMessage(
          icon: Icons.lock_outline_rounded,
          title: 'Client feature',
          message: 'Saved products are available to client accounts.',
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.canvasFor(context),
      appBar: AppBar(
        title: const Text('Saved products'),
        backgroundColor: AppColors.surfaceFor(context),
        surfaceTintColor: AppColors.surfaceFor(context),
      ),
      body: StreamBuilder<Set<String>>(
        stream: _saved.watchSavedIds(profile.uid),
        builder: (context, savedSnapshot) {
          if (savedSnapshot.connectionState == ConnectionState.waiting &&
              !savedSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (savedSnapshot.hasError) {
            return const _SavedMessage(
              icon: Icons.cloud_off_rounded,
              title: 'Saved products unavailable',
              message: 'Check your connection and Firestore permissions.',
            );
          }

          final savedIds = savedSnapshot.data ?? <String>{};

          if (savedIds.isEmpty) {
            return const _SavedMessage(
              icon: Icons.favorite_border_rounded,
              title: 'Nothing saved yet',
              message:
                  'Open a product and tap the heart to keep it here for later.',
            );
          }

          return StreamBuilder<List<Product>>(
            stream: _products.watchActiveProducts(),
            builder: (context, productSnapshot) {
              if (productSnapshot.connectionState == ConnectionState.waiting &&
                  !productSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (productSnapshot.hasError) {
                return const _SavedMessage(
                  icon: Icons.cloud_off_rounded,
                  title: 'Marketplace unavailable',
                  message: 'Saved items could not be matched to the catalogue.',
                );
              }

              final products = (productSnapshot.data ?? const <Product>[])
                  .where((product) => savedIds.contains(product.id))
                  .toList();

              if (products.isEmpty) {
                return const _SavedMessage(
                  icon: Icons.inventory_2_outlined,
                  title: 'Saved items are unavailable',
                  message:
                      'The products you saved may have been hidden or removed by their sellers.',
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
                itemCount: products.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.67,
                ),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return CatalogueProductCard(
                    product: product,
                    onTap: () {
                      Navigator.of(context).push(
                        smoothRoute(
                          ProductDetailPage(
                            productId: product.id,
                            initialProduct: product,
                            profile: profile,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _SavedMessage extends StatelessWidget {
  const _SavedMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: AppColors.accent),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
