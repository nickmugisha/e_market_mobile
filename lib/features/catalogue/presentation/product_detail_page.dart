import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/product_image.dart';
import '../../auth/domain/user_profile.dart';
import '../../cart/data/cart_repository.dart';
import '../../cart/presentation/cart_page.dart';
import '../data/product_repository.dart';
import '../domain/product.dart';

class ProductDetailPage extends StatelessWidget {
  ProductDetailPage({
    super.key,
    required this.productId,
    required this.initialProduct,
    this.profile,
    this.onSignInRequested,
  });

  final String productId;
  final Product initialProduct;
  final UserProfile? profile;
  final Future<void> Function()? onSignInRequested;

  final ProductRepository _products = ProductRepository();
  final CartRepository _cart = CartRepository();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Product?>(
      stream: _products.watchProduct(productId),
      initialData: initialProduct,
      builder: (context, snapshot) {
        if (snapshot.hasError || snapshot.data == null) {
          return const _UnavailableProductPage();
        }

        final product = snapshot.data!;

        return Scaffold(
          backgroundColor: AppColors.canvas,
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            title: const Text('Product details'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
            children: [
              Container(
                height: 340,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.line),
                ),
                child: ProductImage(
                  imageRef: product.imageRef,
                  width: double.infinity,
                  height: 340,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 28,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _StockBadge(stock: product.stock),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${product.currency.code} ${_price(product.price)}',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.category_outlined,
                    label: product.categoryName,
                  ),
                  _InfoChip(
                    icon: Icons.storefront_outlined,
                    label: product.displaySellerName,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'About this product',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.description.trim().isEmpty
                    ? 'No description was provided.'
                    : product.description.trim(),
                style: const TextStyle(
                  color: AppColors.muted,
                  height: 1.55,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 24),
              _SellerCard(product: product),
            ],
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            child: FilledButton.icon(
              onPressed: product.stock <= 0
                  ? null
                  : () => _handlePrimaryAction(context, product),
              icon: Icon(
                profile == null
                    ? Icons.login_rounded
                    : Icons.shopping_bag_outlined,
              ),
              label: Text(
                product.stock <= 0
                    ? 'Currently sold out'
                    : profile == null
                        ? 'Sign in to buy'
                        : profile!.role == UserRole.client
                            ? 'Add to cart'
                            : 'Client account required',
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handlePrimaryAction(
    BuildContext context,
    Product product,
  ) async {
    if (profile == null) {
      if (onSignInRequested != null) {
        await onSignInRequested!();
      }
      return;
    }

    if (profile!.role != UserRole.client) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Use a client account to add marketplace products to a cart.',
            ),
          ),
        );
      return;
    }

    try {
      await _cart.addProduct(
        clientUid: profile!.uid,
        productId: product.id,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('Added to cart.'),
            action: SnackBarAction(
              label: 'View cart',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CartPage(profile: profile!),
                  ),
                );
              },
            ),
          ),
        );
    } on CartFailure catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Could not add this product to the cart.'),
          ),
        );
    }
  }

  String _price(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
  }
}

class _SellerCard extends StatelessWidget {
  const _SellerCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final whatsapp = product.sellerWhatsapp.trim();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sold by',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.displaySellerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (whatsapp.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    'WhatsApp: $whatsapp',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.stock});

  final int stock;

  @override
  Widget build(BuildContext context) {
    final available = stock > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: available ? AppColors.accentSoft : AppColors.ink,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        available ? '$stock in stock' : 'Sold out',
        style: TextStyle(
          color: available ? AppColors.accent : Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.muted),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnavailableProductPage extends StatelessWidget {
  const _UnavailableProductPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 52,
                color: AppColors.accent,
              ),
              SizedBox(height: 14),
              Text(
                'Product unavailable',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'This product may have been removed or hidden by the seller.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
