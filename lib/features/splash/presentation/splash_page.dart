import 'package:flutter/material.dart';

import '../../../core/navigation/app_transitions.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_gate.dart';
import 'widgets/market_bag_animation.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..forward();

    _controller.addStatusListener((status) {
      if (status != AnimationStatus.completed || !mounted) return;

      Navigator.of(context).pushReplacement(smoothRoute(AuthGate()));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _interval(
    double value,
    double begin,
    double end, {
    Curve curve = Curves.easeOutCubic,
  }) {
    if (value <= begin) return 0;
    if (value >= end) return 1;

    return curve.transform((value - begin) / (end - begin));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFDF7),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final progress = _controller.value;

            final titleProgress = _interval(
              progress,
              0.56,
              0.79,
              curve: Curves.easeOutBack,
            );

            final subtitleProgress = _interval(progress, 0.65, 0.86);

            final loadingProgress = _interval(progress, 0.75, 0.96);

            return Stack(
              fit: StackFit.expand,
              children: [
                const _LeafBackground(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      MarketBagAnimation(progress: progress),
                      Transform.translate(
                        offset: Offset(0, 13 * (1 - titleProgress)),
                        child: Opacity(
                          opacity: titleProgress.clamp(0.0, 1.0),
                          child: const Text(
                            'e-market',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.7,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 9),
                      Transform.translate(
                        offset: Offset(0, 8 * (1 - subtitleProgress)),
                        child: Opacity(
                          opacity: subtitleProgress.clamp(0.0, 1.0),
                          child: const Text(
                            'Fresh finds. Easy shopping.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 14,
                              height: 1.45,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Opacity(
                        opacity: loadingProgress.clamp(0.0, 1.0),
                        child: _LoadingLeafLine(progress: progress),
                      ),
                      const SizedBox(height: 18),
                      Opacity(
                        opacity: loadingProgress.clamp(0.0, 1.0),
                        child: Text(
                          'YOUR MARKET, MADE LIGHTER',
                          style: TextStyle(
                            color: AppColors.ink.withValues(alpha: 0.34),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.7,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LeafBackground extends StatelessWidget {
  const _LeafBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0xFFFBFDF7)),
          Positioned(
            top: -150,
            right: -105,
            child: Container(
              width: 315,
              height: 315,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.leafGlow.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            left: -120,
            bottom: 55,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentSoft.withValues(alpha: 0.80),
              ),
            ),
          ),
          const Positioned(
            left: 34,
            top: 82,
            child: TransformLeaf(angle: -0.50, size: 25, opacity: 0.14),
          ),
          const Positioned(
            right: 38,
            bottom: 110,
            child: TransformLeaf(angle: 0.62, size: 30, opacity: 0.12),
          ),
        ],
      ),
    );
  }
}

class TransformLeaf extends StatelessWidget {
  const TransformLeaf({
    super.key,
    required this.angle,
    required this.size,
    required this.opacity,
  });

  final double angle;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Icon(
        Icons.eco_rounded,
        size: size,
        color: AppColors.accentStrong.withValues(alpha: opacity),
      ),
    );
  }
}

class _LoadingLeafLine extends StatelessWidget {
  const _LoadingLeafLine({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final width = 72 + (progress * 16);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.eco_rounded, size: 16, color: AppColors.accentStrong),
        const SizedBox(width: 9),
        Container(
          width: width,
          height: 5,
          decoration: BoxDecoration(
            color: AppColors.accentSoft,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: ((progress - 0.68) / 0.32).clamp(0.10, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accentStrong, AppColors.leafGlow],
                ),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.leafGlow.withValues(alpha: 0.38),
                    blurRadius: 9,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
