import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class LeafBagLoader extends StatefulWidget {
  const LeafBagLoader({
    super.key,
    this.message,
    this.size = 118,
    this.compact = false,
  });

  final String? message;
  final double size;
  final bool compact;

  @override
  State<LeafBagLoader> createState() => _LeafBagLoaderState();
}

class _LeafBagLoaderState extends State<LeafBagLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final p = _controller.value;
        final pulse = 1 + (math.sin(p * math.pi * 2) * 0.035);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: widget.size * 0.78,
                    height: widget.size * 0.78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentSoft.withValues(alpha: 0.72),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.leafGlow.withValues(alpha: 0.25),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),

                  Transform.scale(
                    scale: pulse,
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      size: widget.size * 0.53,
                      color: AppColors.ink,
                    ),
                  ),

                  ...List.generate(3, (index) {
                    final local = (p + (index * 0.33)) % 1.0;

                    final x = <double>[-0.24, 0.18, -0.02][index];

                    final y = -0.42 + (local * 0.55);

                    final opacity = math.sin(local * math.pi).clamp(0.0, 1.0);

                    return Transform.translate(
                      offset: Offset(widget.size * x, widget.size * y),
                      child: Transform.rotate(
                        angle: (local * 1.4) - 0.7,
                        child: Opacity(
                          opacity: opacity,
                          child: Icon(
                            Icons.eco_rounded,
                            size: widget.size * 0.17,
                            color: index == 1
                                ? AppColors.leafGlow
                                : AppColors.accentStrong,
                          ),
                        ),
                      ),
                    );
                  }),

                  SizedBox(
                    width: widget.size * 0.30,
                    height: widget.size * 0.30,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      color: AppColors.accentStrong,
                      backgroundColor: Colors.white.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),

            if (widget.message != null) ...[
              SizedBox(height: widget.compact ? 8 : 14),
              Text(
                widget.message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: widget.compact ? 11 : 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
