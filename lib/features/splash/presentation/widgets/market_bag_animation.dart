import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class MarketBagAnimation extends StatelessWidget {
  const MarketBagAnimation({
    super.key,
    required this.progress,
  });

  final double progress;

  @override
  Widget build(BuildContext context) {
    final bagEntrance = _interval(
      progress,
      0.03,
      0.28,
      Curves.easeOutBack,
    );
    final highlightProgress = _interval(
      progress,
      0.52,
      0.77,
      Curves.easeOutCubic,
    );

    final settle = _interval(
      progress,
      0.28,
      0.72,
      Curves.easeInOut,
    );

    final bob = math.sin(settle * math.pi * 2) * 2.6 * (1 - settle);

    return SizedBox(
      width: 310,
      height: 315,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _FlyingStrokesPainter(
                progress: progress,
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(0, bob - 2),
            child: Transform.scale(
              scale: 0.76 + (0.24 * bagEntrance),
              child: Opacity(
                opacity: bagEntrance.clamp(0.0, 1.0),
                child: Container(
                  width: 184,
                  height: 196,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(48),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ink.withValues(alpha: 0.08),
                        blurRadius: 42,
                        offset: const Offset(0, 22),
                      ),
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.10),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    painter: _BagPainter(
                      reveal: bagEntrance,
                      impact: _interval(
                        progress,
                        0.30,
                        0.64,
                        Curves.easeOut,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 36,
            right: 36,
            height: 54,
            child: CustomPaint(
              painter: _HighlightPainter(
                progress: highlightProgress,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static double _interval(
    double value,
    double begin,
    double end,
    Curve curve,
  ) {
    if (value <= begin) return 0;
    if (value >= end) return 1;

    final normalized = (value - begin) / (end - begin);
    return curve.transform(normalized);
  }
}

class _BagPainter extends CustomPainter {
  const _BagPainter({
    required this.reveal,
    required this.impact,
  });

  final double reveal;
  final double impact;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final bagRect = Rect.fromLTWH(
      size.width * 0.19,
      size.height * 0.31,
      size.width * 0.62,
      size.height * 0.51,
    );

    final bagPath = Path()
      ..moveTo(bagRect.left + 12, bagRect.top + 5)
      ..quadraticBezierTo(
        bagRect.left + 3,
        bagRect.top + 5,
        bagRect.left,
        bagRect.top + 18,
      )
      ..lineTo(bagRect.left + 9, bagRect.bottom - 15)
      ..quadraticBezierTo(
        bagRect.left + 11,
        bagRect.bottom,
        bagRect.left + 28,
        bagRect.bottom + 2,
      )
      ..lineTo(bagRect.right - 28, bagRect.bottom + 2)
      ..quadraticBezierTo(
        bagRect.right - 11,
        bagRect.bottom,
        bagRect.right - 9,
        bagRect.bottom - 15,
      )
      ..lineTo(bagRect.right, bagRect.top + 18)
      ..quadraticBezierTo(
        bagRect.right - 3,
        bagRect.top + 5,
        bagRect.right - 12,
        bagRect.top + 5,
      )
      ..close();

    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFF8FBFF);

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = AppColors.ink.withValues(alpha: 0.90 * reveal);

    canvas.drawPath(bagPath, fill);
    canvas.drawPath(bagPath, outline);

    final handle = Path()
      ..moveTo(size.width * 0.35, bagRect.top + 11)
      ..cubicTo(
        size.width * 0.36,
        size.height * 0.15,
        size.width * 0.64,
        size.height * 0.15,
        size.width * 0.65,
        bagRect.top + 11,
      );

    canvas.drawPath(
      handle,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = AppColors.ink.withValues(alpha: 0.86 * reveal),
    );

    final lipY = bagRect.top + 20;
    final lipPath = Path()
      ..moveTo(bagRect.left + 12, lipY)
      ..quadraticBezierTo(
        centerX,
        lipY + (7 * impact),
        bagRect.right - 12,
        lipY,
      );

    canvas.drawPath(
      lipPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.3
        ..strokeCap = StrokeCap.round
        ..color = AppColors.accent.withValues(alpha: 0.70),
    );

    final badgeCenter = Offset(
      centerX,
      bagRect.top + bagRect.height * 0.56,
    );

    canvas.drawCircle(
      badgeCenter,
      28,
      Paint()
        ..color = AppColors.accentSoft.withValues(alpha: 0.95),
    );

    canvas.drawCircle(
      badgeCenter,
      27,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = AppColors.accent.withValues(alpha: 0.18),
    );

    final sparkPaint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 4.4
      ..strokeCap = StrokeCap.round;

    final spark = Path()
      ..moveTo(badgeCenter.dx - 2, badgeCenter.dy - 14)
      ..lineTo(badgeCenter.dx - 8, badgeCenter.dy + 1)
      ..lineTo(badgeCenter.dx + 1, badgeCenter.dy - 1)
      ..lineTo(badgeCenter.dx - 3, badgeCenter.dy + 15)
      ..lineTo(badgeCenter.dx + 11, badgeCenter.dy - 4)
      ..lineTo(badgeCenter.dx + 3, badgeCenter.dy - 2);

    canvas.drawPath(spark, sparkPaint);
  }

  @override
  bool shouldRepaint(covariant _BagPainter oldDelegate) {
    return oldDelegate.reveal != reveal || oldDelegate.impact != impact;
  }
}

class _FlyingStrokesPainter extends CustomPainter {
  const _FlyingStrokesPainter({
    required this.progress,
  });

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final target = Offset(size.width / 2, size.height * 0.37);

    final strokes = <_StrokeSpec>[
      _StrokeSpec(
        start: Offset(size.width * 0.02, size.height * 0.22),
        targetOffset: const Offset(-21, -7),
        begin: 0.13,
        end: 0.42,
        length: 25,
        width: 4.2,
        color: AppColors.accent,
      ),
      _StrokeSpec(
        start: Offset(size.width * 0.96, size.height * 0.19),
        targetOffset: const Offset(24, -5),
        begin: 0.19,
        end: 0.49,
        length: 30,
        width: 4.8,
        color: Color(0xFF93C7FF),
      ),
      _StrokeSpec(
        start: Offset(size.width * 0.28, -6),
        targetOffset: const Offset(-10, -14),
        begin: 0.24,
        end: 0.53,
        length: 22,
        width: 3.7,
        color: AppColors.ink,
      ),
      _StrokeSpec(
        start: Offset(size.width * 0.80, size.height * 0.02),
        targetOffset: const Offset(14, -14),
        begin: 0.30,
        end: 0.59,
        length: 18,
        width: 3.5,
        color: Color(0xFF4C9BFF),
      ),
      _StrokeSpec(
        start: Offset(-10, size.height * 0.47),
        targetOffset: const Offset(-27, 0),
        begin: 0.34,
        end: 0.63,
        length: 17,
        width: 3.2,
        color: Color(0xFFB6D8FF),
      ),
    ];

    for (final spec in strokes) {
      final p = _interval(
        progress,
        spec.begin,
        spec.end,
        Curves.easeInCubic,
      );

      if (p <= 0 || p >= 1) continue;

      final destination = target + spec.targetOffset;
      final current = Offset.lerp(spec.start, destination, p)!;

      final direction = destination - spec.start;
      final magnitude = direction.distance;
      if (magnitude == 0) continue;

      final unit = direction / magnitude;
      final opacity = math.sin(p * math.pi).clamp(0.0, 1.0);
      final half = unit * (spec.length / 2);

      canvas.drawLine(
        current - half,
        current + half,
        Paint()
          ..color = spec.color.withValues(alpha: opacity * 0.95)
          ..strokeWidth = spec.width
          ..strokeCap = StrokeCap.round,
      );

      canvas.drawCircle(
        current - (unit * (spec.length * 0.72)),
        spec.width * 0.52,
        Paint()
          ..color = spec.color.withValues(alpha: opacity * 0.26),
      );
    }
  }

  double _interval(
    double value,
    double begin,
    double end,
    Curve curve,
  ) {
    if (value <= begin) return 0;
    if (value >= end) return 1;

    final normalized = (value - begin) / (end - begin);
    return curve.transform(normalized);
  }

  @override
  bool shouldRepaint(covariant _FlyingStrokesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _StrokeSpec {
  const _StrokeSpec({
    required this.start,
    required this.targetOffset,
    required this.begin,
    required this.end,
    required this.length,
    required this.width,
    required this.color,
  });

  final Offset start;
  final Offset targetOffset;
  final double begin;
  final double end;
  final double length;
  final double width;
  final Color color;
}

class _HighlightPainter extends CustomPainter {
  const _HighlightPainter({
    required this.progress,
  });

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final specs = [
      (
        path: Path()
          ..moveTo(size.width * 0.16, size.height * 0.28)
          ..quadraticBezierTo(
            size.width * 0.44,
            size.height * 0.17,
            size.width * 0.68,
            size.height * 0.26,
          ),
        begin: 0.0,
        color: AppColors.accent,
        width: 4.4,
      ),
      (
        path: Path()
          ..moveTo(size.width * 0.28, size.height * 0.53)
          ..quadraticBezierTo(
            size.width * 0.52,
            size.height * 0.39,
            size.width * 0.83,
            size.height * 0.48,
          ),
        begin: 0.16,
        color: const Color(0xFF93C7FF),
        width: 3.8,
      ),
      (
        path: Path()
          ..moveTo(size.width * 0.20, size.height * 0.79)
          ..quadraticBezierTo(
            size.width * 0.40,
            size.height * 0.71,
            size.width * 0.59,
            size.height * 0.76,
          ),
        begin: 0.32,
        color: AppColors.ink,
        width: 3.2,
      ),
    ];

    for (final spec in specs) {
      final local = ((progress - spec.begin) / (1 - spec.begin))
          .clamp(0.0, 1.0);
      if (local <= 0) continue;

      final metric = spec.path.computeMetrics().first;
      final partial = metric.extractPath(0, metric.length * local);

      canvas.drawPath(
        partial,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = spec.width
          ..strokeCap = StrokeCap.round
          ..color = spec.color.withValues(alpha: 0.90),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HighlightPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
