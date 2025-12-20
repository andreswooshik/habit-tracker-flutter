import 'package:flutter/material.dart';

/// Helper class to test and verify animations work correctly
/// 
/// Use this in development to ensure all animations trigger properly
class AnimationTestHelper {
  /// Test bounce animation by toggling state
  static Widget testBounceAnimation() {
    return _BounceAnimationTest();
  }

  /// Test confetti celebration
  static Widget testConfettiCelebration() {
    return _ConfettiTest();
  }

  /// Test streak milestone celebration
  static Widget testStreakMilestone() {
    return _StreakMilestoneTest();
  }
}

class _BounceAnimationTest extends StatefulWidget {
  @override
  State<_BounceAnimationTest> createState() => _BounceAnimationTestState();
}

class _BounceAnimationTestState extends State<_BounceAnimationTest> {
  bool _shouldBounce = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bounce Animation Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _shouldBounce ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 50),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                setState(() => _shouldBounce = !_shouldBounce);
              },
              child: Text(_shouldBounce ? 'Reset' : 'Trigger Bounce'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfettiTest extends StatefulWidget {
  @override
  State<_ConfettiTest> createState() => _ConfettiTestState();
}

class _ConfettiTestState extends State<_ConfettiTest> {
  bool _showConfetti = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confetti Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _showConfetti ? '🎉 Celebrating! 🎉' : 'Ready to celebrate',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                setState(() => _showConfetti = !_showConfetti);
              },
              child: Text(_showConfetti ? 'Stop' : 'Trigger Confetti'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakMilestoneTest extends StatefulWidget {
  @override
  State<_StreakMilestoneTest> createState() => _StreakMilestoneTestState();
}

class _StreakMilestoneTestState extends State<_StreakMilestoneTest> {
  int _currentStreak = 0;
  int _previousStreak = 0;

  void _incrementStreak() {
    setState(() {
      _previousStreak = _currentStreak;
      _currentStreak++;
    });
  }

  void _jumpToMilestone(int milestone) {
    setState(() {
      _previousStreak = milestone - 1;
      _currentStreak = milestone;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Streak Milestone Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Current Streak: $_currentStreak days',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              'Previous: $_previousStreak days',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _incrementStreak,
              child: const Text('Increment Streak'),
            ),
            const SizedBox(height: 20),
            const Text('Jump to Milestone:', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: [3, 7, 14, 30, 50, 100].map((milestone) {
                return ElevatedButton(
                  onPressed: () => _jumpToMilestone(milestone),
                  child: Text('$milestone'),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
