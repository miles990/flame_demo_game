import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/space_game.dart';

class StarBackground extends Component with HasGameReference<SpaceGame> {
  final List<Star> stars = [];
  final List<Nebula> nebulas = [];
  final Random random = Random();
  bool initialized = false;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    if (!initialized && size.x > 0 && size.y > 0) {
      // 生成星雲（背景裝飾）
      for (int i = 0; i < 5; i++) {
        nebulas.add(Nebula(
          x: random.nextDouble() * size.x,
          y: random.nextDouble() * size.y,
          radius: 80 + random.nextDouble() * 120,
          color: _randomNebulaColor(),
          speed: 5 + random.nextDouble() * 10,
        ));
      }

      // 生成遠景星星（小、慢）
      for (int i = 0; i < 60; i++) {
        stars.add(Star(
          x: random.nextDouble() * size.x,
          y: random.nextDouble() * size.y,
          size: 0.5 + random.nextDouble() * 1,
          speed: 15 + random.nextDouble() * 25,
          brightness: 0.2 + random.nextDouble() * 0.4,
          twinkleSpeed: random.nextDouble() * 3,
          layer: 0,
        ));
      }

      // 生成中景星星（中、中速）
      for (int i = 0; i < 40; i++) {
        stars.add(Star(
          x: random.nextDouble() * size.x,
          y: random.nextDouble() * size.y,
          size: 1 + random.nextDouble() * 1.5,
          speed: 40 + random.nextDouble() * 40,
          brightness: 0.4 + random.nextDouble() * 0.4,
          twinkleSpeed: random.nextDouble() * 5,
          layer: 1,
        ));
      }

      // 生成近景星星（大、快、有顏色）
      for (int i = 0; i < 20; i++) {
        stars.add(Star(
          x: random.nextDouble() * size.x,
          y: random.nextDouble() * size.y,
          size: 2 + random.nextDouble() * 2,
          speed: 80 + random.nextDouble() * 60,
          brightness: 0.7 + random.nextDouble() * 0.3,
          twinkleSpeed: random.nextDouble() * 8,
          layer: 2,
          color: _randomStarColor(),
        ));
      }

      initialized = true;
    }
  }

  Color _randomNebulaColor() {
    final colors = [
      const Color(0xFF1a0a2e),
      const Color(0xFF0a1a2e),
      const Color(0xFF2e0a1a),
      const Color(0xFF0a2e1a),
    ];
    return colors[random.nextInt(colors.length)];
  }

  Color _randomStarColor() {
    final colors = [
      Colors.white,
      const Color(0xFFFFE4C4), // 暖白
      const Color(0xFFC4E4FF), // 冷白
      const Color(0xFFFFD700), // 金色
      const Color(0xFFADD8E6), // 淺藍
    ];
    return colors[random.nextInt(colors.length)];
  }

  @override
  void render(Canvas canvas) {
    // 繪製星雲
    for (final nebula in nebulas) {
      final paint = Paint()
        ..color = nebula.color.withOpacity(0.15)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, nebula.radius * 0.5);

      canvas.drawCircle(
        Offset(nebula.x, nebula.y),
        nebula.radius,
        paint,
      );
    }

    // 繪製星星
    for (final star in stars) {
      // 閃爍效果
      final twinkle = 0.7 + 0.3 * sin(star.twinklePhase);
      final currentBrightness = star.brightness * twinkle;

      // 星星光暈
      if (star.layer == 2) {
        final glowPaint = Paint()
          ..color = star.color.withOpacity(currentBrightness * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

        canvas.drawCircle(
          Offset(star.x, star.y),
          star.size * 2,
          glowPaint,
        );
      }

      // 星星主體
      final paint = Paint()
        ..color = star.color.withOpacity(currentBrightness)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(star.x, star.y),
        star.size,
        paint,
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 更新星雲
    for (final nebula in nebulas) {
      nebula.y += nebula.speed * dt;

      if (nebula.y > game.size.y + nebula.radius) {
        nebula.y = -nebula.radius;
        nebula.x = random.nextDouble() * game.size.x;
      }
    }

    // 更新星星
    for (final star in stars) {
      star.y += star.speed * dt;
      star.twinklePhase += star.twinkleSpeed * dt;

      if (star.y > game.size.y + 5) {
        star.y = -5;
        star.x = random.nextDouble() * game.size.x;
      }
    }
  }
}

class Star {
  double x;
  double y;
  double size;
  double speed;
  double brightness;
  double twinkleSpeed;
  double twinklePhase;
  int layer;
  Color color;

  Star({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.brightness,
    this.twinkleSpeed = 1.0,
    this.layer = 0,
    this.color = Colors.white,
  }) : twinklePhase = 0;
}

class Nebula {
  double x;
  double y;
  double radius;
  Color color;
  double speed;

  Nebula({
    required this.x,
    required this.y,
    required this.radius,
    required this.color,
    required this.speed,
  });
}
