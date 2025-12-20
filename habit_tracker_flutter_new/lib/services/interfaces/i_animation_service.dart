abstract class IAnimationService {
  /// Trigger a celebration animation
  void triggerCelebration();

  /// Check if animation is currently playing
  bool get isAnimating;

  /// Dispose animation resources
  void dispose();
}

/// Interface for completion-specific animations
abstract class ICompletionAnimationService extends IAnimationService {
  /// Trigger confetti celebration when all habits are completed
  void triggerAllHabitsCompleted();

  /// Trigger bounce animation for single habit completion
  void triggerHabitCompleted();
}

/// Interface for streak milestone animations
abstract class IStreakAnimationService extends IAnimationService {
  /// Trigger animation for reaching a streak milestone
  void triggerStreakMilestone(int streakCount);

  /// Get the animation for a specific milestone level
  bool shouldCelebrateMilestone(int streakCount);
}
