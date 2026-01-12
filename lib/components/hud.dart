import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/space_game.dart';

class Hud extends PositionComponent with HasGameReference<SpaceGame> {
  Hud() : super(position: Vector2.zero(), priority: 200);

  late TextComponent scoreText;
  late TextComponent highScoreText;
  late TextComponent waveText;
  late TextComponent controlsText;

  int _displayedScore = 0;
  double _scoreGlow = 0;
  double _bossFlash = 0;

  @override
  Future<void> onLoad() async {
    // Score display with glow effect
    scoreText = TextComponent(
      text: 'SCORE: 0',
      position: Vector2(20, 20),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF00D4FF),
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: 3,
          shadows: [
            Shadow(
              color: Color(0xFF00D4FF),
              blurRadius: 10,
            ),
          ],
        ),
      ),
    );
    add(scoreText);

    // High score display
    highScoreText = TextComponent(
      text: 'BEST: ${game.highScore}',
      position: Vector2(20, 55),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFFD700),
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          shadows: [
            Shadow(
              color: Color(0xFFFFD700),
              blurRadius: 6,
            ),
          ],
        ),
      ),
    );
    add(highScoreText);

    // Wave display
    waveText = TextComponent(
      text: 'WAVE 1',
      position: Vector2(game.size.x - 20, 20),
      anchor: Anchor.topRight,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF00FF88),
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          shadows: [
            Shadow(
              color: Color(0xFF00FF88),
              blurRadius: 8,
            ),
          ],
        ),
      ),
    );
    add(waveText);

    // Controls hint
    controlsText = TextComponent(
      text: '↑↓←→ or WASD: 移動  |  SPACE: 射擊  |  ESC: 暫停',
      position: Vector2(game.size.x / 2, game.size.y - 25),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white.withOpacity(0.4),
          fontSize: 13,
          letterSpacing: 1,
        ),
      ),
    );
    add(controlsText);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 繪製生命值（愛心圖示）
    _drawLives(canvas);

    // Boss 戰時顯示 BOSS 標籤
    if (game.inBossBattle) {
      _drawBossIndicator(canvas);
    }
  }

  void _drawLives(Canvas canvas) {
    final lives = game.isPlaying ? game.playerLives : 3;
    final heartSize = 22.0;
    final startX = game.size.x - 20 - (lives * (heartSize + 8));
    final startY = 55.0;

    for (int i = 0; i < lives; i++) {
      final x = startX + i * (heartSize + 8);
      _drawHeart(canvas, Offset(x, startY), heartSize);
    }
  }

  void _drawHeart(Canvas canvas, Offset position, double size) {
    final paint = Paint()
      ..color = const Color(0xFFFF3366)
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = const Color(0xFFFF3366).withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final path = Path();
    final x = position.dx;
    final y = position.dy;

    // 繪製愛心形狀
    path.moveTo(x + size / 2, y + size * 0.8);
    path.cubicTo(
      x + size * 0.1, y + size * 0.5,
      x, y + size * 0.2,
      x + size / 2, y,
    );
    path.cubicTo(
      x + size, y + size * 0.2,
      x + size * 0.9, y + size * 0.5,
      x + size / 2, y + size * 0.8,
    );
    path.close();

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  void _drawBossIndicator(Canvas canvas) {
    final centerX = game.size.x / 2;
    final y = 20.0;

    // 閃爍效果
    final opacity = (0.7 + 0.3 * sin(_bossFlash * 5)).clamp(0.0, 1.0);

    // 背景
    final bgPaint = Paint()
      ..color = const Color(0xFFFF0044).withOpacity(0.3 * opacity);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(centerX, y + 15), width: 120, height: 36),
        const Radius.circular(18),
      ),
      bgPaint,
    );

    // 邊框
    final borderPaint = Paint()
      ..color = const Color(0xFFFF0044).withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(centerX, y + 15), width: 120, height: 36),
        const Radius.circular(18),
      ),
      borderPaint,
    );

    // 文字
    final textPainter = TextPainter(
      text: TextSpan(
        text: '⚠ BOSS ⚠',
        style: TextStyle(
          color: Color.fromRGBO(255, 0, 68, opacity),
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 3,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(centerX - textPainter.width / 2, y + 15 - textPainter.height / 2),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Boss 閃爍
    _bossFlash += dt * 3;

    // 平滑分數動畫
    if (_displayedScore < game.score) {
      final diff = game.score - _displayedScore;
      _displayedScore += max(1, (diff * dt * 5).round());
      if (_displayedScore > game.score) _displayedScore = game.score;
      _scoreGlow = 1.0;
    }

    // 分數光暈衰減
    if (_scoreGlow > 0) {
      _scoreGlow -= dt * 2;
      if (_scoreGlow < 0) _scoreGlow = 0;
    }

    scoreText.text = 'SCORE: $_displayedScore';
    highScoreText.text = 'BEST: ${game.highScore}';

    // 更新波數顯示
    if (game.inBossBattle) {
      waveText.text = 'STAGE ${game.currentWave ~/ 5}';
      waveText.textRenderer = TextPaint(
        style: const TextStyle(
          color: Color(0xFFFF0044),
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          shadows: [
            Shadow(
              color: Color(0xFFFF0044),
              blurRadius: 8,
            ),
          ],
        ),
      );
    } else {
      waveText.text = 'WAVE ${game.currentWave}';
      waveText.textRenderer = TextPaint(
        style: const TextStyle(
          color: Color(0xFF00FF88),
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          shadows: [
            Shadow(
              color: Color(0xFF00FF88),
              blurRadius: 8,
            ),
          ],
        ),
      );
    }

    // 更新位置
    waveText.position = Vector2(game.size.x - 20, 20);
    controlsText.position = Vector2(game.size.x / 2, game.size.y - 25);
  }
}
