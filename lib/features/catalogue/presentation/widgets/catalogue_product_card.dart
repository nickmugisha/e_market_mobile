import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/product_image.dart';
import '../../domain/product.dart';

class CatalogueProductCard extends StatelessWidget {
  const CatalogueProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final inStock = product.stock > 0;
    final dark = Theme.of(context).brightness == Brightness.dark;

    final surface = AppColors.surfaceFor(context);
    final line = AppColors.lineFor(context);
    final text = AppColors.textFor(context);
    final muted = AppColors.mutedFor(context);

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: line),
            boxShadow: [
              BoxShadow(
                color: dark
                    ? Colors.black.withValues(alpha: 0.22)
                    : AppColors.ink.withValues(alpha: 0.045),
                blurRadius: dark ? 16 : 20,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ProductImage(
                        imageRef: product.imageRef,
                        fit: BoxFit.cover,
                      ),
                      const Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: [0.40, 1],
                              colors: [Colors.transparent, Color(0x660D0F14)],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: _StockPill(stock: product.stock),
                      ),
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: dark
                                ? AppColors.darkElevated.withValues(alpha: 0.94)
                                : Colors.white.withValues(alpha: 0.92),
                            shape: BoxShape.circle,
                            border: dark
                                ? Border.all(color: AppColors.darkLine)
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: dark ? 0.22 : 0.07,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_outward_rounded,
                            size: 17,
                            color: dark ? AppColors.accent : AppColors.ink,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 11,
                        right: 11,
                        bottom: 10,
                        child: Text(
                          product.displaySellerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 5),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(13, 12, 13, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.categoryName.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: dark
                                    ? AppColors.leafGlow
                                    : AppColors.accentStrong,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.7,
                              ),
                            ),
                          ),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: inStock
                                  ? const Color(0xFF4FB887)
                                  : AppColors.danger,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: text,
                          fontSize: 15,
                          height: 1.12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.25,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              '${product.currency.code} ${_price(product.price)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: text,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.25,
                              ),
                            ),
                          ),
                          Text(
                            inStock ? 'AVAILABLE' : 'SOLD OUT',
                            style: TextStyle(
                              color: inStock ? muted : AppColors.danger,
                              fontSize: 7.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.55,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _price(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
  }
}

class _StockPill extends StatelessWidget {
  const _StockPill({required this.stock});

  final int stock;

  @override
  Widget build(BuildContext context) {
    final inStock = stock > 0;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: inStock
            ? dark
                  ? AppColors.darkElevated.withValues(alpha: 0.94)
                  : Colors.white.withValues(alpha: 0.94)
            : AppColors.ink.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
        border: dark && inStock ? Border.all(color: AppColors.darkLine) : null,
      ),
      child: Text(
        inStock ? '$stock left' : 'Sold out',
        style: TextStyle(
          color: inStock
              ? dark
                    ? AppColors.darkText
                    : AppColors.ink
              : Colors.white,
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
