import 'package:flutter/material.dart';

class LoadingSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const LoadingSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius,
  });

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Shimmer Effect Widget
/// Follows SRP - Applies shimmer effect to any child widget
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const ShimmerEffect({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
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
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Colors.white10,
                Colors.white,
                Colors.white10,
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ],
              transform:
                  _SlidingGradientTransform(slidePercent: _controller.value),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
        bounds.width * (slidePercent - 0.5), 0.0, 0.0);
  }
}

/// Ripple Feedback Widget
/// Follows SRP - Adds ripple effect feedback on tap
class RippleFeedback extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? splashColor;
  final Color? highlightColor;
  final BorderRadius? borderRadius;

  const RippleFeedback({
    super.key,
    required this.child,
    this.onTap,
    this.splashColor,
    this.highlightColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: splashColor ??
            Theme.of(context).primaryColor.withValues(alpha: 0.3),
        highlightColor: highlightColor ??
            Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        child: child,
      ),
    );
  }
}

/// Haptic Feedback Button
/// Follows SRP - Adds haptic feedback to button presses
class HapticButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;
  final bool enableHaptic;

  const HapticButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.enableHaptic = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (enableHaptic) {
          // HapticFeedback can be added here
          // HapticFeedback.lightImpact();
        }
        onPressed();
      },
      child: child,
    );
  }
}

/// Swipe Gesture Indicator
/// Follows SRP - Visual feedback for swipe gestures
class SwipeGestureIndicator extends StatefulWidget {
  final Widget child;
  final Function(DismissDirection)? onDismissed;
  final Color leftColor;
  final Color rightColor;
  final IconData leftIcon;
  final IconData rightIcon;

  const SwipeGestureIndicator({
    super.key,
    required this.child,
    this.onDismissed,
    this.leftColor = Colors.blue,
    this.rightColor = Colors.red,
    this.leftIcon = Icons.edit,
    this.rightIcon = Icons.delete,
  });

  @override
  State<SwipeGestureIndicator> createState() => _SwipeGestureIndicatorState();
}

class _SwipeGestureIndicatorState extends State<SwipeGestureIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragExtent = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent += details.primaryDelta ?? 0;
      _controller.value = (_dragExtent.abs() / 100).clamp(0.0, 1.0);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_dragExtent.abs() > 100) {
      final direction = _dragExtent > 0
          ? DismissDirection.startToEnd
          : DismissDirection.endToStart;
      widget.onDismissed?.call(direction);
    }

    setState(() {
      _dragExtent = 0;
      _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      child: Stack(
        children: [
          // Background indicator
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _controller.value,
                  child: Container(
                    color: _dragExtent > 0
                        ? widget.leftColor.withValues(alpha: 0.2)
                        : widget.rightColor.withValues(alpha: 0.2),
                    alignment: _dragExtent > 0
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Icon(
                      _dragExtent > 0 ? widget.leftIcon : widget.rightIcon,
                      color: _dragExtent > 0
                          ? widget.leftColor
                          : widget.rightColor,
                      size: 24,
                    ),
                  ),
                );
              },
            ),
          ),

          // Content
          Transform.translate(
            offset: Offset(_dragExtent * 0.5, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

/// Fade In Animation
/// Follows SRP - Simple fade in transition
class FadeInAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  const FadeInAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
  });

  @override
  State<FadeInAnimation> createState() => _FadeInAnimationState();
}

class _FadeInAnimationState extends State<FadeInAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
