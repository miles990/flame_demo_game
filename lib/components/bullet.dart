import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/space_game.dart';
import 'enemy.dart' as enemy_component;

/// 子彈類型
enum BulletType {
  standard,     // 標準子彈
  spread,       // 散射子彈（較小）
  laser,        // 雷射（穿透）
  laserWide,    // 粗雷射
  missile,      // 飛彈（追蹤）
  plasma,       // 電漿（高傷害）
  plasmaSmall,  // 小電漿
  plasmaLarge,  // 大電漿
  enemy,        // 敵人子彈
  // 新增 Boss 曲線彈幕類型
  enemySine,    // 正弦波彈幕
  enemySpiral,  // 螺旋彈幕
  enemyHoming,  // 追蹤彈幕
}

class Bullet extends PositionComponent with HasGameReference<SpaceGame>, CollisionCallbacks {
  final double angle;
  final bool isPlayerBullet;
  final BulletType bulletType;
  final double speedMultiplier;  // 速度倍率（用於難度調整）

  // 曲線彈幕參數
  double _time = 0;
  double _sineAmplitude = 0;
  double _sineFrequency = 0;
  double _spiralSpeed = 0;
  bool _isHomingEnemy = false;

  Bullet({
    required super.position,
    this.angle = 0,
    this.isPlayerBullet = true,
    this.bulletType = BulletType.standard,
    this.speedMultiplier = 1.0,  // 預設速度倍率
  }) : super(
          size: _getSizeByType(bulletType, isPlayerBullet),
          anchor: Anchor.center,
        );

  static Vector2 _getSizeByType(BulletType type, bool isPlayer) {
    if (!isPlayer) {
      // 敵人子彈類型大小
      switch (type) {
        case BulletType.enemySine:
          return Vector2(8, 8);  // 圓形
        case BulletType.enemySpiral:
          return Vector2(10, 10);  // 較大圓形
        case BulletType.enemyHoming:
          return Vector2(6, 12);  // 箭頭形
        default:
          return Vector2(6, 20);
      }
    }

    switch (type) {
      case BulletType.standard:
        return Vector2(6, 20);
      case BulletType.spread:
        return Vector2(4, 12);
      case BulletType.laser:
        return Vector2(4, 30);
      case BulletType.laserWide:
        return Vector2(10, 40);
      case BulletType.missile:
        return Vector2(8, 16);
      case BulletType.plasma:
        return Vector2(12, 12);
      case BulletType.plasmaSmall:
        return Vector2(8, 8);
      case BulletType.plasmaLarge:
        return Vector2(18, 18);
      case BulletType.enemy:
      case BulletType.enemySine:
      case BulletType.enemySpiral:
      case BulletType.enemyHoming:
        return Vector2(6, 20);
    }
  }

  late double speed;
  late Vector2 velocity;
  int damage = 1;
  bool isPiercing = false;  // 穿透性
  int pierceCount = 0;      // 已穿透次數
  int maxPierce = 0;        // 最大穿透次數

  // 飛彈追蹤相關
  bool isHoming = false;
  double homingStrength = 0;

  @override
  Future<void> onLoad() async {
    // 根據子彈類型設定屬性
    _initBulletProperties();

    // 計算方向向量
    final direction = isPlayerBullet ? -1.0 : 1.0;
    velocity = Vector2(
      sin(angle) * speed,
      cos(angle) * speed * direction,
    );

    // 根據子彈類型選擇碰撞箱
    if (bulletType == BulletType.plasma ||
        bulletType == BulletType.plasmaSmall ||
        bulletType == BulletType.plasmaLarge) {
      add(CircleHitbox());
    } else {
      add(RectangleHitbox());
    }
  }

