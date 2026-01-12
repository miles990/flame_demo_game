import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/space_game.dart';

class Bullet extends PositionComponent with HasGameReference<SpaceGame> {
  final double angle;
  final bool isPlayerBullet;

  Bullet({
    required super.position,
    this.angle = 0,
    this.isPlayerBullet = true,
  }) : super(
          size: Vector2(6, 20),
          anchor: Anchor.center,
        );

  final double speed = 500;
  late Vector2 velocity;

  @override
  Future<void> onLoad() async {
    // 計算方向向量
    final direction = isPlayerBullet ? -1.0 : 1.0;
    velocity = Vector2(
      sin(angle) * speed,
      cos(angle) * speed * direction,
    );

    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    // 根據是玩家還是敵人子彈選擇顏色
    final bulletColor = isPlayerBullet
        ? const Color(0xFF00FF88)  // 綠色（玩家）
        : const Color(0xFFFF4444); // 紅色（敵人）

    // Draw bullet with glow effect
    final glowPaint = Paint()
      ..color = bulletColor.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-2, -2, size.x + 4, size.y + 4),
        const Radius.circular(4),
      ),
      glowPaint,
    );

    final paint = Paint()
      ..color = bulletColor
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(3),
      ),
      paint,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    position += velocity * dt;

    // Remove if off screen
    if (position.y < -50 || position.y > game.size.y + 50 ||
        position.x < -50 || position.x > game.size.x + 50) {
      removeFromParent();
    }
  }
}
