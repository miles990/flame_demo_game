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

/// Boss 類型
enum BossType {
  destroyer,    // 驅逐艦 - 標準 Boss，多砲管
  carrier,      // 航母 - 生成小怪
  fortress,     // 堡壘 - 高血量，環形攻擊
  phantom,      // 幻影 - 瞬移，快速攻擊
}

/// Boss 敵人
class Boss extends PositionComponent
    with HasGameReference<SpaceGame>, CollisionCallbacks {

  final int stage;
  final BossType bossType;
  late int maxHealth;
  late int health;
  double time = 0;
  double shootCooldown = 0;
  int attackPattern = 0;
  bool isActive = false;
  double entryProgress = 0;
  final double targetY = 100;

  // Phantom Boss 專用
  double _teleportCooldown = 0;
  double _opacity = 1.0;

  // Carrier Boss 專用
  double _spawnCooldown = 0;

  Boss({required this.stage})
      : bossType = _getBossTypeByStage(stage),
        super(
          size: _getSizeByStage(stage),
          anchor: Anchor.center,
        );

  static BossType _getBossTypeByStage(int stage) {
    switch (stage % 4) {
      case 1: return BossType.destroyer;
      case 2: return BossType.carrier;
      case 3: return BossType.fortress;
      case 0: return BossType.phantom;
      default: return BossType.destroyer;
    }
  }

  static Vector2 _getSizeByStage(int stage) {
    final type = _getBossTypeByStage(stage);
    switch (type) {
      case BossType.destroyer: return Vector2(150, 120);
      case BossType.carrier: return Vector2(180, 140);
      case BossType.fortress: return Vector2(200, 160);
      case BossType.phantom: return Vector2(120, 100);
    }
  }

  @override
  Future<void> onLoad() async {
    // 根據 Boss 類型調整血量
    maxHealth = switch (bossType) {
      BossType.destroyer => 20 + stage * 10,
      BossType.carrier => 25 + stage * 12,
      BossType.fortress => 40 + stage * 15,
      BossType.phantom => 15 + stage * 8,
    };
    health = maxHealth;
    position = Vector2(game.size.x / 2, -100);

    final hitboxSize = Vector2(size.x * 0.85, size.y * 0.85);
    add(RectangleHitbox(
      size: hitboxSize,
      position: (size - hitboxSize) / 2,
    ));
  }

  Color get _bossColor => switch (bossType) {
    BossType.destroyer => const Color(0xFFFF0088),
    BossType.carrier => const Color(0xFF00AA44),
    BossType.fortress => const Color(0xFF8844FF),
    BossType.phantom => const Color(0xFF00CCFF),
  };

  Color get _bossBodyColor => switch (bossType) {
    BossType.destroyer => const Color(0xFF880044),
    BossType.carrier => const Color(0xFF004422),
    BossType.fortress => const Color(0xFF442288),
    BossType.phantom => const Color(0xFF004466),
  };

  @override
  void render(Canvas canvas) {
    // Phantom Boss 透明度
    if (bossType == BossType.phantom) {
      canvas.saveLayer(null, Paint()..color = Colors.white.withOpacity(_opacity));
    }

    // Boss 外層光暈
    final glowPaint = Paint()
      ..color = _bossColor.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2,
      glowPaint,
    );

    // 根據 Boss 類型繪製不同外觀
    switch (bossType) {
      case BossType.destroyer:
        _renderDestroyer(canvas);
        break;
      case BossType.carrier:
        _renderCarrier(canvas);
        break;
      case BossType.fortress:
        _renderFortress(canvas);
        break;
      case BossType.phantom:
        _renderPhantom(canvas);
        break;
    }

    // 血量條
    _drawBossHealthBar(canvas);

    if (bossType == BossType.phantom) {
      canvas.restore();
    }
  }

  void _renderDestroyer(Canvas canvas) {
    final paint = Paint()
      ..color = _bossBodyColor
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

    final outlinePaint = Paint()
      ..color = _bossColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawPath(path, outlinePaint);

    _drawEyes(canvas, 3);
    _drawGuns(canvas, 3);
  }

  void _renderCarrier(Canvas canvas) {
    final paint = Paint()
      ..color = _bossBodyColor
      ..style = PaintingStyle.fill;

    // 航母主體 - 寬扁形狀
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.x * 0.05, size.y * 0.2, size.x * 0.9, size.y * 0.6),
      const Radius.circular(10),
    );
    canvas.drawRRect(rect, paint);

    // 艦橋
    final bridgePaint = Paint()..color = _bossBodyColor.withOpacity(0.8);
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.4, size.y * 0.05, size.x * 0.2, size.y * 0.25),
      bridgePaint,
    );

    final outlinePaint = Paint()
      ..color = _bossColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(rect, outlinePaint);

    // 機庫門
    for (int i = 0; i < 3; i++) {
      final hangarPaint = Paint()..color = Colors.black.withOpacity(0.5);
      canvas.drawRect(
        Rect.fromLTWH(size.x * (0.15 + i * 0.25), size.y * 0.7, size.x * 0.15, size.y * 0.15),
        hangarPaint,
      );
    }

    _drawEyes(canvas, 2);
  }

  void _renderFortress(Canvas canvas) {
    final paint = Paint()
      ..color = _bossBodyColor
      ..style = PaintingStyle.fill;

    // 堡壘主體 - 八角形
    final path = Path();
    final cx = size.x / 2;
    final cy = size.y / 2;
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * pi * 2 - pi / 2;
      final r = size.x * 0.45;
      final px = cx + cos(angle) * r;
      final py = cy + sin(angle) * r * 0.8;
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();

    canvas.drawPath(path, paint);

    // 內層防護
    final innerPaint = Paint()
      ..color = _bossColor.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), size.x * 0.25, innerPaint);

    final outlinePaint = Paint()
      ..color = _bossColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawPath(path, outlinePaint);

    _drawEyes(canvas, 1);
    _drawGuns(canvas, 4);
  }

  void _renderPhantom(Canvas canvas) {
    final paint = Paint()
      ..color = _bossBodyColor
      ..style = PaintingStyle.fill;

    // 幻影 - 流線型
    final path = Path()
      ..moveTo(size.x / 2, 0)
      ..quadraticBezierTo(size.x * 0.9, size.y * 0.2, size.x * 0.85, size.y * 0.5)
      ..quadraticBezierTo(size.x * 0.9, size.y * 0.8, size.x * 0.7, size.y)
      ..lineTo(size.x * 0.3, size.y)
      ..quadraticBezierTo(size.x * 0.1, size.y * 0.8, size.x * 0.15, size.y * 0.5)
      ..quadraticBezierTo(size.x * 0.1, size.y * 0.2, size.x / 2, 0)
      ..close();

    canvas.drawPath(path, paint);

    // 能量核心
    final corePaint = Paint()
      ..color = _bossColor.withOpacity(0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(size.x / 2, size.y * 0.4), 15, corePaint);

    final outlinePaint = Paint()
      ..color = _bossColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, outlinePaint);

    _drawEyes(canvas, 2);
  }

  void _drawEyes(Canvas canvas, int count) {
    final eyePaint = Paint()
      ..color = const Color(0xFFFF0000)
      ..style = PaintingStyle.fill;
    final eyeGlow = Paint()
      ..color = const Color(0xFFFFFF00)
      ..style = PaintingStyle.fill;

    final spacing = size.x / (count + 1);
    for (int i = 0; i < count; i++) {
      final x = spacing * (i + 1);
      final y = size.y * 0.4;
      canvas.drawCircle(Offset(x, y), 8, eyePaint);
      canvas.drawCircle(Offset(x, y), 3, eyeGlow);
    }
  }

  void _drawGuns(Canvas canvas, int count) {
    final gunPaint = Paint()..color = Colors.grey[700]!;
    final spacing = size.x / (count + 1);

    for (int i = 0; i < count; i++) {
      canvas.drawRect(
        Rect.fromLTWH(spacing * (i + 1) - 7, size.y * 0.8, 14, 25),
        gunPaint,
      );
    }
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

    // 根據 Boss 類型執行不同行為
    switch (bossType) {
      case BossType.destroyer:
        _updateDestroyer(dt);
        break;
      case BossType.carrier:
        _updateCarrier(dt);
        break;
      case BossType.fortress:
        _updateFortress(dt);
        break;
      case BossType.phantom:
        _updatePhantom(dt);
        break;
    }
  }

  void _updateDestroyer(double dt) {
    position.x = game.size.x / 2 + sin(time * 0.5) * 200;

    shootCooldown -= dt;
    if (shootCooldown <= 0) {
      _executeDestroyerAttack();
      attackPattern = (attackPattern + 1) % 3;
      shootCooldown = 1.5;
    }
  }

  void _updateCarrier(double dt) {
    position.x = game.size.x / 2 + sin(time * 0.3) * 150;

    // 生成小怪
    _spawnCooldown -= dt;
    if (_spawnCooldown <= 0) {
      _spawnMinions();
      _spawnCooldown = 4.0;
    }

    // 偶爾射擊
    shootCooldown -= dt;
    if (shootCooldown <= 0) {
      _executeCarrierAttack();
      shootCooldown = 2.5;
    }
  }

  void _updateFortress(double dt) {
    // 堡壘移動緩慢
    position.x = game.size.x / 2 + sin(time * 0.2) * 100;

    shootCooldown -= dt;
    if (shootCooldown <= 0) {
      _executeFortressAttack();
      attackPattern = (attackPattern + 1) % 2;
      shootCooldown = 1.2;
    }
  }

  void _updatePhantom(double dt) {
    // 瞬移邏輯
    _teleportCooldown -= dt;
    if (_teleportCooldown <= 0) {
      _teleport();
      _teleportCooldown = 3.0;
    }

    // 透明度波動
    _opacity = 0.5 + 0.5 * sin(time * 2).abs();

    // 快速射擊
    shootCooldown -= dt;
    if (shootCooldown <= 0) {
      _executePhantomAttack();
      shootCooldown = 0.8;
    }
  }

  void _teleport() {
    final random = Random();
    final newX = 100.0 + random.nextDouble() * (game.size.x - 200);
    position.x = newX;
  }

  void _spawnMinions() {
    final random = Random();
    for (int i = 0; i < 3; i++) {
      final offset = (i - 1) * 60.0;
      game.world.add(Enemy(
        position: position + Vector2(offset, size.y / 2 + 20),
        type: random.nextBool() ? EnemyType.fast : EnemyType.basic,
      ));
    }
  }

  void _executeDestroyerAttack() {
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

  void _executeCarrierAttack() {
    // 航母攻擊 - 寬範圍
    for (int i = -3; i <= 3; i++) {
      game.world.add(
        bullet_component.Bullet(
          position: position + Vector2(i * 25.0, size.y / 2),
          angle: 0,
          isPlayerBullet: false,
        ),
      );
    }
  }

  void _executeFortressAttack() {
    switch (attackPattern) {
      case 0:
        // 環形彈幕
        for (int i = 0; i < 12; i++) {
          final angle = (i / 12) * pi * 2 + time * 0.5;
          game.world.add(
            bullet_component.Bullet(
              position: position + Vector2(0, 0),
              angle: angle - pi / 2,
              isPlayerBullet: false,
            ),
          );
        }
        break;
      case 1:
        // 十字攻擊
        for (int i = 0; i < 4; i++) {
          final angle = (i / 4) * pi * 2;
          for (int j = 1; j <= 3; j++) {
            Future.delayed(Duration(milliseconds: j * 100), () {
              if (isMounted) {
                game.world.add(
                  bullet_component.Bullet(
                    position: position.clone(),
                    angle: angle - pi / 2,
                    isPlayerBullet: false,
                  ),
                );
              }
            });
          }
        }
        break;
    }
  }

  void _executePhantomAttack() {
    // 幻影攻擊 - 追蹤玩家方向
    final playerPos = game.player.position;
    final direction = (playerPos - position).normalized();
    final baseAngle = atan2(direction.x, -direction.y);

    for (int i = -1; i <= 1; i++) {
      game.world.add(
        bullet_component.Bullet(
          position: position + Vector2(0, size.y / 2),
          angle: baseAngle + i * 0.15,
          isPlayerBullet: false,
        ),
      );
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
