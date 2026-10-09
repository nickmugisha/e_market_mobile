import 'package:flutter/material.dart';

enum FeaturedImageShape { roundedCard, circle, softBlob }

class FeaturedCardData {
  const FeaturedCardData({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientStart,
    required this.gradientEnd,
    required this.accent,
    this.imageRef = '',
    this.imageShape = FeaturedImageShape.roundedCard,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color gradientStart;
  final Color gradientEnd;
  final Color accent;

  // Kept for compatibility with the existing home-page data.
  // Featured cards now intentionally use illustrations instead of products.
  final String imageRef;
  final FeaturedImageShape imageShape;
}

class FeaturedCard extends StatelessWidget {
  const FeaturedCard({
    super.key,
    required this.data,
    this.showSwipeHint = false,
  });

  final FeaturedCardData data;
  final bool showSwipeHint;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [data.gradientStart, data.gradientEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: data.gradientEnd.withValues(alpha: 0.24),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Positioned(
              right: -62,
              top: -78,
              child: _GlowCircle(
                size: 220,
                color: data.accent.withValues(alpha: 0.17),
              ),
            ),

            Positioned(
              left: -85,
              bottom: -105,
              child: _GlowCircle(
                size: 230,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),

            Positioned(
              right: -28,
              bottom: -34,
              child: _GlowCircle(
                size: 185,
                color: Colors.white.withValues(alpha: 0.055),
              ),
            ),

            // Category illustration.
            Positioned(
              right: 14,
              bottom: 38,
              child: _ThreadIllustration(
                title: data.title,
                accent: data.accent,
              ),
            ),

            Positioned(
              right: 25,
              top: 24,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.13),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.17),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_outward_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Text(
                      data.eyebrow.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: 205,
                    child: Text(
                      data.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 31,
                        height: 0.98,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.35,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: 205,
                    child: Text(
                      data.subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.76),
                        fontSize: 13,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const Spacer(),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: data.accent,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: data.accent.withValues(alpha: 0.27),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Explore',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),

                      if (showSwipeHint) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(
                                Icons.swipe_rounded,
                                size: 17,
                                color: Colors.white.withValues(alpha: 0.55),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'SWIPE',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.50),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThreadIllustration extends StatelessWidget {
  const _ThreadIllustration({required this.title, required this.accent});

  final String title;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 142,
      height: 142,
      child: CustomPaint(
        painter: _ThreadIllustrationPainter(title: title, accent: accent),
      ),
    );
  }
}

class _ThreadIllustrationPainter extends CustomPainter {
  const _ThreadIllustrationPainter({required this.title, required this.accent});

  final String title;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = accent.withValues(alpha: 0.19)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white.withValues(alpha: 0.91);

    final softLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white.withValues(alpha: 0.35);

    final key = title.toLowerCase();

    if (key.contains('electronic')) {
      _drawElectronics(canvas, size, glow, line, softLine);
      return;
    }

    if (key.contains('style') || key.contains('fashion')) {
      _drawFashion(canvas, size, glow, line, softLine);
      return;
    }

    if (key.contains('home')) {
      _drawHome(canvas, size, glow, line, softLine);
      return;
    }

    _drawFreshPicks(canvas, size, glow, line, softLine);
  }

  void _drawFreshPicks(
    Canvas canvas,
    Size size,
    Paint glow,
    Paint line,
    Paint softLine,
  ) {
    final bag = Path()
      ..moveTo(size.width * 0.27, size.height * 0.39)
      ..quadraticBezierTo(
        size.width * 0.23,
        size.height * 0.40,
        size.width * 0.25,
        size.height * 0.49,
      )
      ..lineTo(size.width * 0.31, size.height * 0.79)
      ..quadraticBezierTo(
        size.width * 0.33,
        size.height * 0.85,
        size.width * 0.40,
        size.height * 0.85,
      )
      ..lineTo(size.width * 0.73, size.height * 0.85)
      ..quadraticBezierTo(
        size.width * 0.80,
        size.height * 0.85,
        size.width * 0.81,
        size.height * 0.78,
      )
      ..lineTo(size.width * 0.84, size.height * 0.48)
      ..quadraticBezierTo(
        size.width * 0.85,
        size.height * 0.40,
        size.width * 0.77,
        size.height * 0.39,
      );

    final handle = Path()
      ..moveTo(size.width * 0.40, size.height * 0.42)
      ..cubicTo(
        size.width * 0.41,
        size.height * 0.20,
        size.width * 0.67,
        size.height * 0.20,
        size.width * 0.69,
        size.height * 0.42,
      );

    canvas.drawPath(bag, glow);
    canvas.drawPath(handle, glow);

    canvas.drawPath(bag, line);
    canvas.drawPath(handle, line);

    _spark(canvas, Offset(size.width * 0.25, size.height * 0.25), 11, line);

    _spark(canvas, Offset(size.width * 0.82, size.height * 0.20), 7, softLine);

    final leaf = Path()
      ..moveTo(size.width * 0.56, size.height * 0.57)
      ..quadraticBezierTo(
        size.width * 0.44,
        size.height * 0.47,
        size.width * 0.46,
        size.height * 0.66,
      )
      ..quadraticBezierTo(
        size.width * 0.61,
        size.height * 0.68,
        size.width * 0.56,
        size.height * 0.57,
      );

    canvas.drawPath(leaf, line);
  }

  void _drawElectronics(
    Canvas canvas,
    Size size,
    Paint glow,
    Paint line,
    Paint softLine,
  ) {
    final headphones = Path()
      ..moveTo(size.width * 0.25, size.height * 0.60)
      ..cubicTo(
        size.width * 0.23,
        size.height * 0.25,
        size.width * 0.77,
        size.height * 0.25,
        size.width * 0.76,
        size.height * 0.60,
      );

    final leftCup = Path()
      ..moveTo(size.width * 0.27, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.18,
        size.height * 0.58,
        size.width * 0.23,
        size.height * 0.77,
      )
      ..quadraticBezierTo(
        size.width * 0.31,
        size.height * 0.82,
        size.width * 0.34,
        size.height * 0.70,
      );

    final rightCup = Path()
      ..moveTo(size.width * 0.74, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.83,
        size.height * 0.59,
        size.width * 0.78,
        size.height * 0.77,
      )
      ..quadraticBezierTo(
        size.width * 0.70,
        size.height * 0.82,
        size.width * 0.67,
        size.height * 0.70,
      );

    canvas.drawPath(headphones, glow);
    canvas.drawPath(leftCup, glow);
    canvas.drawPath(rightCup, glow);

    canvas.drawPath(headphones, line);
    canvas.drawPath(leftCup, line);
    canvas.drawPath(rightCup, line);

    final cable = Path()
      ..moveTo(size.width * 0.69, size.height * 0.74)
      ..cubicTo(
        size.width * 0.60,
        size.height * 0.94,
        size.width * 0.43,
        size.height * 0.84,
        size.width * 0.48,
        size.height * 0.73,
      );

    canvas.drawPath(cable, softLine);

    _spark(canvas, Offset(size.width * 0.82, size.height * 0.27), 8, line);
  }

  void _drawFashion(
    Canvas canvas,
    Size size,
    Paint glow,
    Paint line,
    Paint softLine,
  ) {
    final hanger = Path()
      ..moveTo(size.width * 0.28, size.height * 0.38)
      ..lineTo(size.width * 0.50, size.height * 0.25)
      ..lineTo(size.width * 0.74, size.height * 0.38)
      ..quadraticBezierTo(
        size.width * 0.77,
        size.height * 0.42,
        size.width * 0.70,
        size.height * 0.42,
      )
      ..lineTo(size.width * 0.31, size.height * 0.42)
      ..quadraticBezierTo(
        size.width * 0.24,
        size.height * 0.42,
        size.width * 0.28,
        size.height * 0.38,
      );

    final hook = Path()
      ..moveTo(size.width * 0.50, size.height * 0.25)
      ..cubicTo(
        size.width * 0.46,
        size.height * 0.18,
        size.width * 0.55,
        size.height * 0.13,
        size.width * 0.58,
        size.height * 0.21,
      );

    final dress = Path()
      ..moveTo(size.width * 0.43, size.height * 0.44)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.54,
        size.width * 0.38,
        size.height * 0.64,
      )
      ..lineTo(size.width * 0.29, size.height * 0.84)
      ..quadraticBezierTo(
        size.width * 0.49,
        size.height * 0.91,
        size.width * 0.71,
        size.height * 0.84,
      )
      ..lineTo(size.width * 0.62, size.height * 0.64)
      ..quadraticBezierTo(
        size.width * 0.55,
        size.height * 0.54,
        size.width * 0.57,
        size.height * 0.44,
      );

    canvas.drawPath(hanger, glow);
    canvas.drawPath(hook, glow);
    canvas.drawPath(dress, glow);

    canvas.drawPath(hanger, line);
    canvas.drawPath(hook, line);
    canvas.drawPath(dress, line);

    final fabric = Path()
      ..moveTo(size.width * 0.41, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.77,
        size.width * 0.59,
        size.height * 0.72,
      );

    canvas.drawPath(fabric, softLine);
  }

  void _drawHome(
    Canvas canvas,
    Size size,
    Paint glow,
    Paint line,
    Paint softLine,
  ) {
    final pan = Path()
      ..moveTo(size.width * 0.20, size.height * 0.58)
      ..quadraticBezierTo(
        size.width * 0.24,
        size.height * 0.77,
        size.width * 0.47,
        size.height * 0.78,
      )
      ..quadraticBezierTo(
        size.width * 0.68,
        size.height * 0.77,
        size.width * 0.70,
        size.height * 0.58,
      )
      ..lineTo(size.width * 0.20, size.height * 0.58);

    final handle = Path()
      ..moveTo(size.width * 0.68, size.height * 0.61)
      ..quadraticBezierTo(
        size.width * 0.80,
        size.height * 0.55,
        size.width * 0.91,
        size.height * 0.46,
      );

    canvas.drawPath(pan, glow);
    canvas.drawPath(handle, glow);

    canvas.drawPath(pan, line);
    canvas.drawPath(handle, line);

    final steam1 = Path()
      ..moveTo(size.width * 0.38, size.height * 0.48)
      ..cubicTo(
        size.width * 0.29,
        size.height * 0.38,
        size.width * 0.45,
        size.height * 0.33,
        size.width * 0.38,
        size.height * 0.23,
      );

    final steam2 = Path()
      ..moveTo(size.width * 0.55, size.height * 0.48)
      ..cubicTo(
        size.width * 0.47,
        size.height * 0.40,
        size.width * 0.61,
        size.height * 0.34,
        size.width * 0.55,
        size.height * 0.26,
      );

    canvas.drawPath(steam1, softLine);
    canvas.drawPath(steam2, softLine);

    _spark(canvas, Offset(size.width * 0.78, size.height * 0.25), 7, line);
  }

  void _spark(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx, center.dy + radius)
      ..moveTo(center.dx - radius, center.dy)
      ..lineTo(center.dx + radius, center.dy);

    canvas.drawPath(path, paint);

    final diagonal = radius * 0.52;

    final secondary = Path()
      ..moveTo(center.dx - diagonal, center.dy - diagonal)
      ..lineTo(center.dx + diagonal, center.dy + diagonal)
      ..moveTo(center.dx + diagonal, center.dy - diagonal)
      ..lineTo(center.dx - diagonal, center.dy + diagonal);

    canvas.drawPath(secondary, paint);
  }

  @override
  bool shouldRepaint(covariant _ThreadIllustrationPainter oldDelegate) {
    return oldDelegate.title != title || oldDelegate.accent != accent;
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
