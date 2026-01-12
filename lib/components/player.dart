import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/space_game.dart';
import 'bullet.dart' as bullet_component;
import 'enemy.dart' as enemy_component;

/// 武器類型
enum WeaponType {
  standard,   // 標準武器 - 平衡型
  spread,     // 散射武器 - 寬範圍但傷害低
  laser,      // 雷射武器 - 穿透型
  missile,    // 飛彈武器 - 追蹤型
  plasma,     // 電漿武器 - 高傷害但慢
}

class Player extends PositionComponent
    with HasGameReference<SpaceGame>, KeyboardHandler, CollisionCallbacks {

  Player({required super.position})
      : super(
          size: Vector2(50, 60),
          anchor: Anchor.center,
          priority: 100,
        );

  // 基本屬性
  double baseSpeed = 350;
  double get speed => baseSpeed * (hasSpeedBoost ? 1.5 : 1.0);
  final Vector2 velocity = Vector2.zero();

  // 射擊屬性
  double shootCooldown = 0;
  double baseShootInterval = 0.18;
  double get shootInterval => baseShootInterval * (hasRapidFire ? 0.5 : 1.0);

  // 輸入狀態
  int horizontalDirection = 0;
  int verticalDirection = 0;
  bool isShooting = false;

  // === 強化系統 ===
  int weaponLevel = 1;           // 武器等級 1-4
  WeaponType weaponType = WeaponType.standard;  // 武器類型
  int lives = 3;                 // 生命數
  bool hasShield = false;        // 護盾狀態
  bool hasSpeedBoost = false;    // 加速狀態
  bool hasRapidFire = false;     // 快速射擊狀態

  // Buff 計時器
  double _shieldTimer = 0;
  double _speedBoostTimer = 0;
  double _rapidFireTimer = 0;

  // Buff 持續時間
  static const double shieldDuration = 8.0;
  static const double speedBoostDuration = 6.0;
  static const double rapidFireDuration = 5.0;

  // 無敵狀態（被擊中後短暫無敵）
  bool isInvincible = false;
  double _invincibleTimer = 0;
  static const double invincibleDuration = 2.0;

  // 視覺效果
  double _engineFlicker = 0;
  double _shieldPulse = 0;

  late Paint _shipPaint;
  late Paint _shipOutline;
  late Paint _glowPaint;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _shipPaint = Paint()
      ..color = const Color(0xFF00D4FF)
      ..style = PaintingStyle.fill;

    _shipOutline = Paint()
      ..color = const Color(0xFF00FFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    _glowPaint = Paint()
      ..color = const Color(0xFFFF6B00)
      ..style = PaintingStyle.fill;

    add(RectangleHitbox(
      size: Vector2(40, 50),
      position: Vector2(5, 5),
    ));

    debugPrint('Player loaded at position: $position, size: $size');
  }

  @override
  void render(Canvas canvas) {
    // 無敵閃爍效果
    if (isInvincible && ((_invincibleTimer * 10).toInt() % 2 == 0)) {
      return; // 閃爍時不繪製
    }

    // 繪製護盾（如果有）
    if (hasShield) {
      final shieldOpacity = (0.3 + 0.2 * sin(_shieldPulse * 3)).clamp(0.0, 1.0);
      final shieldPaint = Paint()
        ..color = const Color(0xFF00BFFF).withOpacity(shieldOpacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        40,
        shieldPaint,
      );

      // 護盾邊框
      final shieldBorder = Paint()
        ..color = const Color(0xFF00BFFF).withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        40,
        shieldBorder,
      );
    }

    // 加速特效
    if (hasSpeedBoost) {
      final boostPaint = Paint()
        ..color = const Color(0xFFFFFF00).withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        35,
        boostPaint,
      );
    }

    // 繪製引擎火焰
    final flameLength = 15 + 8 * sin(_engineFlicker * 10);
    final flameColor = hasSpeedBoost ? const Color(0xFF00FFFF) : const Color(0xFFFF6B00);

    final glowPath = Path()
      ..moveTo(size.x * 0.3, size.y - 8)
      ..lineTo(size.x / 2, size.y + flameLength * (hasSpeedBoost ? 1.5 : 1.0))
      ..lineTo(size.x * 0.7, size.y - 8)
      ..close();

    final outerGlow = Paint()
      ..color = flameColor.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(glowPath, outerGlow);

    _glowPaint.color = flameColor;
    canvas.drawPath(glowPath, _glowPaint);

    final corePath = Path()
      ..moveTo(size.x * 0.4, size.y - 5)
      ..lineTo(size.x / 2, size.y + flameLength * 0.6)
      ..lineTo(size.x * 0.6, size.y - 5)
      ..close();
    final corePaint = Paint()..color = const Color(0xFFFFFF00);
    canvas.drawPath(corePath, corePaint);

    // 繪製太空船主體
    final shipColor = _getShipColorByWeaponLevel();
    _shipPaint.color = shipColor;
    _shipOutline.color = shipColor.withOpacity(0.8);

    final shipPath = Path()
      ..moveTo(size.x / 2, 0)
      ..lineTo(size.x * 0.1, size.y - 15)
      ..lineTo(size.x * 0.25, size.y - 10)
      ..lineTo(size.x / 2, size.y - 20)
      ..lineTo(size.x * 0.75, size.y - 10)
      ..lineTo(size.x * 0.9, size.y - 15)
      ..close();

    final shipGlow = Paint()
      ..color = shipColor.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(shipPath, shipGlow);
    canvas.drawPath(shipPath, _shipPaint);
    canvas.drawPath(shipPath, _shipOutline);

    // 駕駛艙
    final cockpitGradient = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [shipColor, shipColor.withOpacity(0.5)],
      ).createShader(Rect.fromCenter(
        center: Offset(size.x / 2, size.y / 3),
        width: 14,
        height: 18,
      ));

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x / 2, size.y / 3),
        width: 14,
        height: 18,
      ),
      cockpitGradient,
    );

    // 武器等級指示燈
    _drawWeaponIndicators(canvas);
  }

  Color _getShipColorByWeaponLevel() {
    switch (weaponLevel) {
      case 1:
        return const Color(0xFF00D4FF);  // 藍色
      case 2:
        return const Color(0xFF00FF88);  // 綠色
      case 3:
        return const Color(0xFFFFAA00);  // 橙色
      case 4:
        return const Color(0xFFFF00FF);  // 紫色（滿級）
      default:
        return const Color(0xFF00D4FF);
    }
  }

  void _drawWeaponIndicators(Canvas canvas) {
    final indicatorPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 4; i++) {
      indicatorPaint.color = i < weaponLevel
          ? _getShipColorByWeaponLevel()
          : Colors.grey.withOpacity(0.3);

      canvas.drawCircle(
        Offset(size.x * 0.2 + i * 8, size.y - 5),
        2,
        indicatorPaint,
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    _engineFlicker += dt * 15;
    _shieldPulse += dt * 3;

    // 更新 Buff 計時器
    _updateBuffTimers(dt);

    // 更新無敵計時器
    if (isInvincible) {
      _invincibleTimer -= dt;
      if (_invincibleTimer <= 0) {
        isInvincible = false;
      }
    }

    // 移動
    velocity.x = horizontalDirection * speed;
    velocity.y = verticalDirection * speed;
    position += velocity * dt;

    // 螢幕邊界
    position.x = position.x.clamp(size.x / 2, game.size.x - size.x / 2);
    position.y = position.y.clamp(size.y / 2, game.size.y - size.y / 2);

    // 射擊
    if (shootCooldown > 0) {
      shootCooldown -= dt;
    }

    if (isShooting && shootCooldown <= 0) {
      shoot();
      shootCooldown = shootInterval;
    }
  }

  void _updateBuffTimers(double dt) {
    // 護盾計時
    if (hasShield) {
      _shieldTimer -= dt;
      if (_shieldTimer <= 0) {
        hasShield = false;
      }
    }

    // 加速計時
    if (hasSpeedBoost) {
      _speedBoostTimer -= dt;
      if (_speedBoostTimer <= 0) {
        hasSpeedBoost = false;
      }
    }

    // 快速射擊計時
    if (hasRapidFire) {
      _rapidFireTimer -= dt;
      if (_rapidFireTimer <= 0) {
        hasRapidFire = false;
      }
    }
  }

  void shoot() {
    final bulletPos = position - Vector2(0, size.y / 2);

    switch (weaponType) {
      case WeaponType.standard:
        _shootStandard(bulletPos);
        break;
      case WeaponType.spread:
        _shootSpread(bulletPos);
        break;
      case WeaponType.laser:
        _shootLaser(bulletPos);
        break;
      case WeaponType.missile:
        _shootMissile(bulletPos);
        break;
      case WeaponType.plasma:
        _shootPlasma(bulletPos);
        break;
    }
  }

  void _shootStandard(Vector2 bulletPos) {
    switch (weaponLevel) {
      case 1:
        _spawnBullet(bulletPos, 0, bullet_component.BulletType.standard);
        break;
      case 2:
        _spawnBullet(bulletPos - Vector2(8, 0), 0, bullet_component.BulletType.standard);
        _spawnBullet(bulletPos + Vector2(8, 0), 0, bullet_component.BulletType.standard);
        break;
      case 3:
        _spawnBullet(bulletPos, 0, bullet_component.BulletType.standard);
        _spawnBullet(bulletPos - Vector2(10, 0), -0.15, bullet_component.BulletType.standard);
        _spawnBullet(bulletPos + Vector2(10, 0), 0.15, bullet_component.BulletType.standard);
        break;
      case 4:
        _spawnBullet(bulletPos, 0, bullet_component.BulletType.standard);
        _spawnBullet(bulletPos - Vector2(8, 0), -0.1, bullet_component.BulletType.standard);
        _spawnBullet(bulletPos + Vector2(8, 0), 0.1, bullet_component.BulletType.standard);
        _spawnBullet(bulletPos - Vector2(15, 5), -0.25, bullet_component.BulletType.standard);
        _spawnBullet(bulletPos + Vector2(15, 5), 0.25, bullet_component.BulletType.standard);
        break;
    }
  }

  void _shootSpread(Vector2 bulletPos) {
    // 散射武器 - 更多子彈，更寬角度
    final count = 3 + weaponLevel * 2;
    final angleSpread = 0.15 + weaponLevel * 0.05;

    for (int i = 0; i < count; i++) {
      final angleOffset = (i - (count - 1) / 2) * angleSpread;
      _spawnBullet(bulletPos, angleOffset, bullet_component.BulletType.spread);
    }
  }

  void _shootLaser(Vector2 bulletPos) {
    // 雷射武器 - 穿透性子彈
    switch (weaponLevel) {
      case 1:
        _spawnBullet(bulletPos, 0, bullet_component.BulletType.laser);
        break;
      case 2:
        _spawnBullet(bulletPos - Vector2(6, 0), 0, bullet_component.BulletType.laser);
        _spawnBullet(bulletPos + Vector2(6, 0), 0, bullet_component.BulletType.laser);
        break;
      case 3:
        _spawnBullet(bulletPos, 0, bullet_component.BulletType.laser);
        _spawnBullet(bulletPos - Vector2(12, 0), 0, bullet_component.BulletType.laser);
        _spawnBullet(bulletPos + Vector2(12, 0), 0, bullet_component.BulletType.laser);
        break;
      case 4:
        // 滿級：中央粗雷射 + 兩側
        _spawnBullet(bulletPos, 0, bullet_component.BulletType.laserWide);
        _spawnBullet(bulletPos - Vector2(18, 0), 0, bullet_component.BulletType.laser);
        _spawnBullet(bulletPos + Vector2(18, 0), 0, bullet_component.BulletType.laser);
        break;
    }
  }

  void _shootMissile(Vector2 bulletPos) {
    // 飛彈武器 - 追蹤型
    final missileCount = weaponLevel;
    final spacing = 15.0;

    for (int i = 0; i < missileCount; i++) {
      final offset = (i - (missileCount - 1) / 2) * spacing;
      _spawnBullet(
        bulletPos + Vector2(offset, 0),
        0,
        bullet_component.BulletType.missile,
      );
    }
  }

  void _shootPlasma(Vector2 bulletPos) {
    // 電漿武器 - 高傷害但數量少
    switch (weaponLevel) {
      case 1:
        _spawnBullet(bulletPos, 0, bullet_component.BulletType.plasma);
        break;
      case 2:
        _spawnBullet(bulletPos, 0, bullet_component.BulletType.plasma);
        _spawnBullet(bulletPos, 0.08, bullet_component.BulletType.plasmaSmall);
        _spawnBullet(bulletPos, -0.08, bullet_component.BulletType.plasmaSmall);
        break;
      case 3:
        _spawnBullet(bulletPos, 0, bullet_component.BulletType.plasmaLarge);
        break;
      case 4:
        _spawnBullet(bulletPos, 0, bullet_component.BulletType.plasmaLarge);
        _spawnBullet(bulletPos - Vector2(15, 5), -0.1, bullet_component.BulletType.plasma);
        _spawnBullet(bulletPos + Vector2(15, 5), 0.1, bullet_component.BulletType.plasma);
        break;
    }
  }

  void _spawnBullet(Vector2 pos, double angleOffset, bullet_component.BulletType bulletType) {
    game.world.add(
      bullet_component.Bullet(
        position: pos.clone(),
        angle: angleOffset,
        isPlayerBullet: true,
        bulletType: bulletType,
      ),
    );
  }

  // === 道具效果方法 ===

  void upgradeWeapon() {
    if (weaponLevel < 4) {
      weaponLevel++;
      debugPrint('Weapon upgraded to level $weaponLevel');
    }
  }

  void changeWeapon(WeaponType newType) {
    weaponType = newType;
    // 換武器時等級重置為 2（比 1 強，但不是滿級）
    if (weaponLevel < 2) weaponLevel = 2;
    debugPrint('Weapon changed to ${newType.name}');
  }

  void activateShield() {
    hasShield = true;
    _shieldTimer = shieldDuration;
    debugPrint('Shield activated for ${shieldDuration}s');
  }

  void activateSpeedBoost() {
    hasSpeedBoost = true;
    _speedBoostTimer = speedBoostDuration;
    debugPrint('Speed boost activated for ${speedBoostDuration}s');
  }

  void activateRapidFire() {
    hasRapidFire = true;
    _rapidFireTimer = rapidFireDuration;
    debugPrint('Rapid fire activated for ${rapidFireDuration}s');
  }

  void addLife() {
    lives++;
    debugPrint('Extra life! Lives: $lives');
  }

  void takeDamage() {
    if (isInvincible) return;

    if (hasShield) {
      hasShield = false;
      _shieldTimer = 0;
      isInvincible = true;
      _invincibleTimer = 1.0;  // 短暫無敵
      debugPrint('Shield absorbed damage!');
      return;
    }

    lives--;
    debugPrint('Hit! Lives remaining: $lives');

    if (lives <= 0) {
      game.gameOver();
    } else {
      // 受傷後無敵時間
      isInvincible = true;
      _invincibleTimer = invincibleDuration;
      // 降級武器
      if (weaponLevel > 1) {
        weaponLevel--;
      }
    }
  }

  // 重置玩家狀態（新遊戲時）
  void reset() {
    weaponLevel = 1;
    weaponType = WeaponType.standard;
    lives = 3;
    hasShield = false;
    hasSpeedBoost = false;
    hasRapidFire = false;
    isInvincible = false;
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      if (game.overlays.isActive('PauseMenu')) {
        game.resumeGame();
      } else {
        game.pauseGame();
      }
      return true;
    }

    horizontalDirection = 0;
    verticalDirection = 0;

    if (keysPressed.contains(LogicalKeyboardKey.arrowLeft) ||
        keysPressed.contains(LogicalKeyboardKey.keyA)) {
      horizontalDirection = -1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
        keysPressed.contains(LogicalKeyboardKey.keyD)) {
      horizontalDirection = 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.arrowUp) ||
        keysPressed.contains(LogicalKeyboardKey.keyW)) {
      verticalDirection = -1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.arrowDown) ||
        keysPressed.contains(LogicalKeyboardKey.keyS)) {
      verticalDirection = 1;
    }

    isShooting = keysPressed.contains(LogicalKeyboardKey.space);

    return true;
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is enemy_component.Enemy) {
      takeDamage();
    } else if (other is enemy_component.Boss) {
      takeDamage();
    } else if (other is bullet_component.Bullet && !other.isPlayerBullet) {
      // 被敵人子彈擊中
      other.removeFromParent();
      takeDamage();
    }
  }
}
