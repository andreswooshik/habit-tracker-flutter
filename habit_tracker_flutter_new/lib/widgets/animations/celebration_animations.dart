import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

class ConfettiCelebration extends StatefulWidget {
  final Widget child;
  final bool shouldPlay;
  final VoidCallback? onAnimationComplete;
  final Duration duration;

  const ConfettiCelebration({
    super.key,
    required this.child,
    this.shouldPlay = false,
    this.onAnimationComplete,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<ConfettiCelebration> createState() => _ConfettiCelebrationState();
}

class _ConfettiCelebrationState extends State<ConfettiCelebration> {
  late ConfettiController _confettiController;
  bool _hasPlayed = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: widget.duration);
  }

  @override
  void didUpdateWidget(ConfettiCelebration oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Trigger confetti when shouldPlay changes from false to true
    if (widget.shouldPlay && !oldWidget.shouldPlay && !_hasPlayed) {
      _triggerConfetti();
      _hasPlayed = true;
    }

    // Reset flag when shouldPlay becomes false
    if (!widget.shouldPlay && oldWidget.shouldPlay) {
      _hasPlayed = false;
    }
  }

  void _triggerConfetti() {
    _confettiController.play();

    // Notify when animation completes
    Future.delayed(widget.duration, () {
      if (mounted && widget.onAnimationComplete != null) {
        widget.onAnimationComplete!();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        widget.child,

        // Confetti from top center
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2, // Down
            emissionFrequency: 0.05,
            numberOfParticles: 30,
            maxBlastForce: 20,
            minBlastForce: 8,
            gravity: 0.3,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
              Colors.amber,
            ],
          ),
        ),
      ],
    );
  }
}

/// Bounce Animation Controller Widget
/// Follows SRP - Only manages bounce animation logic
class BounceAnimation extends StatefulWidget {
  final Widget child;
  final bool shouldAnimate;
  final Duration duration;

  const BounceAnimation({
    super.key,
    required this.child,
    this.shouldAnimate = false,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<BounceAnimation> createState() => _BounceAnimationState();
}

class _BounceAnimationState extends State<BounceAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // Bounce curve: scale up then down
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(BounceAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Trigger animation when shouldAnimate changes to true
    if (widget.shouldAnimate && !oldWidget.shouldAnimate) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );
  }
}

/// Achievement Unlock Animation
/// Follows SRP - Only handles achievement celebration
class AchievementUnlockAnimation extends StatefulWidget {
  final Widget child;
  final bool shouldShow;
  final String achievementText;
  final IconData achievementIcon;
  final Duration displayDuration;

  const AchievementUnlockAnimation({
    super.key,
    required this.child,
    this.shouldShow = false,
    this.achievementText = 'Achievement Unlocked!',
    this.achievementIcon = Icons.emoji_events,
    this.displayDuration = const Duration(seconds: 3),
  });

  @override
  State<AchievementUnlockAnimation> createState() =>
      _AchievementUnlockAnimationState();
}

class _AchievementUnlockAnimationState extends State<AchievementUnlockAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5),
    ));
  }

  @override
  void didUpdateWidget(AchievementUnlockAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.shouldShow && !oldWidget.shouldShow) {
      _showAchievement();
    }
  }

  Future<void> _showAchievement() async {
    setState(() => _isVisible = true);
    await _controller.forward();

    // Keep visible for display duration
    await Future.delayed(widget.displayDuration);

    // Hide with reverse animation
    await _controller.reverse();
    setState(() => _isVisible = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isVisible)
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.amber.shade700,
                          Colors.amber.shade500,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.5),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.achievementIcon,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          widget.achievementText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