  void _initBulletProperties() {
    switch (bulletType) {
      case BulletType.standard:
        speed = 500;
        damage = 1;
        break;
      case BulletType.spread:
        speed = 450;
        damage = 1;
        break;
      case BulletType.laser:
        speed = 700;
        damage = 1;
        isPiercing = true;
        maxPierce = 3;
        break;
      case BulletType.laserWide:
        speed = 600;
        damage = 2;
        isPiercing = true;
        maxPierce = 5;
        break;
      case BulletType.missile:
        speed = 350;
        damage = 2;
        isHoming = true;
        homingStrength = 3.0;
        break;
      case BulletType.plasma:
        speed = 400;
        damage = 2;
        break;
      case BulletType.plasmaSmall:
        speed = 420;
        damage = 1;
        break;
      case BulletType.plasmaLarge:
        speed = 350;
        damage = 4;
        break;
      case BulletType.enemy:
        // 基礎敵人子彈速度調慢（從 300 降到 180）
        speed = 180 * speedMultiplier;
        damage = 1;
        break;
      case BulletType.enemySine:
        // 正弦波彈幕 - 較慢但有曲線
        speed = 150 * speedMultiplier;
        damage = 1;
        _sineAmplitude = 60;
        _sineFrequency = 4;
        break;
      case BulletType.enemySpiral:
        // 螺旋彈幕 - 旋轉前進
        speed = 120 * speedMultiplier;
        damage = 1;
        _spiralSpeed = 3;
        break;
      case BulletType.enemyHoming:
        // 追蹤彈幕 - 緩慢追蹤
        speed = 100 * speedMultiplier;
        damage = 1;
        _isHomingEnemy = true;
        break;
    }
  }

  @override
  void render(Canvas canvas) {
    if (!isPlayerBullet) {
      switch (bulletType) {
        case BulletType.enemySine:
          _renderSineBullet(canvas);
          return;
        case BulletType.enemySpiral:
          _renderSpiralBullet(canvas);
          return;
        case BulletType.enemyHoming:
          _renderHomingEnemyBullet(canvas);
          return;
        default:
          _renderEnemyBullet(canvas);
          return;
      }
    }

    switch (bulletType) {
      case BulletType.standard:
        _renderStandardBullet(canvas, const Color(0xFF00FF88));
        break;
      case BulletType.spread:
        _renderStandardBullet(canvas, const Color(0xFF88FF00));
        break;
      case BulletType.laser:
        _renderLaserBullet(canvas, const Color(0xFF00FFFF));
        break;
      case BulletType.laserWide:
        _renderLaserBullet(canvas, const Color(0xFF00FFFF));
        break;
      case BulletType.missile:
        _renderMissileBullet(canvas);
        break;
      case BulletType.plasma:
      case BulletType.plasmaSmall:
      case BulletType.plasmaLarge:
        _renderPlasmaBullet(canvas);
        break;
      case BulletType.enemy:
      case BulletType.enemySine:
      case BulletType.enemySpiral:
      case BulletType.enemyHoming:
        _renderEnemyBullet(canvas);
        break;
    }
  }

  /// 正弦波彈幕外觀 - 藍紫色波動球
  void _renderSineBullet(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final pulse = 1.0 + sin(_time * 8) * 0.2;

    // 外層光暈
    final glowPaint = Paint()
      ..color = const Color(0xFF6644FF).withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center, size.x / 2 * pulse + 3, glowPaint);

    // 核心
    final corePaint = Paint()
      ..color = const Color(0xFFAA88FF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size.x / 2 * pulse, corePaint);

