import 'package:flutter/material.dart';

import '../../features/catalogue/utils/product_image_codec.dart';
import '../theme/app_theme.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.imageRef,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final String imageRef;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final bytes = ProductImageCodec.decode(imageRef);

    Widget child;
    if (bytes != null) {
      child = Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    } else if (imageRef.startsWith('http://') ||
        imageRef.startsWith('https://')) {
      child = Image.network(
        imageRef,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    } else {
      child = _placeholder();
    }

    if (borderRadius == null) return child;

    return ClipRRect(borderRadius: borderRadius!, child: child);
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.canvas,
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, color: AppColors.muted, size: 34),
    );
  }
}
