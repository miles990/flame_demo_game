import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/space_game.dart';
import 'bullet.dart' as bullet_component;
import 'power_up.dart';

/// 敵人類型
enum EnemyType {
  basic,      // 基本敵人 - 正弦波移動
  fast,       // 快速敵人 - 直線高速
  tank,       // 坦克敵人 - 慢但血厚
  shooter,    // 射擊敵人 - 會發射子彈
  zigzag,     // Z字形敵人 - 來回移動
}

class Enemy extends PositionComponent
    with HasGameReference<SpaceGame>, CollisionCallbacks {

  final EnemyType type;
  int health;

  Enemy({
    required super.position,
    this.type = EnemyType.basic,
  }) : health = _getHealthByType(type),
       super(
         size: _getSizeByType(type),
         anchor: Anchor.center,
       );

  static int _getHealthByType(EnemyType type) {
    switch (type) {
      case EnemyType.basic: return 1;
      case EnemyType.fast: return 1;
      case EnemyType.tank: return 3;
      case EnemyType.shooter: return 2;
      case EnemyType.zigzag: return 1;
    }
  }

  static Vector2 _getSizeByType(EnemyType type) {
    switch (type) {
      case EnemyType.basic: return Vector2(40, 40);
      case EnemyType.fast: return Vector2(30, 35);
      case EnemyType.tank: return Vector2(55, 55);
      case EnemyType.shooter: return Vector2(45, 45);
      case EnemyType.zigzag: return Vector2(35, 35);
    }
  }

  late double speed;
  late double amplitude;
  late double frequency;
  double time = 0;
  double startX = 0;
  double shootCooldown = 0;
  int zigzagDirection = 1;

  @override
  Future<void> onLoad() async {
    final random = Random();

    switch (type) {
      case EnemyType.basic:
        speed = 100 + random.nextDouble() * 80;
        amplitude = 30 + random.nextDouble() * 50;
        frequency = 1 + random.nextDouble() * 2;
        break;
      case EnemyType.fast:
        speed = 250 + random.nextDouble() * 100;
        amplitude = 0;
        frequency = 0;
        break;
      case EnemyType.tank:
        speed = 60 + random.nextDouble() * 30;
        amplitude = 20;
        frequency = 0.5;
        break;
      case EnemyType.shooter:
        speed = 80 + random.nextDouble() * 40;
        amplitude = 50;
        frequency = 1;
        shootCooldown = 2.0;
        break;
      case EnemyType.zigzag:
        speed = 120 + random.nextDouble() * 60;
        amplitude = 150;
        frequency = 0;
        zigzagDirection = random.nextBool() ? 1 : -1;
        break;
    }

    startX = position.x;
    add(CircleHitbox());
  }

  Color get _color {
    switch (type) {
      case EnemyType.basic: return const Color(0xFFCC2222);
      case EnemyType.fast: return const Color(0xFFFF8800);
      case EnemyType.tank: return const Color(0xFF666688);
      case EnemyType.shooter: return const Color(0xFF8822CC);
      case EnemyType.zigzag: return const Color(0xFF22CCCC);
    }
  }

  @override
  void render(Canvas canvas) {
    // 外層光暈
    final glowPaint = Paint()
      ..color = _color.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2 + 5,
      glowPaint,
    );

    // 根據敵人類型繪製不同外觀
    switch (type) {
      case EnemyType.basic:
        _drawHexagon(canvas);
        break;
      case EnemyType.fast:
        _drawTriangle(canvas);
        break;
      case EnemyType.tank:
        _drawSquare(canvas);
        break;
      case EnemyType.shooter:
        _drawDiamond(canvas);
        break;
      case EnemyType.zigzag:
        _drawStar(canvas);
        break;
    }

    // 血量指示（坦克和射手）
    if (type == EnemyType.tank || type == EnemyType.shooter) {
      _drawHealthBar(canvas);
    }
  }

  void _drawHexagon(Canvas canvas) {
    final paint = Paint()
      ..color = _color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.x / 2, 0)
      ..lineTo(size.x * 0.9, size.y * 0.25)
      ..lineTo(size.x * 0.9, size.y * 0.75)
      ..lineTo(size.x / 2, size.y)
      ..lineTo(size.x * 0.1, size.y * 0.75)
      ..lineTo(size.x * 0.1, size.y * 0.25)
      ..close();

    canvas.drawPath(path, paint);
    _drawOutlineAndEye(canvas, path);
  }

  void _drawTriangle(Canvas canvas) {
    final paint = Paint()
      ..color = _color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.x / 2, 0)
      ..lineTo(size.x, size.y)
      ..lineTo(0, size.y)
      ..close();

    canvas.drawPath(path, paint);
    _drawOutlineAndEye(canvas, path);
  }

  void _drawSquare(Canvas canvas) {
    final paint = Paint()
      ..color = _color
      ..style = PaintingStyle.fill;

    final rect = Rect.fromLTWH(size.x * 0.1, size.y * 0.1,
                                size.x * 0.8, size.y * 0.8);
    canvas.drawRect(rect, paint);

    final outlinePaint = Paint()
      ..color = _color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRect(rect, outlinePaint);

    // 裝甲紋路
    final linePaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(size.x * 0.3, size.y * 0.1),
                    Offset(size.x * 0.3, size.y * 0.9), linePaint);
    canvas.drawLine(Offset(size.x * 0.7, size.y * 0.1),
                    Offset(size.x * 0.7, size.y * 0.9), linePaint);

    _drawEye(canvas);
  }

  void _drawDiamond(Canvas canvas) {
    final paint = Paint()
      ..color = _color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.x / 2, 0)
      ..lineTo(size.x, size.y / 2)
      ..lineTo(size.x / 2, size.y)
      ..lineTo(0, size.y / 2)
      ..close();

    canvas.drawPath(path, paint);
    _drawOutlineAndEye(canvas, path);

    // 砲管
    final gunPaint = Paint()
      ..color = Colors.grey[800]!
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.4, size.y * 0.7, size.x * 0.2, size.y * 0.4),
      gunPaint,
    );
  }

  void _drawStar(Canvas canvas) {
    final paint = Paint()
      ..color = _color
      ..style = PaintingStyle.fill;

    final path = Path();
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    final outerRadius = size.x / 2;
    final innerRadius = size.x / 4;

    for (int i = 0; i < 5; i++) {
      final outerAngle = (i * 72 - 90) * pi / 180;
      final innerAngle = ((i * 72) + 36 - 90) * pi / 180;

      if (i == 0) {
        path.moveTo(
          centerX + outerRadius * cos(outerAngle),
          centerY + outerRadius * sin(outerAngle),
        );
      } else {
        path.lineTo(
          centerX + outerRadius * cos(outerAngle),
          centerY + outerRadius * sin(outerAngle),
        );
      }
      path.lineTo(
        centerX + innerRadius * cos(innerAngle),
        centerY + innerRadius * sin(innerAngle),
      );
    }
    path.close();

    canvas.drawPath(path, paint);
    _drawOutlineAndEye(canvas, path);
  }

  void _drawOutlineAndEye(Canvas canvas, Path path) {
    final outlinePaint = Paint()
      ..color = _color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, outlinePaint);
    _drawEye(canvas);
  }

  void _drawEye(Canvas canvas) {
    final eyePaint = Paint()
      ..color = const Color(0xFFFFFF00)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      6,
      eyePaint,
    );

    final eyeGlow = Paint()
      ..color = const Color(0xFFFF8800).withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      8,
      eyeGlow,
    );
  }

  void _drawHealthBar(Canvas canvas) {
    final maxHealth = _getHealthByType(type);
    final barWidth = size.x * 0.8;
    final barHeight = 4.0;
    final barX = size.x * 0.1;
    final barY = -8.0;

    // 背景
    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barWidth, barHeight),
      Paint()..color = Colors.grey[800]!,
    );

    // 血量
    final healthPercent = health / maxHealth;
    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barWidth * healthPercent, barHeight),
      Paint()..color = healthPercent > 0.5 ? Colors.green : Colors.red,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    time += dt;

    switch (type) {
      case EnemyType.basic:
        position.y += speed * dt;
        position.x = startX + sin(time * frequency) * amplitude;
        break;

      case EnemyType.fast:
        position.y += speed * dt;
        break;

      case EnemyType.tank:
        position.y += speed * dt;
        position.x = startX + sin(time * frequency) * amplitude;
        break;

      case EnemyType.shooter:
        position.y += speed * dt;
        position.x = startX + sin(time * frequency) * amplitude;
        _handleShooting(dt);
        break;

      case EnemyType.zigzag:
        position.y += speed * dt;
        position.x += zigzagDirection * 200 * dt;
        if (position.x < 50 || position.x > game.size.x - 50) {
          zigzagDirection *= -1;
        }
        break;
    }

    // Remove if off screen
    if (position.y > game.size.y + 100) {
      removeFromParent();
    }
  }

  void _handleShooting(double dt) {
    shootCooldown -= dt;
    if (shootCooldown <= 0) {
      _shoot();
      shootCooldown = 2.0 + Random().nextDouble();
    }
  }

  void _shoot() {
    game.world.add(
      bullet_component.Bullet(
        position: position + Vector2(0, size.y / 2),
        angle: 0,
        isPlayerBullet: false,
      ),
    );
  }

  void takeDamage() {
    health--;
    if (health <= 0) {
      _onDestroyed();
    }
  }

  void _onDestroyed() {
    // 計算分數
    final score = switch (type) {
      EnemyType.basic => 100,
      EnemyType.fast => 150,
      EnemyType.tank => 300,
      EnemyType.shooter => 250,
      EnemyType.zigzag => 120,
    };
    game.addScore(score);

    // 通知遊戲敵人被擊殺
    game.onEnemyKilled();

    // 嘗試掉落道具
    final powerUpType = PowerUpSpawner.getRandomType();
    if (powerUpType != null) {
      game.world.add(
        PowerUp(position: position.clone(), type: powerUpType),
      );
    }

    // 爆炸效果
    game.world.add(Explosion(position: position.clone()));
    removeFromParent();
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is bullet_component.Bullet && other.isPlayerBullet) {
      other.removeFromParent();
      takeDamage();
    }
  }
}

