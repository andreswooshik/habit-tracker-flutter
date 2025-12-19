import 'package:flutter/material.dart';

class StreakDisplayCard extends StatelessWidget {
  final int currentStreak;
  final int bestStreak;
  final bool isAtRisk;

  const StreakDisplayCard({
    super.key,
    required this.currentStreak,
    required this.bestStreak,
    required this.isAtRisk,
  });

  @override
  Widget build(BuildContext context) {
    final streakEmoji = _getStreakEmoji(currentStreak);
    final streakColor = _getStreakColor(currentStreak);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                streakColor.withOpacity(0.1),
                streakColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Current Streak',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (isAtRisk)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'At Risk',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 24),

              // Streak Display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Emoji Icon
                  Text(
                    streakEmoji,
                    style: const TextStyle(fontSize: 64),
                  ),

                  const SizedBox(width: 24),

                  // Streak Count
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$currentStreak',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: streakColor,
                          height: 1,
                        ),
                      ),
                      Text(
                        currentStreak == 1 ? 'day' : 'days',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Best Streak Comparison
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.emoji_events,
                          color: Colors.amber.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Best Streak',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$bestStreak ${bestStreak == 1 ? 'day' : 'days'}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              // Streak Tips
              if (isAtRisk) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Colors.orange.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Complete this habit today to maintain your streak!',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Milestone Message
              if (currentStreak > 0 && !isAtRisk)
                _buildMilestoneMessage(currentStreak),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMilestoneMessage(int streak) {
    final nextMilestone = _getNextMilestone(streak);
    final daysToMilestone = nextMilestone - streak;

    if (daysToMilestone <= 0) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.celebration,
                color: Colors.green.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '🎉 Milestone achieved! $streak days strong!',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        '$daysToMilestone more ${daysToMilestone == 1 ? 'day' : 'days'} until $nextMilestone-day milestone!',
        style: const TextStyle(
          fontSize: 13,
          color: Colors.black54,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _getStreakEmoji(int streak) {
    if (streak >= 30) return '🏆'; // Trophy
    if (streak >= 14) return '⚡'; // Lightning
    if (streak >= 7) return '🔥'; // Fire
    if (streak >= 3) return '💪'; // Muscle
    return '🌱'; // Seedling
  }

  Color _getStreakColor(int streak) {
    if (streak >= 30) return Colors.amber;
    if (streak >= 14) return Colors.purple;
    if (streak >= 7) return Colors.orange;
    if (streak >= 3) return Colors.green;
    return Colors.blue;
  }

  int _getNextMilestone(int streak) {
    const milestones = [3, 7, 14, 30, 60, 90, 180, 365];
    for (final milestone in milestones) {
      if (streak < milestone) return milestone;
    }
    return ((streak ~/ 100) + 1) * 100; // Next hundred
  }
}
