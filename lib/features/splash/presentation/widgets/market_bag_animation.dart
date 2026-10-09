import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class MarketBagAnimation extends StatelessWidget {
  const MarketBagAnimation({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final entrance = _interval(progress, 0.02, 0.27, Curves.easeOutBack);

    final settle = _interval(progress, 0.22, 0.74, Curves.easeInOutCubic);

    final bob = math.sin(settle * math.pi * 2) * 4.0 * (1 - settle);

    return SizedBox(
      width: 330,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _FlyingStrokesPainter(progress: progress),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 72,
            right: 72,
            height: 36,
            child: CustomPaint(painter: _GroundGlowPainter(opacity: entrance)),
          ),
          Transform.translate(
            offset: Offset(0, bob),
            child: Transform.scale(
              scale: 0.76 + (0.24 * entrance),
              child: Opacity(
                opacity: entrance.clamp(0.0, 1.0),
                child: SizedBox(
                  width: 205,
                  height: 215,
                  child: CustomPaint(
                    painter: _BagPainter(
                      reveal: entrance,
                      impact: _interval(
                        progress,
                        0.30,
                        0.66,
                        Curves.easeOutCubic,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static double _interval(double value, double begin, double end, Curve curve) {
    if (value <= begin) return 0;
    if (value >= end) return 1;

    final normalized = (value - begin) / (end - begin);
    return curve.transform(normalized);
  }
}

class _BagPainter extends CustomPainter {
  const _BagPainter({required this.reveal, required this.impact});

  final double reveal;
  final double impact;

  @override
  void paint(Canvas canvas, Size size) {
    final bagRect = Rect.fromLTWH(
      size.width * 0.18,
      size.height * 0.29,
      size.width * 0.64,
      size.height * 0.56,
    );

    final centerX = size.width / 2;

    final bagPath = Path()
      ..moveTo(bagRect.left + 16, bagRect.top + 4)
      ..quadraticBezierTo(
        bagRect.left + 3,
        bagRect.top + 4,
        bagRect.left,
        bagRect.top + 22,
      )
      ..lineTo(bagRect.left + 9, bagRect.bottom - 17)
      ..quadraticBezierTo(
        bagRect.left + 11,
        bagRect.bottom + 3,
        bagRect.left + 30,
        bagRect.bottom + 4,
      )
      ..lineTo(bagRect.right - 30, bagRect.bottom + 4)
      ..quadraticBezierTo(
        bagRect.right - 11,
        bagRect.bottom + 3,
        bagRect.right - 9,
        bagRect.bottom - 17,
      )
      ..lineTo(bagRect.right, bagRect.top + 22)
      ..quadraticBezierTo(
        bagRect.right - 3,
        bagRect.top + 4,
        bagRect.right - 16,
        bagRect.top + 4,
      )
      ..close();

    canvas.save();
    canvas.translate(0, 10);
    canvas.drawPath(
      bagPath,
      Paint()
        ..color = AppColors.accentStrong.withValues(alpha: 0.15 * reveal)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    canvas.restore();

    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFF4FBE8), Color(0xFFE7F5CC)],
      ).createShader(bagRect);

    canvas.drawPath(bagPath, fill);

    canvas.drawPath(
      bagPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.1
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.ink.withValues(alpha: 0.92 * reveal),
    );

    final handle = Path()
      ..moveTo(size.width * 0.35, bagRect.top + 12)
      ..cubicTo(
        size.width * 0.36,
        size.height * 0.12,
        size.width * 0.64,
        size.height * 0.12,
        size.width * 0.65,
        bagRect.top + 12,
      );

    canvas.drawPath(
      handle,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.1
        ..strokeCap = StrokeCap.round
        ..color = AppColors.ink.withValues(alpha: 0.90 * reveal),
    );

    final lipY = bagRect.top + 23;

    final lip = Path()
      ..moveTo(bagRect.left + 13, lipY)
      ..quadraticBezierTo(
        centerX,
        lipY + (9 * impact),
        bagRect.right - 13,
        lipY,
      );

    canvas.drawPath(
      lip,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..color = AppColors.accentStrong.withValues(alpha: 0.88),
    );

    final emblem = Offset(centerX, bagRect.top + bagRect.height * 0.58);

    canvas.drawCircle(
      emblem,
      33,
      Paint()..color = AppColors.accentSoft.withValues(alpha: 0.94),
    );

    canvas.drawCircle(
      emblem,
      32,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = AppColors.accentStrong.withValues(alpha: 0.20),
    );

    _drawLeaf(
      canvas,
      center: Offset(emblem.dx - 7, emblem.dy + 1),
      angle: -0.63,
      color: AppColors.accentStrong,
    );

    _drawLeaf(
      canvas,
      center: Offset(emblem.dx + 8, emblem.dy - 3),
      angle: 0.72,
      color: AppColors.leafGlow,
    );

    canvas.drawLine(
      Offset(emblem.dx, emblem.dy + 11),
      Offset(emblem.dx, emblem.dy - 10),
      Paint()
        ..color = AppColors.ink.withValues(alpha: 0.50)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawLeaf(
    Canvas canvas, {
    required Offset center,
    required double angle,
    required Color color,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final leaf = Path()
      ..moveTo(-2, 12)
      ..quadraticBezierTo(-17, -4, 0, -15)
      ..quadraticBezierTo(17, -4, -2, 12)
      ..close();

    canvas.drawPath(leaf, Paint()..color = color);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BagPainter oldDelegate) {
    return oldDelegate.reveal != reveal || oldDelegate.impact != impact;
  }
}

class _FlyingStrokesPainter extends CustomPainter {
  const _FlyingStrokesPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final target = Offset(size.width * 0.50, size.height * 0.42);

    final flights = <_FlightSpec>[
      _FlightSpec(
        start: Offset(-14, size.height * 0.21),
        control1: Offset(size.width * 0.18, size.height * 0.05),
        control2: Offset(size.width * 0.34, size.height * 0.36),
        targetOffset: const Offset(-23, -3),
        begin: 0.10,
        end: 0.43,
        color: AppColors.leafGlow,
        width: 4.2,
        trail: 52,
      ),
      _FlightSpec(
        start: Offset(size.width + 12, size.height * 0.16),
        control1: Offset(size.width * 0.78, -10),
        control2: Offset(size.width * 0.68, size.height * 0.31),
        targetOffset: const Offset(25, -5),
        begin: 0.17,
        end: 0.49,
        color: AppColors.accent,
        width: 4.6,
        trail: 59,
      ),
      _FlightSpec(
        start: Offset(size.width * 0.22, -18),
        control1: Offset(size.width * 0.27, size.height * 0.13),
        control2: Offset(size.width * 0.40, size.height * 0.22),
        targetOffset: const Offset(-10, -17),
        begin: 0.23,
        end: 0.54,
        color: AppColors.accentStrong,
        width: 3.6,
        trail: 45,
      ),
      _FlightSpec(
        start: Offset(size.width * 0.82, -15),
        control1: Offset(size.width * 0.76, size.height * 0.13),
        control2: Offset(size.width * 0.61, size.height * 0.23),
        targetOffset: const Offset(12, -16),
        begin: 0.29,
        end: 0.60,
        color: Color(0xFFDDFB87),
        width: 3.7,
        trail: 43,
      ),
      _FlightSpec(
        start: Offset(-20, size.height * 0.56),
        control1: Offset(size.width * 0.17, size.height * 0.54),
        control2: Offset(size.width * 0.31, size.height * 0.43),
        targetOffset: const Offset(-30, 6),
        begin: 0.35,
        end: 0.66,
        color: Color(0xFFB7E66E),
        width: 3.3,
        trail: 40,
      ),
    ];

    for (final spec in flights) {
      final p = _interval(
        progress,
        spec.begin,
        spec.end,
        Curves.easeInOutCubic,
      );

      if (p <= 0 || p >= 1) continue;

      final destination = target + spec.targetOffset;

      final path = Path()
        ..moveTo(spec.start.dx, spec.start.dy)
        ..cubicTo(
          spec.control1.dx,
          spec.control1.dy,
          spec.control2.dx,
          spec.control2.dy,
          destination.dx,
          destination.dy,
        );

      final metric = path.computeMetrics().first;
      final head = metric.length * p;
      final tail = math.max(0.0, head - spec.trail);
      final segment = metric.extractPath(tail, head);

      final opacity = math.sin(p * math.pi).clamp(0.0, 1.0);

      canvas.drawPath(
        segment,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = spec.width * 3.0
          ..strokeCap = StrokeCap.round
          ..color = spec.color.withValues(alpha: opacity * 0.20)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      canvas.drawPath(
        segment,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = spec.width
          ..strokeCap = StrokeCap.round
          ..color = spec.color.withValues(alpha: opacity),
      );

      final tangent = metric.getTangentForOffset(head);

      if (tangent != null) {
        canvas.drawCircle(
          tangent.position,
          spec.width * 1.15,
          Paint()
            ..color = spec.color.withValues(alpha: opacity * 0.92)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }
    }
  }

  double _interval(double value, double begin, double end, Curve curve) {
    if (value <= begin) return 0;
    if (value >= end) return 1;

    return curve.transform((value - begin) / (end - begin));
  }

  @override
  bool shouldRepaint(covariant _FlyingStrokesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _GroundGlowPainter extends CustomPainter {
  const _GroundGlowPainter({required this.opacity});

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.72,
        height: size.height * 0.30,
      ),
      Paint()
        ..color = AppColors.leafGlow.withValues(alpha: 0.20 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
  }

  @override
  bool shouldRepaint(covariant _GroundGlowPainter oldDelegate) {
    return oldDelegate.opacity != opacity;
  }
}

class _FlightSpec {
  const _FlightSpec({
    required this.start,
    required this.control1,
    required this.control2,
    required this.targetOffset,
    required this.begin,
    required this.end,
    required this.color,
    required this.width,
    required this.trail,
  });

  final Offset start;
  final Offset control1;
  final Offset control2;
  final Offset targetOffset;
  final double begin;
  final double end;
  final Color color;
  final double width;
  final double trail;
}