/// 爆炸特效
class Explosion extends PositionComponent with HasGameReference<SpaceGame> {
  Explosion({required super.position})
      : super(
          size: Vector2.all(60),
          anchor: Anchor.center,
        );

  double lifetime = 0;
  final double maxLifetime = 0.3;

  @override
  void render(Canvas canvas) {
    final progress = (lifetime / maxLifetime).clamp(0.0, 1.0);
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    final scale = 1.0 + progress;

    final baseColor = Color.lerp(
      const Color(0xFFFFFF00),
      const Color(0xFFFF4400),
      progress,
    )!;

    final paint = Paint()
      ..color = baseColor.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      (size.x / 2) * scale,
      paint,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    lifetime += dt;

    if (lifetime >= maxLifetime) {
      removeFromParent();
    }
  }
}

/// Boss 敵人
class Boss extends PositionComponent
    with HasGameReference<SpaceGame>, CollisionCallbacks {

  final int stage;
  late int maxHealth;
  late int health;
  double time = 0;
  double shootCooldown = 0;
  int attackPattern = 0;
  bool isActive = false;
  double entryProgress = 0;
  final double targetY = 100;

  Boss({required this.stage})
      : super(
          size: Vector2(150, 120),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    maxHealth = 20 + stage * 10;
    health = maxHealth;
    position = Vector2(game.size.x / 2, -100);

    add(RectangleHitbox(
      size: Vector2(130, 100),
      position: Vector2(10, 10),
    ));
  }

  @override
  void render(Canvas canvas) {
    // Boss 外層光暈
    final glowPaint = Paint()
      ..color = const Color(0xFFFF0088).withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2,
      glowPaint,
    );

    // Boss 主體
    final paint = Paint()
      ..color = const Color(0xFF880044)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.x / 2, 0)
      ..lineTo(size.x * 0.9, size.y * 0.3)
      ..lineTo(size.x, size.y * 0.5)
      ..lineTo(size.x * 0.85, size.y * 0.8)
      ..lineTo(size.x * 0.7, size.y)
      ..lineTo(size.x * 0.3, size.y)
      ..lineTo(size.x * 0.15, size.y * 0.8)
      ..lineTo(0, size.y * 0.5)
      ..lineTo(size.x * 0.1, size.y * 0.3)
      ..close();

    canvas.drawPath(path, paint);

    // 輪廓
    final outlinePaint = Paint()
      ..color = const Color(0xFFFF0088)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawPath(path, outlinePaint);

    // Boss 眼睛（3個）
    final eyePaint = Paint()
      ..color = const Color(0xFFFF0000)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.x * 0.3, size.y * 0.4), 10, eyePaint);
    canvas.drawCircle(Offset(size.x * 0.5, size.y * 0.35), 12, eyePaint);
    canvas.drawCircle(Offset(size.x * 0.7, size.y * 0.4), 10, eyePaint);

    // 眼睛光芒
    final eyeGlow = Paint()
      ..color = const Color(0xFFFFFF00)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.x * 0.3, size.y * 0.4), 4, eyeGlow);
    canvas.drawCircle(Offset(size.x * 0.5, size.y * 0.35), 5, eyeGlow);
    canvas.drawCircle(Offset(size.x * 0.7, size.y * 0.4), 4, eyeGlow);

    // 砲管
    final gunPaint = Paint()
      ..color = Colors.grey[700]!;
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.2, size.y * 0.8, 15, 25),
      gunPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.45, size.y * 0.85, 15, 30),
      gunPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.7, size.y * 0.8, 15, 25),
      gunPaint,
    );

    // 血量條
    _drawBossHealthBar(canvas);
  }

  void _drawBossHealthBar(Canvas canvas) {
    final barWidth = size.x * 0.9;
    final barHeight = 8.0;
    final barX = size.x * 0.05;
    final barY = -20.0;

    // 背景
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barY, barWidth, barHeight),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.grey[900]!,
    );

    // 血量
    final healthPercent = health / maxHealth;
    final healthColor = healthPercent > 0.5
        ? Colors.green
        : healthPercent > 0.25
            ? Colors.orange
            : Colors.red;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barY, barWidth * healthPercent, barHeight),
        const Radius.circular(4),
      ),
      Paint()..color = healthColor,
    );

    // 邊框
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barY, barWidth, barHeight),
        const Radius.circular(4),
      ),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    time += dt;

    // 進場動畫
    if (!isActive) {
      entryProgress += dt * 0.5;
      position.y = -100 + (targetY + 100) * entryProgress.clamp(0.0, 1.0);
      if (entryProgress >= 1.0) {
        isActive = true;
      }
      return;
    }

    // Boss 移動模式
    position.x = game.size.x / 2 + sin(time * 0.5) * 200;

    // 攻擊模式
    shootCooldown -= dt;
    if (shootCooldown <= 0) {
      _executeAttackPattern();
      attackPattern = (attackPattern + 1) % 3;
      shootCooldown = 1.5;
    }
  }

  void _executeAttackPattern() {
    switch (attackPattern) {
      case 0:
        // 散射
        for (int i = -2; i <= 2; i++) {
          game.world.add(
            bullet_component.Bullet(
              position: position + Vector2(0, size.y / 2),
              angle: i * 0.2,
              isPlayerBullet: false,
            ),
          );
        }
        break;
      case 1:
        // 三連發
        for (int i = 0; i < 3; i++) {
          final offset = (i - 1) * 40.0;
          game.world.add(
            bullet_component.Bullet(
              position: position + Vector2(offset, size.y / 2),
              angle: 0,
              isPlayerBullet: false,
            ),
          );
        }
        break;
      case 2:
        // 環形攻擊
        for (int i = 0; i < 8; i++) {
          final angle = (i / 8) * pi * 2;
          game.world.add(
            bullet_component.Bullet(
              position: position + Vector2(0, size.y / 2),
              angle: angle - pi / 2,
              isPlayerBullet: false,
            ),
          );
        }
        break;
    }
  }

  void takeDamage() {
    health--;
    if (health <= 0) {
      _onDestroyed();
    }
  }

  void _onDestroyed() {
    game.addScore(1000 * stage);

    // 掉落多個道具
    final random = Random();
    for (int i = 0; i < 3; i++) {
      final offset = Vector2(
        (random.nextDouble() - 0.5) * 100,
        (random.nextDouble() - 0.5) * 50,
      );
      game.world.add(
        PowerUp(
          position: position + offset,
          type: PowerUpType.values[random.nextInt(PowerUpType.values.length)],
        ),
      );
    }

    // 大爆炸
    for (int i = 0; i < 5; i++) {
      final offset = Vector2(
        (random.nextDouble() - 0.5) * size.x,
        (random.nextDouble() - 0.5) * size.y,
      );
      game.world.add(Explosion(position: position + offset));
    }

    game.onBossDefeated();
    removeFromParent();
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is bullet_component.Bullet && other.isPlayerBullet) {
      other.removeFromParent();
      takeDamage();
    }
  }
}

/// 敵人生成器配置
class EnemySpawnConfig {
  static EnemyType getRandomType(int wave) {
    final random = Random();
    final roll = random.nextDouble();

    // 根據波數調整敵人出現機率
    if (wave < 3) {
      // 前期只有基本和快速敵人
      return roll < 0.7 ? EnemyType.basic : EnemyType.fast;
    } else if (wave < 6) {
      // 中期加入更多種類
      if (roll < 0.4) return EnemyType.basic;
      if (roll < 0.6) return EnemyType.fast;
      if (roll < 0.8) return EnemyType.zigzag;
      return EnemyType.shooter;
    } else {
      // 後期全種類
      if (roll < 0.25) return EnemyType.basic;
      if (roll < 0.4) return EnemyType.fast;
      if (roll < 0.55) return EnemyType.zigzag;
      if (roll < 0.75) return EnemyType.shooter;
      return EnemyType.tank;
    }
  }
}
