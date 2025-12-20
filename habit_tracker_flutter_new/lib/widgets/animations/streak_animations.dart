import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Streak Milestone Celebration Widget
/// Follows SRP - Handles streak milestone animations
class StreakMilestoneCelebration extends StatefulWidget {
  final Widget child;
  final int currentStreak;
  final int previousStreak;

  const StreakMilestoneCelebration({
    super.key,
    required this.child,
    required this.currentStreak,
    required this.previousStreak,
  });

  @override
  State<StreakMilestoneCelebration> createState() =>
      _StreakMilestoneCelebrationState();
}

class _StreakMilestoneCelebrationState extends State<StreakMilestoneCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _shouldCelebrate = false;
  int? _milestoneReached;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(StreakMilestoneCelebration oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if a milestone was just reached
    if (widget.currentStreak > widget.previousStreak) {
      final milestone = _checkMilestone(widget.currentStreak);
      if (milestone != null && milestone > (_milestoneReached ?? 0)) {
        _milestoneReached = milestone;
        setState(() => _shouldCelebrate = true);
        _controller.forward(from: 0.0).then((_) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() => _shouldCelebrate = false);
            }
          });
        });
      }
    }
  }

  /// Check if current streak is a milestone
  /// Milestones: 3, 7, 14, 30, 50, 100 days
  int? _checkMilestone(int streak) {
    const milestones = [3, 7, 14, 30, 50, 100];
    for (final milestone in milestones.reversed) {
      if (streak >= milestone && (widget.previousStreak < milestone)) {
        return milestone;
      }
    }
    return null;
  }

  String _getMilestoneEmoji(int milestone) {
    switch (milestone) {
      case 100:
        return '💎'; // Diamond
      case 50:
        return '👑'; // Crown
      case 30:
        return '🏆'; // Trophy
      case 14:
        return '⚡'; // Lightning
      case 7:
        return '🔥'; // Fire
      case 3:
        return '💪'; // Muscle
      default:
        return '⭐'; // Star
    }
  }

  Color _getMilestoneColor(int milestone) {
    switch (milestone) {
      case 100:
        return Colors.cyan;
      case 50:
        return Colors.purple;
      case 30:
        return Colors.amber;
      case 14:
        return Colors.deepOrange;
      case 7:
        return Colors.orange;
      case 3:
        return Colors.green;
      default:
        return Colors.blue;
    }
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

        // Milestone celebration overlay
        if (_shouldCelebrate && _milestoneReached != null)
          _MilestoneCelebrationOverlay(
            controller: _controller,
            milestone: _milestoneReached!,
            emoji: _getMilestoneEmoji(_milestoneReached!),
            color: _getMilestoneColor(_milestoneReached!),
          ),
      ],
    );
  }
}

/// Milestone Celebration Overlay
/// Private widget for displaying milestone animation
class _MilestoneCelebrationOverlay extends StatelessWidget {
  final AnimationController controller;
  final int milestone;
  final String emoji;
  final Color color;

  const _MilestoneCelebrationOverlay({
    required this.controller,
    required this.milestone,
    required this.emoji,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scaleAnimation = Tween<double>(begin: 0.0, end: 1.2).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    final fadeOutAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            return Opacity(
              opacity: controller.value < 0.7
                  ? fadeAnimation.value
                  : fadeOutAnimation.value,
              child: Center(
                child: ScaleTransition(
                  scale: scaleAnimation,
                  child: child,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.95),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.6),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 64),
                ),
                const SizedBox(height: 8),
                Text(
                  '$milestone Days!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Particle Effect Widget
/// Creates floating particles for celebration effects
class ParticleEffect extends StatefulWidget {
  final int particleCount;
  final Duration duration;
  final Color color;

  const ParticleEffect({
    super.key,
    this.particleCount = 20,
    this.duration = const Duration(seconds: 2),
    this.color = Colors.amber,
  });

  @override
  State<ParticleEffect> createState() => _ParticleEffectState();
}

class _ParticleEffectState extends State<ParticleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();

    _particles = List.generate(
      widget.particleCount,
      (index) => _Particle(
        color: widget.color,
        random: math.Random(index),
      ),
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
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlePainter(
            particles: _particles,
            animation: _controller.value,
          ),
          child: Container(),
        );
      },
    );
  }
}

class _Particle {
  final Color color;
  final double startX;
  final double startY;
  final double velocityX;
  final double velocityY;
  final double size;

  _Particle({
    required this.color,
    required math.Random random,
  })  : startX = random.nextDouble(),
        startY = random.nextDouble(),
        velocityX = (random.nextDouble() - 0.5) * 2,
        velocityY = -random.nextDouble() * 2 - 1,
        size = random.nextDouble() * 4 + 2;
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double animation;

  _ParticlePainter({
    required this.particles,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final x =
          size.width * particle.startX + particle.velocityX * animation * 100;
      final y = size.height * particle.startY +
          particle.velocityY * animation * 100 +
          (animation * animation * 50); // Gravity effect

      final paint = Paint()
        ..color = particle.color.withValues(alpha: 1.0 - animation)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}
