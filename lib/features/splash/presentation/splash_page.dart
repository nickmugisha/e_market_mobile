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

    final normalized = (value - begin) / (end - begin);
    return curve.transform(normalized);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFD),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final progress = _controller.value;

            final titleProgress = _interval(
              progress,
              0.58,
              0.80,
              curve: Curves.easeOutBack,
            );
            final subtitleProgress = _interval(
              progress,
              0.67,
              0.87,
            );
            final loadingProgress = _interval(
              progress,
              0.76,
              0.96,
            );

            return Stack(
              fit: StackFit.expand,
              children: [
                const _SoftBackground(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      MarketBagAnimation(progress: progress),
                      const SizedBox(height: 4),
                      Transform.translate(
                        offset: Offset(0, 12 * (1 - titleProgress)),
                        child: Opacity(
                          opacity: titleProgress.clamp(0.0, 1.0),
                          child: const Text(
                            'e-market',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.6,
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
                            'Good finds are on the way.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 14,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Opacity(
                        opacity: loadingProgress.clamp(0.0, 1.0),
                        child: _LoadingDots(progress: progress),
                      ),
                      const SizedBox(height: 24),
                      Opacity(
                        opacity: loadingProgress.clamp(0.0, 1.0),
                        child: Text(
                          'MADE FOR EASY SHOPPING',
                          style: TextStyle(
                            color: AppColors.ink.withValues(alpha: 0.34),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
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

class _SoftBackground extends StatelessWidget {
  const _SoftBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0xFFFAFBFD)),
          Positioned(
            top: -150,
            right: -110,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.075),
              ),
            ),
          ),
          Positioned(
            left: -120,
            bottom: 70,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEAF4FF).withValues(alpha: 0.60),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingDots extends StatelessWidget {
  const _LoadingDots({
    required this.progress,
  });

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final shifted = (progress * 8) - index;
        final wave = (shifted - shifted.floor()).abs();
        final emphasis = 0.55 + (0.45 * (1 - ((wave - 0.5).abs() * 2)));

        return Container(
          width: index == 1 ? 18 : 7,
          height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: emphasis),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
