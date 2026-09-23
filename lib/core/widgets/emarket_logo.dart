import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class EMarketLogo extends StatelessWidget {
  const EMarketLogo({
    super.key,
    this.size = 96,
    this.showWordmark = false,
    this.onDark = true,
  });

  final double size;
  final bool showWordmark;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final icon = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.shopping_bag_rounded,
            size: size * 0.52,
            color: AppColors.ink,
          ),
          Positioned(
            right: size * 0.18,
            bottom: size * 0.18,
            child: Container(
              width: size * 0.26,
              height: size * 0.26,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bolt_rounded,
                size: size * 0.16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (!showWordmark) return icon;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 12),
        Text(
          'e-market',
          style: TextStyle(
            color: onDark ? Colors.white : AppColors.ink,
            fontSize: size * 0.28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
      ],
    );
  }
}