    // 內核
    final innerPaint = Paint()
      ..color = Colors.white.withOpacity(0.8);
    canvas.drawCircle(center, size.x / 4, innerPaint);
  }

  /// 螺旋彈幕外觀 - 橙紅色旋轉球
  void _renderSpiralBullet(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);

    // 外層旋轉光暈
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_time * 5);

    final glowPaint = Paint()
      ..color = const Color(0xFFFF6600).withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // 旋轉的光芒
    for (int i = 0; i < 3; i++) {
      final angle = (i / 3) * pi * 2;
      canvas.drawCircle(
        Offset(cos(angle) * 4, sin(angle) * 4),
        size.x / 3,
        glowPaint,
      );
    }

    canvas.restore();

    // 核心
    final corePaint = Paint()
      ..color = const Color(0xFFFF4400)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size.x / 2.5, corePaint);

    // 亮點
    final brightPaint = Paint()
      ..color = const Color(0xFFFFAA00);
    canvas.drawCircle(Offset(center.dx - 2, center.dy - 2), 3, brightPaint);
  }

  /// 追蹤彈幕外觀 - 綠色箭頭
  void _renderHomingEnemyBullet(Canvas canvas) {
    // 計算朝向（根據速度方向）
    final rotation = atan2(velocity.x, -velocity.y);

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(rotation);

    // 光暈
    final glowPaint = Paint()
      ..color = const Color(0xFF00FF44).withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(Offset.zero, size.x / 2 + 3, glowPaint);

    // 箭頭形狀
    final arrowPaint = Paint()
      ..color = const Color(0xFF00CC44)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, -size.y / 2)
      ..lineTo(size.x / 2, size.y / 3)
      ..lineTo(0, size.y / 6)
      ..lineTo(-size.x / 2, size.y / 3)
      ..close();

    canvas.drawPath(path, arrowPaint);

    // 尾焰
    final flamePaint = Paint()
      ..color = const Color(0xFF88FF88).withOpacity(0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(Offset(0, size.y / 3), 4, flamePaint);

    canvas.restore();
  }

  void _renderStandardBullet(Canvas canvas, Color bulletColor) {
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

  void _renderLaserBullet(Canvas canvas, Color bulletColor) {
    // 外層光暈
    final glowPaint = Paint()
      ..color = bulletColor.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawRect(
      Rect.fromLTWH(-4, -2, size.x + 8, size.y + 4),
      glowPaint,
    );

    // 核心光束
    final corePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.2, 0, size.x * 0.6, size.y),
      corePaint,
    );

    // 外層
    final outerPaint = Paint()
      ..color = bulletColor
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      outerPaint..color = bulletColor.withOpacity(0.7),
    );
  }

  void _renderMissileBullet(Canvas canvas) {
    // 飛彈主體
    final bodyPaint = Paint()
      ..color = const Color(0xFFFF6600)
      ..style = PaintingStyle.fill;

    // 飛彈形狀
    final path = Path()
      ..moveTo(size.x / 2, 0)
      ..lineTo(size.x, size.y * 0.3)
      ..lineTo(size.x * 0.8, size.y * 0.3)
      ..lineTo(size.x * 0.8, size.y * 0.8)
      ..lineTo(size.x, size.y)
      ..lineTo(size.x * 0.5, size.y * 0.85)
      ..lineTo(0, size.y)
      ..lineTo(size.x * 0.2, size.y * 0.8)
      ..lineTo(size.x * 0.2, size.y * 0.3)
      ..lineTo(0, size.y * 0.3)
      ..close();

    canvas.drawPath(path, bodyPaint);

    // 尾焰
    final flamePaint = Paint()
      ..color = const Color(0xFFFFFF00)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawCircle(
      Offset(size.x / 2, size.y + 3),
      4,
      flamePaint,
    );
  }

  void _renderPlasmaBullet(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final radius = size.x / 2;

    // 外層光暈
    final glowPaint = Paint()
      ..color = const Color(0xFF8800FF).withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawCircle(center, radius + 5, glowPaint);

    // 中間層
    final midPaint = Paint()
      ..color = const Color(0xFFAA00FF)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, midPaint);

    // 核心
    final corePaint = Paint()
      ..color = const Color(0xFFFFAAFF)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.5, corePaint);

    // 閃光效果
    final sparkPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(center.dx - radius * 0.3, center.dy - radius * 0.3),
      radius * 0.2,
      sparkPaint,
    );
  }

  void _renderEnemyBullet(Canvas canvas) {
    final bulletColor = const Color(0xFFFF4444);

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
    _time += dt;

    // 飛彈追蹤邏輯（玩家）
    if (isHoming && isPlayerBullet) {
      _updateHoming(dt);
    }

    // 敵人曲線彈幕邏輯
    if (!isPlayerBullet) {
      switch (bulletType) {
        case BulletType.enemySine:
          _updateSineBullet(dt);
          return;
        case BulletType.enemySpiral:
          _updateSpiralBullet(dt);
          return;
        case BulletType.enemyHoming:
          _updateHomingEnemyBullet(dt);
          return;
        default:
          break;
      }
    }

    position += velocity * dt;

    // Remove if off screen
    if (position.y < -50 || position.y > game.size.y + 50 ||
        position.x < -50 || position.x > game.size.x + 50) {
      removeFromParent();
    }
  }

  /// 正弦波彈幕移動
  void _updateSineBullet(double dt) {
    // 基本向下移動
    position.y += speed * dt;

    // 正弦波左右擺動
    final sineOffset = sin(_time * _sineFrequency) * _sineAmplitude * dt * 10;
    position.x += sineOffset;

    _checkBounds();
  }

  /// 螺旋彈幕移動
  void _updateSpiralBullet(double dt) {
    // 螺旋軌跡
    final spiralAngle = _time * _spiralSpeed;
    final radius = 30 + _time * 20;  // 逐漸擴大的螺旋

    // 基礎向下移動 + 螺旋偏移
    position.y += speed * dt;
    position.x += cos(spiralAngle) * radius * dt;

    _checkBounds();
  }

  /// 敵人追蹤彈幕
  void _updateHomingEnemyBullet(double dt) {
    // 找玩家位置
    final playerPos = game.player.position;
    final toPlayer = (playerPos - position);

    if (toPlayer.length > 10) {
      final targetDirection = toPlayer.normalized();
      final currentDirection = velocity.normalized();

      // 緩慢轉向玩家（追蹤強度較低）
      final newDirection = (currentDirection + targetDirection * 1.5 * dt).normalized();
      velocity = newDirection * speed;
    }

    position += velocity * dt;
    _checkBounds();
  }

  void _checkBounds() {
    if (position.y < -50 || position.y > game.size.y + 50 ||
        position.x < -50 || position.x > game.size.x + 50) {
      removeFromParent();
    }
  }

  void _updateHoming(double dt) {
    // 找最近的敵人
    enemy_component.Enemy? nearestEnemy;
    double nearestDistance = double.infinity;

    for (final child in game.world.children) {
      if (child is enemy_component.Enemy) {
        final distance = position.distanceTo(child.position);
        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearestEnemy = child;
        }
      }
      // 也追蹤 Boss
      if (child is enemy_component.Boss) {
        final distance = position.distanceTo(child.position);
        if (distance < nearestDistance) {
          nearestDistance = distance;
          // 不能直接追蹤 Boss，但可以朝它的方向調整
        }
      }
    }

    if (nearestEnemy != null && nearestDistance < 300) {
      // 計算朝向敵人的方向
      final targetDirection = (nearestEnemy.position - position).normalized();
      final currentDirection = velocity.normalized();

      // 緩慢轉向
      final newDirection = (currentDirection + targetDirection * homingStrength * dt).normalized();
      velocity = newDirection * speed;
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    // 穿透邏輯
    if (isPiercing && isPlayerBullet) {
      if (other is enemy_component.Enemy || other is enemy_component.Boss) {
        pierceCount++;
        if (pierceCount > maxPierce) {
          removeFromParent();
        }
        // 穿透時不移除子彈，讓 enemy 處理傷害
      }
    }
  }

  /// 獲取子彈傷害（給敵人使用）
  int getDamage() => damage;
}
