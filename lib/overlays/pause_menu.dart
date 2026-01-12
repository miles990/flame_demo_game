import 'package:flutter/material.dart';

import '../components/star_background.dart';
import '../game/space_game.dart';

class PauseMenu extends StatelessWidget {
  final SpaceGame game;

  const PauseMenu({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pause text
            const Text(
              'PAUSED',
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 10,
              ),
            ),
            const SizedBox(height: 20),

            // Current score
            Text(
              'Score: ${game.score}',
              style: const TextStyle(
                fontSize: 24,
                color: Color(0xFF00D4FF),
              ),
            ),
            const SizedBox(height: 50),

            // Resume button
            _PauseButton(
              text: 'RESUME',
              onPressed: () => game.resumeGame(),
              color: const Color(0xFF00FF88),
            ),
            const SizedBox(height: 20),

            // Restart button
            _PauseButton(
              text: 'RESTART',
              onPressed: () {
                game.resumeGame();
                game.startGame();
              },
              color: const Color(0xFFFFD700),
            ),
            const SizedBox(height: 20),

            // Quit button
            _PauseButton(
              text: 'QUIT',
              onPressed: () {
                game.resumeGame();
                game.isPlaying = false;
                game.overlays.add('MainMenu');

                // Clear game components except background
                game.world.children
                    .where((c) => c is! StarBackground)
                    .toList()
                    .forEach((c) => c.removeFromParent());
                game.camera.viewport.children
                    .toList()
                    .forEach((c) => c.removeFromParent());
              },
              color: const Color(0xFFFF4444),
            ),
          ],
        ),
      ),
    );
  }
}

class _PauseButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;

  const _PauseButton({
    required this.text,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.2),
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: color),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}
