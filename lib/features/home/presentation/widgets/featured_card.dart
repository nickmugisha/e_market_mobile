import 'package:flutter/material.dart';


class FeaturedCardData {
  const FeaturedCardData({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientStart,
    required this.gradientEnd,
    required this.accent,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color gradientStart;
  final Color gradientEnd;
  final Color accent;
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
          colors: [
            data.gradientStart,
            data.gradientEnd,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: data.gradientEnd.withValues(alpha: 0.28),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Positioned(
              right: -58,
              top: -72,
              child: _GlowCircle(
                size: 210,
                color: data.accent.withValues(alpha: 0.18),
              ),
            ),
            Positioned(
              left: -72,
              bottom: -96,
              child: _GlowCircle(
                size: 220,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
            Positioned(
              right: 22,
              bottom: 28,
              child: Transform.rotate(
                angle: -0.08,
                child: Container(
                  width: 118,
                  height: 118,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Icon(
                    data.icon,
                    size: 62,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 28,
              top: 26,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
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
                      color: Colors.white.withValues(alpha: 0.12),
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
                    width: 235,
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
                    width: 225,
                    child: Text(
                      data.subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
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
                              color: data.accent.withValues(alpha: 0.28),
                              blurRadius: 16,
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(
                                Icons.swipe_rounded,
                                size: 18,
                                color: Colors.white.withValues(alpha: 0.56),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'SWIPE',
                                style: TextStyle(
                                  color:
                                      Colors.white.withValues(alpha: 0.50),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
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

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
