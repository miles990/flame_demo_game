import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/space_game.dart';
import 'player.dart';
export 'player.dart' show WeaponType;

/// 道具類型
enum PowerUpType {
  weaponUpgrade,  // 武器升級
  shield,         // 護盾
  speedBoost,     // 加速
  rapidFire,      // 快速射擊
  bomb,           // 清屏炸彈
  extraLife,      // 額外生命
  // 新增武器類型道具
  weaponSpread,   // 散射武器
  weaponLaser,    // 雷射武器
  weaponMissile,  // 飛彈武器
  weaponPlasma,   // 電漿武器
  // 特殊獎勵道具（敵人群 bonus）
  megaBonus,      // 大獎勵（高分數 + 隨機道具）
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
      case PowerUpType.weaponSpread:
        return const Color(0xFF88FF00);  // 黃綠色
      case PowerUpType.weaponLaser:
        return const Color(0xFF00FFFF);  // 青色
      case PowerUpType.weaponMissile:
        return const Color(0xFFFF6600);  // 深橙色
      case PowerUpType.weaponPlasma:
        return const Color(0xFF8800FF);  // 紫羅蘭
      case PowerUpType.megaBonus:
        return const Color(0xFFFFD700);  // 金色
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
      case PowerUpType.weaponSpread:
        return 'SP';
      case PowerUpType.weaponLaser:
        return 'LA';
      case PowerUpType.weaponMissile:
        return 'MI';
      case PowerUpType.weaponPlasma:
        return 'PL';
      case PowerUpType.megaBonus:
        return '★';
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
      case PowerUpType.weaponSpread:
        player.changeWeapon(WeaponType.spread);
        break;
      case PowerUpType.weaponLaser:
        player.changeWeapon(WeaponType.laser);
        break;
      case PowerUpType.weaponMissile:
        player.changeWeapon(WeaponType.missile);
        break;
      case PowerUpType.weaponPlasma:
        player.changeWeapon(WeaponType.plasma);
        break;
      case PowerUpType.megaBonus:
        _triggerMegaBonus(player);
        break;
    }

    // 顯示獲得道具的提示
    game.addScore(50);
  }

  void _triggerMegaBonus(Player player) {
    // 大獎勵：給予大量分數
    game.addScore(500);

    // 隨機給予一個效果
    final random = Random();
    final effects = [
      () => player.upgradeWeapon(),
      () => player.activateShield(),
      () => player.activateRapidFire(),
      () => player.addLife(),
    ];
    effects[random.nextInt(effects.length)]();
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

  /// 根據機率生成道具類型（一般敵人）
  /// 掉落率從 30% 降低到 20%
  static PowerUpType? getRandomType() {
    final roll = _random.nextDouble();

    // 20% 機率掉落道具（降低一般掉落率）
    if (roll > 0.20) return null;

    return _selectPowerUpType();
  }

  /// 編隊敵人 bonus 掉落（必定掉落，且有機會掉落特殊道具）
  static PowerUpType getFormationBonusType() {
    final typeRoll = _random.nextDouble();

    // 30% 機率掉落大獎勵
    if (typeRoll < 0.30) {
      return PowerUpType.megaBonus;
    }

    // 30% 機率掉落武器道具
    if (typeRoll < 0.60) {
      return _selectWeaponType();
    }

    // 其餘掉落一般道具
    return _selectPowerUpType();
  }

  /// 選擇一般道具類型
  static PowerUpType _selectPowerUpType() {
    final typeRoll = _random.nextDouble();

    if (typeRoll < 0.30) {
      return PowerUpType.weaponUpgrade;  // 30% - 武器升級
    } else if (typeRoll < 0.50) {
      return PowerUpType.shield;         // 20% - 護盾
    } else if (typeRoll < 0.65) {
      return PowerUpType.rapidFire;      // 15% - 快速射擊
    } else if (typeRoll < 0.80) {
      return PowerUpType.speedBoost;     // 15% - 加速
    } else if (typeRoll < 0.92) {
      return PowerUpType.bomb;           // 12% - 清屏炸彈
    } else {
      return PowerUpType.extraLife;      // 8% - 額外生命
    }
  }

  /// 選擇武器道具類型
  static PowerUpType _selectWeaponType() {
    final weapons = [
      PowerUpType.weaponSpread,
      PowerUpType.weaponLaser,
      PowerUpType.weaponMissile,
      PowerUpType.weaponPlasma,
    ];
    return weapons[_random.nextInt(weapons.length)];
  }
}
