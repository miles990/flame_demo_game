import 'package:flutter/material.dart';

import '../game/space_game.dart';

class GameOverMenu extends StatelessWidget {
  final SpaceGame game;

  const GameOverMenu({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final isNewHighScore = game.score >= game.highScore && game.score > 0;

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            Colors.red.withOpacity(0.3),
            Colors.black.withOpacity(0.9),
          ],
          radius: 1.5,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Game over text
            const Text(
              'GAME OVER',
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF4444),
                letterSpacing: 8,
                shadows: [
                  Shadow(
                    color: Color(0xFFFF4444),
                    blurRadius: 30,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // New high score badge
            if (isNewHighScore)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFFD700),
                    width: 2,
                  ),
                ),
                child: const Text(
                  'NEW HIGH SCORE!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFD700),
                    letterSpacing: 3,
                  ),
                ),
              ),

            const SizedBox(height: 30),

            // Score display
            Text(
              'SCORE',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white.withOpacity(0.6),
                letterSpacing: 5,
              ),
            ),
            Text(
              '${game.score}',
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00D4FF),
                shadows: [
                  Shadow(
                    color: Color(0xFF00D4FF),
                    blurRadius: 20,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // High score
            Text(
              'HIGH SCORE: ${game.highScore}',
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFFFFD700),
              ),
            ),

            const SizedBox(height: 50),

            // Retry button
            ElevatedButton(
              onPressed: () {
                game.resumeEngine();
                game.startGame();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4FF).withOpacity(0.2),
                foregroundColor: const Color(0xFF00D4FF),
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: const BorderSide(
                    color: Color(0xFF00D4FF),
                    width: 2,
                  ),
                ),
              ),
              child: const Text(
                'PLAY AGAIN',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Main menu button
            TextButton(
              onPressed: () {
                game.resumeEngine();
                game.overlays.remove('GameOver');
                game.overlays.add('MainMenu');

                // Clear game components except background
                game.world.children
                    .where((c) => c.runtimeType.toString() != 'StarBackground')
                    .forEach((c) => c.removeFromParent());
              },
              child: Text(
                'MAIN MENU',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.6),
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
