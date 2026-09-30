import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'featured_card.dart';

class FeaturedCardDeck extends StatefulWidget {
  const FeaturedCardDeck({
    super.key,
    required this.items,
    this.onTap,
    this.height = 372,
  });

  final List<FeaturedCardData> items;
  final VoidCallback? onTap;
  final double height;

  @override
  State<FeaturedCardDeck> createState() => _FeaturedCardDeckState();
}

class _FeaturedCardDeckState extends State<FeaturedCardDeck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  Offset _dragOffset = Offset.zero;
  Offset _animationStart = Offset.zero;
  Offset _animationEnd = Offset.zero;

  int _currentIndex = 0;
  bool _advanceAfterAnimation = false;
  bool _animating = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..addListener(() {
        final eased = Curves.easeOutCubic.transform(_controller.value);
        setState(() {
          _dragOffset = Offset.lerp(
                _animationStart,
                _animationEnd,
                eased,
              ) ??
              Offset.zero;
        });
      });
  }

  @override
  void didUpdateWidget(covariant FeaturedCardDeck oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.items.isEmpty) {
      _currentIndex = 0;
      _dragOffset = Offset.zero;
      return;
    }

    if (_currentIndex >= widget.items.length) {
      _currentIndex = 0;
      _dragOffset = Offset.zero;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startDrag(DragStartDetails details) {
    if (_animating || widget.items.length < 2) return;
    _controller.stop();
  }

  void _updateDrag(DragUpdateDetails details) {
    if (_animating || widget.items.length < 2) return;

    setState(() {
      _dragOffset += Offset(
        details.delta.dx,
        details.delta.dy * 0.18,
      );
    });
  }

  void _endDrag(DragEndDetails details) {
    if (_animating || widget.items.length < 2) return;

    final width = context.size?.width ?? MediaQuery.sizeOf(context).width;
    final velocityX = details.velocity.pixelsPerSecond.dx;
    final crossedDistance = _dragOffset.dx.abs() > width * 0.22;
    final crossedVelocity = velocityX.abs() > 720;

    if (!crossedDistance && !crossedVelocity) {
      _animateTo(
        Offset.zero,
        advance: false,
        duration: const Duration(milliseconds: 260),
      );
      return;
    }

    final fallbackDirection = _dragOffset.dx == 0 ? 1.0 : _dragOffset.dx.sign;
    final direction = velocityX.abs() > 80 ? velocityX.sign : fallbackDirection;

    _animateTo(
      Offset(
        direction * (width + 180),
        _dragOffset.dy + 34,
      ),
      advance: true,
      duration: const Duration(milliseconds: 300),
    );
  }

  Future<void> _animateTo(
    Offset target, {
    required bool advance,
    required Duration duration,
  }) async {
    _animationStart = _dragOffset;
    _animationEnd = target;
    _advanceAfterAnimation = advance;
    _animating = true;
    _controller.duration = duration;

    await _controller.forward(from: 0);

    if (!mounted) return;

    setState(() {
      if (_advanceAfterAnimation && widget.items.isNotEmpty) {
        _currentIndex = (_currentIndex + 1) % widget.items.length;
      }

      _dragOffset = Offset.zero;
      _animationStart = Offset.zero;
      _animationEnd = Offset.zero;
      _advanceAfterAnimation = false;
      _animating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final dragProgress = width <= 0
              ? 0.0
              : (_dragOffset.dx.abs() / (width * 0.62)).clamp(0.0, 1.0);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: widget.height - 34,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    if (widget.items.length > 2)
                      _BehindCard(
                        data: _itemAt(2),
                        depth: 2,
                        progress: dragProgress,
                      ),
                    if (widget.items.length > 1)
                      _BehindCard(
                        data: _itemAt(1),
                        depth: 1,
                        progress: dragProgress,
                      ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _animating ? null : widget.onTap,
                      onHorizontalDragStart: _startDrag,
                      onHorizontalDragUpdate: _updateDrag,
                      onHorizontalDragEnd: _endDrag,
                      child: Transform.translate(
                        offset: _dragOffset,
                        child: Transform.rotate(
                          angle: width <= 0
                              ? 0
                              : (_dragOffset.dx / width) * 0.095,
                          alignment: Alignment.bottomCenter,
                          child: Transform.scale(
                            scale: 1 - (0.025 * dragProgress),
                            alignment: Alignment.center,
                            child: FeaturedCard(
                              data: _itemAt(0),
                              showSwipeHint: widget.items.length > 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 0,
                child: Row(
                  children: [
                    const Icon(
                      Icons.swipe_rounded,
                      size: 17,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 7),
                    const Text(
                      'Swipe the top card',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    _DeckDots(
                      count: widget.items.length,
                      currentIndex: _currentIndex,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${(_currentIndex + 1).toString().padLeft(2, '0')}'
                      ' / '
                      '${widget.items.length.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  FeaturedCardData _itemAt(int offset) {
    final index = (_currentIndex + offset) % widget.items.length;
    return widget.items[index];
  }
}

class _BehindCard extends StatelessWidget {
  const _BehindCard({
    required this.data,
    required this.depth,
    required this.progress,
  });

  final FeaturedCardData data;
  final int depth;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final baseScale = depth == 1 ? 0.955 : 0.91;
    final nextScale = depth == 1 ? 1.0 : 0.955;
    final scale = _lerp(baseScale, nextScale, progress);

    final baseY = depth == 1 ? 15.0 : 29.0;
    final nextY = depth == 1 ? 0.0 : 15.0;
    final translateY = _lerp(baseY, nextY, progress);

    final baseOpacity = depth == 1 ? 0.88 : 0.66;
    final nextOpacity = depth == 1 ? 1.0 : 0.88;
    final opacity = _lerp(baseOpacity, nextOpacity, progress);

    return IgnorePointer(
      child: Transform.translate(
        offset: Offset(0, translateY),
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.topCenter,
          child: Opacity(
            opacity: opacity,
            child: FeaturedCard(data: data),
          ),
        ),
      ),
    );
  }

  double _lerp(double a, double b, double t) {
    return a + ((b - a) * t);
  }
}

class _DeckDots extends StatelessWidget {
  const _DeckDots({
    required this.count,
    required this.currentIndex,
  });

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final visibleCount = math.min(count, 6);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(visibleCount, (index) {
        final selected = index == currentIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: selected ? 20 : 6,
          height: 6,
          margin: EdgeInsets.only(
            right: index == visibleCount - 1 ? 0 : 5,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : AppColors.line,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
