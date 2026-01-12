import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/space_game.dart';
import 'player.dart';

/// 道具類型
enum PowerUpType {
  weaponUpgrade,  // 武器升級
  shield,         // 護盾
  speedBoost,     // 加速
  rapidFire,      // 快速射擊
  bomb,           // 清屏炸彈
  extraLife,      // 額外生命
}

class PowerUp extends PositionComponent
    with HasGameReference<SpaceGame>, CollisionCallbacks {

  final PowerUpType type;
  final double fallSpeed = 80;
  double _animTime = 0;

  PowerUp({
    required super.position,
    required this.type,
  }) : super(
    size: Vector2.all(30),
    anchor: Anchor.center,
  );

  // 道具顏色映射
  Color get _color {
    switch (type) {
      case PowerUpType.weaponUpgrade:
        return const Color(0xFFFF6B00);  // 橙色
      case PowerUpType.shield:
        return const Color(0xFF00BFFF);  // 藍色
      case PowerUpType.speedBoost:
        return const Color(0xFFFFFF00);  // 黃色
      case PowerUpType.rapidFire:
        return const Color(0xFFFF00FF);  // 紫色
      case PowerUpType.bomb:
        return const Color(0xFFFF0000);  // 紅色
      case PowerUpType.extraLife:
        return const Color(0xFF00FF00);  // 綠色
    }
  }

  // 道具圖示
  String get _symbol {
    switch (type) {
      case PowerUpType.weaponUpgrade:
        return 'W';
      case PowerUpType.shield:
        return 'S';
      case PowerUpType.speedBoost:
        return '>';
      case PowerUpType.rapidFire:
        return 'R';
      case PowerUpType.bomb:
        return 'B';
      case PowerUpType.extraLife:
        return '+';
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  @override
  void render(Canvas canvas) {
    final pulse = 0.8 + 0.2 * sin(_animTime * 5);
    final rotation = _animTime * 2;

    // 外層光暈
    final glowPaint = Paint()
      ..color = _color.withOpacity(0.3 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2 + 5,
      glowPaint,
    );

    // 旋轉的外框
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(rotation);

    // 菱形外框
    final outlinePaint = Paint()
      ..color = _color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final outlinePath = Path()
      ..moveTo(0, -size.y / 2)
      ..lineTo(size.x / 2, 0)
      ..lineTo(0, size.y / 2)
      ..lineTo(-size.x / 2, 0)
      ..close();

    canvas.drawPath(outlinePath, outlinePaint);
    canvas.restore();

    // 內部圓形
    final innerPaint = Paint()
      ..color = _color.withOpacity(0.8 * pulse)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 3,
      innerPaint,
    );

    // 道具符號
    final textPainter = TextPainter(
      text: TextSpan(
        text: _symbol,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.x - textPainter.width) / 2,
        (size.y - textPainter.height) / 2,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animTime += dt;

    // 向下飄落
    position.y += fallSpeed * dt;

    // 輕微左右搖擺
    position.x += sin(_animTime * 3) * 20 * dt;

    // 超出螢幕移除
    if (position.y > game.size.y + 50) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Player) {
      // 套用道具效果
      _applyEffect(other);
      removeFromParent();
    }
  }

  void _applyEffect(Player player) {
    switch (type) {
      case PowerUpType.weaponUpgrade:
        player.upgradeWeapon();
        break;
      case PowerUpType.shield:
        player.activateShield();
        break;
      case PowerUpType.speedBoost:
        player.activateSpeedBoost();
        break;
      case PowerUpType.rapidFire:
        player.activateRapidFire();
        break;
      case PowerUpType.bomb:
        _triggerBomb();
        break;
      case PowerUpType.extraLife:
        player.addLife();
        break;
    }

    // 顯示獲得道具的提示
    game.addScore(50);
  }

  void _triggerBomb() {
    // 清除所有敵人
    game.world.children
        .whereType<PositionComponent>()
        .where((c) => c.runtimeType.toString() == 'Enemy')
        .toList()
        .forEach((enemy) {
          game.addScore(50);
          enemy.removeFromParent();
        });
  }
}

/// 道具生成器 - 決定掉落什麼道具
class PowerUpSpawner {
  static final _random = Random();

  /// 根據機率生成道具類型
  static PowerUpType? getRandomType() {
    final roll = _random.nextDouble();

    // 30% 機率掉落道具
    if (roll > 0.30) return null;

    // 道具機率分配
    final typeRoll = _random.nextDouble();
    if (typeRoll < 0.35) {
      return PowerUpType.weaponUpgrade;  // 35% - 武器升級
    } else if (typeRoll < 0.55) {
      return PowerUpType.shield;         // 20% - 護盾
    } else if (typeRoll < 0.70) {
      return PowerUpType.rapidFire;      // 15% - 快速射擊
    } else if (typeRoll < 0.85) {
      return PowerUpType.speedBoost;     // 15% - 加速
    } else if (typeRoll < 0.95) {
      return PowerUpType.bomb;           // 10% - 清屏炸彈
    } else {
      return PowerUpType.extraLife;      // 5% - 額外生命
    }
  }
}
