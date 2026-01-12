import 'package:flutter/material.dart';

import '../game/space_game.dart';

class MainMenu extends StatelessWidget {
  final SpaceGame game;

  const MainMenu({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.6),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Game title
            const Text(
              'SPACE',
              style: TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00D4FF),
                letterSpacing: 20,
                shadows: [
                  Shadow(
                    color: Color(0xFF00D4FF),
                    blurRadius: 20,
                  ),
                ],
              ),
            ),
            const Text(
              'SHOOTER',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF4444),
                letterSpacing: 15,
                shadows: [
                  Shadow(
                    color: Color(0xFFFF4444),
                    blurRadius: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),

            // Start button
            _MenuButton(
              text: 'START GAME',
              onPressed: () => game.startGame(),
              color: const Color(0xFF00D4FF),
            ),

            const SizedBox(height: 40),

            // High score
            if (game.highScore > 0)
              Text(
                'HIGH SCORE: ${game.highScore}',
                style: const TextStyle(
                  fontSize: 20,
                  color: Color(0xFFFFD700),
                  letterSpacing: 2,
                ),
              ),

            const SizedBox(height: 60),

            // Controls info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    'CONTROLS',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'WASD / Arrow Keys - Move',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                  Text(
                    'SPACE - Shoot',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                  Text(
                    'ESC - Pause',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;

  const _MenuButton({
    required this.text,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(color: color, width: 2),
        ),
        elevation: 0,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 3,
          shadows: [
            Shadow(color: color, blurRadius: 10),
          ],
        ),
      ),
    );
  }
}
