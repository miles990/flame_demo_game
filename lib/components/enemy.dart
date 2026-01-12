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
  tracker,    // 追蹤敵人 - 追蹤玩家位置
  diver,      // 俯衝敵人 - 俯衝攻擊後撤退
  orbiter,    // 環繞敵人 - 環繞移動並射擊
}

/// 敵人進入方向
enum SpawnDirection {
  top,        // 從上方進入（預設）
  left,       // 從左側進入
  right,      // 從右側進入
  topLeft,    // 從左上角進入
  topRight,   // 從右上角進入
}

class Enemy extends PositionComponent
    with HasGameReference<SpaceGame>, CollisionCallbacks {

  final EnemyType type;
  final SpawnDirection spawnDirection;
  int health;

  Enemy({
    required super.position,
    this.type = EnemyType.basic,
    this.spawnDirection = SpawnDirection.top,
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
      case EnemyType.tracker: return 2;
      case EnemyType.diver: return 1;
      case EnemyType.orbiter: return 2;
    }
  }

  static Vector2 _getSizeByType(EnemyType type) {
    switch (type) {
      case EnemyType.basic: return Vector2(40, 40);
      case EnemyType.fast: return Vector2(30, 35);
      case EnemyType.tank: return Vector2(55, 55);
      case EnemyType.shooter: return Vector2(45, 45);
      case EnemyType.zigzag: return Vector2(35, 35);
      case EnemyType.tracker: return Vector2(38, 38);
      case EnemyType.diver: return Vector2(35, 40);
      case EnemyType.orbiter: return Vector2(32, 32);
    }
  }

  late double speed;
  late double amplitude;
  late double frequency;
  double time = 0;
  double startX = 0;
  double startY = 0;
  double shootCooldown = 0;
  int zigzagDirection = 1;

  // 新增行為模式變數
  bool _isDiving = false;
  double _diveTargetY = 0;
  double _orbitAngle = 0;
  double _orbitCenterX = 0;
  double _orbitCenterY = 0;
  Vector2 _moveDirection = Vector2(0, 1);

  @override
  Future<void> onLoad() async {
    final random = Random();

    // 根據進入方向設定初始移動方向
    _moveDirection = _getDirectionFromSpawn();

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
      case EnemyType.tracker:
        speed = 90 + random.nextDouble() * 40;
        amplitude = 0;
        frequency = 0;
        break;
      case EnemyType.diver:
        speed = 150 + random.nextDouble() * 50;
        amplitude = 0;
        frequency = 0;
        _diveTargetY = game.size.y * 0.6;
        break;
      case EnemyType.orbiter:
        speed = 60;
        amplitude = 0;
        frequency = 3;
        shootCooldown = 1.5;
        _orbitAngle = random.nextDouble() * pi * 2;
        break;
    }

    startX = position.x;
    startY = position.y;
    add(CircleHitbox());
  }

  Vector2 _getDirectionFromSpawn() {
    switch (spawnDirection) {
      case SpawnDirection.top:
        return Vector2(0, 1);
      case SpawnDirection.left:
        return Vector2(1, 0.5);
      case SpawnDirection.right:
        return Vector2(-1, 0.5);
      case SpawnDirection.topLeft:
        return Vector2(0.7, 0.7).normalized();
      case SpawnDirection.topRight:
        return Vector2(-0.7, 0.7).normalized();
    }
  }

  Color get _color {
    switch (type) {
      case EnemyType.basic: return const Color(0xFFCC2222);
      case EnemyType.fast: return const Color(0xFFFF8800);
      case EnemyType.tank: return const Color(0xFF666688);
      case EnemyType.shooter: return const Color(0xFF8822CC);
      case EnemyType.zigzag: return const Color(0xFF22CCCC);
      case EnemyType.tracker: return const Color(0xFFFF4488);
      case EnemyType.diver: return const Color(0xFFFFCC00);
      case EnemyType.orbiter: return const Color(0xFF44FFAA);
    }
  }

  @override
  void render(Canvas canvas) {
    // 動態脈動效果
    final pulse = 1.0 + sin(time * 4) * 0.05;

    // 外層光暈 - 根據敵人類型有不同效果
    final glowIntensity = _getGlowIntensity();
    final glowPaint = Paint()
      ..color = _color.withOpacity(0.3 * glowIntensity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * pulse);

    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      (size.x / 2 + 5) * pulse,
      glowPaint,
    );

    // 特殊效果層（某些敵人類型）
    _drawSpecialEffects(canvas);

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
      case EnemyType.tracker:
        _drawTracker(canvas);
        break;
      case EnemyType.diver:
        _drawDiver(canvas);
        break;
      case EnemyType.orbiter:
        _drawOrbiter(canvas);
        break;
    }

    // 血量指示（坦克和射手和追蹤者）
    if (type == EnemyType.tank || type == EnemyType.shooter ||
        type == EnemyType.tracker || type == EnemyType.orbiter) {
      _drawHealthBar(canvas);
    }

    // 方向指示器（從側面進入的敵人）
    if (spawnDirection != SpawnDirection.top) {
      _drawDirectionIndicator(canvas);
    }
  }

  double _getGlowIntensity() {
    switch (type) {
      case EnemyType.basic: return 1.0;
      case EnemyType.fast: return 1.3;  // 快速敵人更亮
      case EnemyType.tank: return 0.8;  // 坦克較暗
      case EnemyType.shooter: return 1.2;
      case EnemyType.zigzag: return 1.1;
      case EnemyType.tracker: return 1.4;  // 追蹤者閃爍
      case EnemyType.diver: return _isDiving ? 1.8 : 1.0;  // 俯衝時更亮
      case EnemyType.orbiter: return 1.0 + sin(time * 3).abs() * 0.5;  // 脈動
    }
  }

  void _drawSpecialEffects(Canvas canvas) {
    switch (type) {
      case EnemyType.fast:
        // 速度線效果
        _drawSpeedLines(canvas);
        break;
      case EnemyType.shooter:
        // 瞄準線效果
        if (shootCooldown < 0.5) {
          _drawAimLine(canvas);
        }
        break;
      case EnemyType.zigzag:
        // Z 字軌跡殘影
        _drawZigzagTrail(canvas);
        break;
      default:
        break;
    }
  }

  void _drawSpeedLines(Canvas canvas) {
    final linePaint = Paint()
      ..color = _color.withOpacity(0.4)
      ..strokeWidth = 2;

    for (int i = 0; i < 3; i++) {
      final offset = i * 8.0;
      canvas.drawLine(
        Offset(size.x * 0.3, size.y + offset),
        Offset(size.x * 0.3, size.y + offset + 15),
        linePaint,
      );
      canvas.drawLine(
        Offset(size.x * 0.7, size.y + offset),
        Offset(size.x * 0.7, size.y + offset + 15),
        linePaint,
      );
    }
  }

  void _drawAimLine(Canvas canvas) {
    final aimPaint = Paint()
      ..color = const Color(0xFFFF0000).withOpacity(0.5)
      ..strokeWidth = 1;

    final blinkOpacity = (sin(time * 20) + 1) / 2;
    aimPaint.color = const Color(0xFFFF0000).withOpacity(0.3 * blinkOpacity);

    canvas.drawLine(
      Offset(size.x / 2, size.y),
      Offset(size.x / 2, size.y + 100),
      aimPaint,
    );
  }

  void _drawZigzagTrail(Canvas canvas) {
    final trailPaint = Paint()
      ..color = _color.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    // 殘影效果
    for (int i = 1; i <= 3; i++) {
      final offset = zigzagDirection * i * 10.0;
      canvas.drawCircle(
        Offset(size.x / 2 - offset, size.y / 2 + i * 8),
        (size.x / 4) / i,
        trailPaint,
      );
    }
  }

  void _drawDirectionIndicator(Canvas canvas) {
    // 繪製進入方向的小箭頭
    final arrowPaint = Paint()
      ..color = _color.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);

    // 根據方向旋轉
    final rotationAngle = switch (spawnDirection) {
      SpawnDirection.top => 0.0,
      SpawnDirection.left => -pi / 4,
      SpawnDirection.right => pi / 4,
      SpawnDirection.topLeft => -pi / 6,
      SpawnDirection.topRight => pi / 6,
    };
    canvas.rotate(rotationAngle);

    // 小箭頭
    final arrowPath = Path()
      ..moveTo(0, -size.y / 2 - 8)
      ..lineTo(-4, -size.y / 2 - 2)
      ..lineTo(4, -size.y / 2 - 2)
      ..close();

    canvas.drawPath(arrowPath, arrowPaint);
    canvas.restore();
  }

  void _drawTracker(Canvas canvas) {
    final paint = Paint()
      ..color = _color
      ..style = PaintingStyle.fill;

    // 追蹤者外觀 - 眼睛形狀
    final path = Path()
      ..moveTo(size.x / 2, 0)
      ..quadraticBezierTo(size.x, size.y / 2, size.x / 2, size.y)
      ..quadraticBezierTo(0, size.y / 2, size.x / 2, 0)
      ..close();

    canvas.drawPath(path, paint);
    _drawOutlineAndEye(canvas, path);

    // 追蹤雷達效果
    final radarPaint = Paint()
      ..color = _color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2 + sin(time * 5) * 5,
      radarPaint,
    );
  }

  void _drawDiver(Canvas canvas) {
    final paint = Paint()
      ..color = _color
      ..style = PaintingStyle.fill;

    // 俯衝者外觀 - 尖銳的向下箭頭
    final path = Path()
      ..moveTo(size.x / 2, 0)
      ..lineTo(size.x * 0.8, size.y * 0.3)
      ..lineTo(size.x * 0.65, size.y * 0.3)
      ..lineTo(size.x * 0.65, size.y * 0.7)
      ..lineTo(size.x, size.y)
      ..lineTo(size.x / 2, size.y * 0.8)
      ..lineTo(0, size.y)
      ..lineTo(size.x * 0.35, size.y * 0.7)
      ..lineTo(size.x * 0.35, size.y * 0.3)
      ..lineTo(size.x * 0.2, size.y * 0.3)
      ..close();

    canvas.drawPath(path, paint);
    _drawOutlineAndEye(canvas, path);

    // 俯衝時的火焰效果
    if (_isDiving) {
      final flamePaint = Paint()
        ..color = const Color(0xFFFF4400).withOpacity(0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(
        Offset(size.x / 2, 0),
        8 + sin(time * 20) * 3,
        flamePaint,
      );
    }
  }

  void _drawOrbiter(Canvas canvas) {
    final paint = Paint()
      ..color = _color
      ..style = PaintingStyle.fill;

    // 環繞者外觀 - 旋轉的圓環
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(_orbitAngle);

    // 外環
    final ringPaint = Paint()
      ..color = _color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(Offset.zero, size.x / 2 - 2, ringPaint);

    // 核心
    canvas.drawCircle(Offset.zero, size.x / 4, paint);

    // 軌道上的小球
    for (int i = 0; i < 3; i++) {
      final angle = (i / 3) * pi * 2;
      final orbX = cos(angle) * (size.x / 2 - 5);
      final orbY = sin(angle) * (size.y / 2 - 5);
      canvas.drawCircle(Offset(orbX, orbY), 4, paint);
    }

    canvas.restore();
    _drawEye(canvas);
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
        _updateBasic(dt);
        break;

      case EnemyType.fast:
        _updateFast(dt);
        break;

      case EnemyType.tank:
        _updateTank(dt);
        break;

      case EnemyType.shooter:
        _updateShooter(dt);
        break;

      case EnemyType.zigzag:
        _updateZigzag(dt);
        break;

      case EnemyType.tracker:
        _updateTracker(dt);
        break;

      case EnemyType.diver:
        _updateDiver(dt);
        break;

      case EnemyType.orbiter:
        _updateOrbiter(dt);
        break;
    }

    // Remove if off screen (考慮不同方向進入)
    if (position.y > game.size.y + 100 ||
        position.y < -150 ||
        position.x < -100 ||
        position.x > game.size.x + 100) {
      removeFromParent();
    }
  }

  void _updateBasic(double dt) {
    position += _moveDirection * speed * dt;
    position.x = startX + sin(time * frequency) * amplitude * _moveDirection.y.abs();
  }

  void _updateFast(double dt) {
    position += _moveDirection * speed * dt;
  }

  void _updateTank(double dt) {
    position += _moveDirection * speed * dt;
    position.x = startX + sin(time * frequency) * amplitude * _moveDirection.y.abs();
  }

  void _updateShooter(double dt) {
    position += _moveDirection * speed * dt;
    position.x = startX + sin(time * frequency) * amplitude * _moveDirection.y.abs();
    _handleShooting(dt);
  }

  void _updateZigzag(double dt) {
    position.y += speed * dt * _moveDirection.y.abs();
    position.x += zigzagDirection * 200 * dt;
    if (position.x < 50 || position.x > game.size.x - 50) {
      zigzagDirection *= -1;
    }
  }

  void _updateTracker(double dt) {
    // 追蹤玩家位置
    final playerPos = game.player.position;
    final direction = (playerPos - position).normalized();

    // 緩慢轉向玩家
    _moveDirection = (_moveDirection + direction * 0.02).normalized();
    position += _moveDirection * speed * dt;
  }

  void _updateDiver(double dt) {
    if (!_isDiving) {
      // 先水平移動進入螢幕
      position += _moveDirection * speed * 0.5 * dt;

      // 當到達一定位置時開始俯衝
      if (position.y > 50 && position.y < 150) {
        _isDiving = true;
        // 瞄準玩家位置
        final playerPos = game.player.position;
        _moveDirection = (playerPos - position).normalized();
      }
    } else {
      // 俯衝階段 - 高速衝向目標
      position += _moveDirection * speed * 2 * dt;

      // 俯衝到一定深度後撤退
      if (position.y > _diveTargetY) {
        _isDiving = false;
        _moveDirection = Vector2(
          _moveDirection.x,
          -0.8,  // 向上撤退
        ).normalized();
        speed *= 0.8;  // 撤退時減速
      }
    }
  }

  void _updateOrbiter(double dt) {
    // 先進入螢幕
    if (time < 1.5) {
      position += _moveDirection * speed * dt;
      _orbitCenterX = position.x;
      _orbitCenterY = position.y + 50;
    } else {
      // 環繞移動
      _orbitAngle += frequency * dt;
      final radius = 80.0;
      position.x = _orbitCenterX + cos(_orbitAngle) * radius;
      position.y = _orbitCenterY + sin(_orbitAngle) * radius * 0.5;

      // 緩慢向下移動軌道中心
      _orbitCenterY += 20 * dt;
    }

    _handleShooting(dt);
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

  void takeDamage([int damage = 1]) {
    health -= damage;
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
      EnemyType.tracker => 200,
      EnemyType.diver => 180,
      EnemyType.orbiter => 220,
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
      final damage = other.getDamage();
      if (!other.isPiercing) {
        other.removeFromParent();
      }
      takeDamage(damage);
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

  // Boss 攻擊階段（血量越低，攻擊越猛烈）
  int get attackPhase {
    final healthPercent = health / maxHealth;
    if (healthPercent > 0.7) return 1;
    if (healthPercent > 0.4) return 2;
    return 3;  // 狂暴階段
  }

  // 憤怒模式（血量低於 30%）
  bool get isEnraged => health / maxHealth < 0.3;

  @override
  Future<void> onLoad() async {
    // 根據 Boss 類型調整血量 - 大幅提升
    maxHealth = switch (bossType) {
      BossType.destroyer => 35 + stage * 18,
      BossType.carrier => 45 + stage * 20,
      BossType.fortress => 70 + stage * 25,
      BossType.phantom => 25 + stage * 12,
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
    // 移動速度根據階段增加
    final moveSpeed = 0.5 + attackPhase * 0.2;
    position.x = game.size.x / 2 + sin(time * moveSpeed) * 200;

    // 憤怒模式時上下移動
    if (isEnraged) {
      position.y = targetY + sin(time * 2) * 30;
    }

    shootCooldown -= dt;
    // 攻擊間隔根據階段減少
    final cooldownTime = 1.5 - (attackPhase - 1) * 0.3;
    if (shootCooldown <= 0) {
      _executeDestroyerAttack();
      attackPattern = (attackPattern + 1) % (isEnraged ? 5 : 3);
      shootCooldown = cooldownTime;
    }
  }

  void _updateCarrier(double dt) {
    final moveSpeed = 0.3 + attackPhase * 0.1;
    position.x = game.size.x / 2 + sin(time * moveSpeed) * 150;

    // 生成小怪 - 頻率隨階段增加
    _spawnCooldown -= dt;
    final spawnInterval = 4.0 - attackPhase * 0.8;
    if (_spawnCooldown <= 0) {
      _spawnMinions();
      _spawnCooldown = spawnInterval;
    }

    // 射擊頻率隨階段增加
    shootCooldown -= dt;
    final shootInterval = 2.5 - attackPhase * 0.5;
    if (shootCooldown <= 0) {
      _executeCarrierAttack();
      shootCooldown = shootInterval;
    }
  }

  void _updateFortress(double dt) {
    // 堡壘移動緩慢，但狂暴時加速
    final moveSpeed = isEnraged ? 0.4 : 0.2;
    position.x = game.size.x / 2 + sin(time * moveSpeed) * 100;

    // 狂暴時輕微旋轉
    if (isEnraged) {
      angle = sin(time * 2) * 0.1;
    }

    shootCooldown -= dt;
    final cooldown = 1.2 - attackPhase * 0.2;
    if (shootCooldown <= 0) {
      _executeFortressAttack();
      attackPattern = (attackPattern + 1) % (isEnraged ? 4 : 2);
      shootCooldown = cooldown;
    }
  }

  void _updatePhantom(double dt) {
    // 瞬移邏輯 - 頻率隨階段增加
    _teleportCooldown -= dt;
    final teleportInterval = 3.0 - attackPhase * 0.5;
    if (_teleportCooldown <= 0) {
      _teleport();
      _teleportCooldown = teleportInterval;
    }

    // 透明度波動 - 狂暴時更快閃爍
    final flickerSpeed = isEnraged ? 5.0 : 2.0;
    _opacity = 0.4 + 0.6 * sin(time * flickerSpeed).abs();

    // 快速射擊 - 攻擊間隔根據階段減少
    shootCooldown -= dt;
    final shootInterval = 0.8 - attackPhase * 0.15;
    if (shootCooldown <= 0) {
      _executePhantomAttack();
      shootCooldown = shootInterval;
    }
  }

  void _teleport() {
    final random = Random();
    final newX = 100.0 + random.nextDouble() * (game.size.x - 200);
    position.x = newX;
  }

  void _spawnMinions() {
    final random = Random();
    final minionCount = 3 + attackPhase;

    for (int i = 0; i < minionCount; i++) {
      final offset = (i - (minionCount - 1) / 2) * 50.0;

      // 根據階段生成不同類型的小怪
      EnemyType minionType;
      if (attackPhase == 1) {
        minionType = random.nextBool() ? EnemyType.fast : EnemyType.basic;
      } else if (attackPhase == 2) {
        final roll = random.nextDouble();
        if (roll < 0.4) minionType = EnemyType.fast;
        else if (roll < 0.7) minionType = EnemyType.zigzag;
        else minionType = EnemyType.shooter;
      } else {
        // 狂暴階段生成更強的小怪
        final roll = random.nextDouble();
        if (roll < 0.3) minionType = EnemyType.tracker;
        else if (roll < 0.6) minionType = EnemyType.diver;
        else minionType = EnemyType.shooter;
      }

      game.world.add(Enemy(
        position: position + Vector2(offset, size.y / 2 + 20),
        type: minionType,
      ));
    }
  }

  // 根據攻擊階段計算子彈速度倍率（初期慢，後期快）
  double get _bulletSpeedMultiplier {
    switch (attackPhase) {
      case 1: return 0.7;   // 階段1：較慢
      case 2: return 0.9;   // 階段2：中等
      case 3: return 1.1;   // 階段3：較快
      default: return 0.7;
    }
  }

  void _executeDestroyerAttack() {
    final bulletCount = 5 + attackPhase * 2;
    final speedMult = _bulletSpeedMultiplier;

    switch (attackPattern) {
      case 0:
        // 散射 - 根據階段增加子彈數
        for (int i = -(bulletCount ~/ 2); i <= bulletCount ~/ 2; i++) {
          game.world.add(
            bullet_component.Bullet(
              position: position + Vector2(0, size.y / 2),
              angle: i * 0.15,
              isPlayerBullet: false,
              speedMultiplier: speedMult,
            ),
          );
        }
        break;
      case 1:
        // 三連發 + 階段加強
        final count = 3 + attackPhase;
        for (int i = 0; i < count; i++) {
          final offset = (i - (count - 1) / 2) * 35.0;
          game.world.add(
            bullet_component.Bullet(
              position: position + Vector2(offset, size.y / 2),
              angle: 0,
              isPlayerBullet: false,
              speedMultiplier: speedMult,
            ),
          );
        }
        break;
      case 2:
        // 環形攻擊 - 子彈數量隨階段增加
        final ringCount = 8 + attackPhase * 4;
        for (int i = 0; i < ringCount; i++) {
          final angle = (i / ringCount) * pi * 2;
          game.world.add(
            bullet_component.Bullet(
              position: position + Vector2(0, size.y / 2),
              angle: angle - pi / 2,
              isPlayerBullet: false,
              speedMultiplier: speedMult,
            ),
          );
        }
        break;
      case 3:
        // 新增：正弦波彈幕（曲線移動）
        _executeSineWave(8 + attackPhase * 2);
        break;
      case 4:
        // 新增：螺旋曲線彈幕
        _executeSpiralCurve(6 + attackPhase);
        break;
    }
  }

  /// 正弦波彈幕 - 曲線移動
  void _executeSineWave(int count) {
    for (int i = 0; i < count; i++) {
      final delay = i * 80;
      Future.delayed(Duration(milliseconds: delay), () {
        if (isMounted) {
          final xOffset = (i - count / 2) * 25.0;
          game.world.add(
            bullet_component.Bullet(
              position: position + Vector2(xOffset, size.y / 2),
              angle: 0,
              isPlayerBullet: false,
              bulletType: bullet_component.BulletType.enemySine,
              speedMultiplier: _bulletSpeedMultiplier,
            ),
          );
        }
      });
    }
  }

  /// 螺旋曲線彈幕
  void _executeSpiralCurve(int count) {
    for (int i = 0; i < count; i++) {
      final delay = i * 100;
      Future.delayed(Duration(milliseconds: delay), () {
        if (isMounted) {
          final angle = (i / count) * pi * 2;
          game.world.add(
            bullet_component.Bullet(
              position: position + Vector2(cos(angle) * 20, size.y / 2 + sin(angle) * 10),
              angle: angle * 0.3,
              isPlayerBullet: false,
              bulletType: bullet_component.BulletType.enemySpiral,
              speedMultiplier: _bulletSpeedMultiplier,
            ),
          );
        }
      });
    }
  }

  void _executeSpiral(int count, double angleOffset) {
    final speedMult = _bulletSpeedMultiplier;
    for (int i = 0; i < count; i++) {
      final delay = i * 60;  // 稍微調慢間隔
      Future.delayed(Duration(milliseconds: delay), () {
        if (isMounted) {
          final angle = (time * 3 + i * angleOffset) % (pi * 2);
          game.world.add(
            bullet_component.Bullet(
              position: position.clone(),
              angle: angle - pi / 2,
              isPlayerBullet: false,
              speedMultiplier: speedMult,
            ),
          );
        }
      });
    }
  }

  void _executeHomingBurst() {
    final playerPos = game.player.position;
    final direction = (playerPos - position).normalized();
    final baseAngle = atan2(direction.x, -direction.y);
    final speedMult = _bulletSpeedMultiplier;

    // 改用追蹤彈幕類型
    for (int i = -2; i <= 2; i++) {
      game.world.add(
        bullet_component.Bullet(
          position: position + Vector2(0, size.y / 2),
          angle: baseAngle + i * 0.12,
          isPlayerBullet: false,
          bulletType: bullet_component.BulletType.enemyHoming,
          speedMultiplier: speedMult,
        ),
      );
    }
  }

  void _executeCarrierAttack() {
    final count = 3 + attackPhase * 2;
    final speedMult = _bulletSpeedMultiplier;

    switch (attackPattern % 4) {
      case 0:
        // 寬範圍攻擊
        for (int i = -count; i <= count; i++) {
          game.world.add(
            bullet_component.Bullet(
              position: position + Vector2(i * 22.0, size.y / 2),
              angle: 0,
              isPlayerBullet: false,
              speedMultiplier: speedMult,
            ),
          );
        }
        break;
      case 1:
        // 正弦波彈幕（曲線移動）
        for (int i = 0; i < count * 2; i++) {
          final delay = i * 100;  // 調慢間隔
          Future.delayed(Duration(milliseconds: delay), () {
            if (isMounted) {
              final xOffset = sin(i * 0.5) * 60;
              game.world.add(
                bullet_component.Bullet(
                  position: position + Vector2(xOffset, size.y / 2),
                  angle: 0,
                  isPlayerBullet: false,
                  bulletType: bullet_component.BulletType.enemySine,
                  speedMultiplier: speedMult,
                ),
              );
            }
          });
        }
        break;
      case 2:
        // 扇形追蹤彈幕
        _executeHomingBurst();
        break;
      case 3:
        // 新增：螺旋曲線彈幕
        _executeSpiralCurve(count);
        break;
    }
    attackPattern++;
  }

  void _executeFortressAttack() {
    final ringCount = 12 + attackPhase * 4;
    final speedMult = _bulletSpeedMultiplier;

    switch (attackPattern) {
      case 0:
        // 環形彈幕 - 數量隨階段增加
        for (int i = 0; i < ringCount; i++) {
          final bulletAngle = (i / ringCount) * pi * 2 + time * 0.5;
          game.world.add(
            bullet_component.Bullet(
              position: position + Vector2(0, 0),
              angle: bulletAngle - pi / 2,
              isPlayerBullet: false,
              speedMultiplier: speedMult,
            ),
          );
        }
        break;
      case 1:
        // 十字攻擊 - 連發數隨階段增加（使用螺旋彈幕）
        final arms = 4 + (attackPhase > 2 ? 4 : 0);
        for (int i = 0; i < arms; i++) {
          final armAngle = (i / arms) * pi * 2;
          final burstCount = 3 + attackPhase;
          for (int j = 1; j <= burstCount; j++) {
            Future.delayed(Duration(milliseconds: j * 100), () {  // 調慢間隔
              if (isMounted) {
                game.world.add(
                  bullet_component.Bullet(
                    position: position.clone(),
                    angle: armAngle - pi / 2,
                    isPlayerBullet: false,
                    bulletType: bullet_component.BulletType.enemySpiral,
                    speedMultiplier: speedMult,
                  ),
                );
              }
            });
          }
        }
        break;
      case 2:
        // 雙向正弦波彈幕（曲線）
        for (int i = 0; i < 10; i++) {
          final delay = i * 80;
          Future.delayed(Duration(milliseconds: delay), () {
            if (isMounted) {
              // 左側
              game.world.add(
                bullet_component.Bullet(
                  position: position + Vector2(-40, size.y / 2),
                  angle: 0.3,
                  isPlayerBullet: false,
                  bulletType: bullet_component.BulletType.enemySine,
                  speedMultiplier: speedMult,
                ),
              );
              // 右側
              game.world.add(
                bullet_component.Bullet(
                  position: position + Vector2(40, size.y / 2),
                  angle: -0.3,
                  isPlayerBullet: false,
                  bulletType: bullet_component.BulletType.enemySine,
                  speedMultiplier: speedMult,
                ),
              );
            }
          });
        }
        break;
      case 3:
        // 追蹤彈幕 + 螺旋組合（狂暴階段）
        _executeHomingBurst();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (isMounted) _executeSpiralCurve(8);
        });
        break;
    }
  }

  void _executePhantomAttack() {
    // 幻影攻擊 - 追蹤玩家方向
    final playerPos = game.player.position;
    final direction = (playerPos - position).normalized();
    final baseAngle = atan2(direction.x, -direction.y);
    final speedMult = _bulletSpeedMultiplier;

    final count = 1 + attackPhase;

    switch (attackPattern % 4) {
      case 0:
        // 追蹤扇形（使用追蹤彈幕）
        for (int i = -count; i <= count; i++) {
          game.world.add(
            bullet_component.Bullet(
              position: position + Vector2(0, size.y / 2),
              angle: baseAngle + i * 0.12,
              isPlayerBullet: false,
              bulletType: bullet_component.BulletType.enemyHoming,
              speedMultiplier: speedMult,
            ),
          );
        }
        break;
      case 1:
        // 分裂攻擊 - 正弦波從多個位置
        for (int side = -1; side <= 1; side += 2) {
          game.world.add(
            bullet_component.Bullet(
              position: position + Vector2(side * 30.0, size.y / 2),
              angle: baseAngle + side * 0.2,
              isPlayerBullet: false,
              bulletType: bullet_component.BulletType.enemySine,
              speedMultiplier: speedMult,
            ),
          );
        }
        break;
      case 2:
        // 螺旋曲線攻擊
        for (int i = 0; i < 4; i++) {
          final delay = i * 80;
          Future.delayed(Duration(milliseconds: delay), () {
            if (isMounted) {
              game.world.add(
                bullet_component.Bullet(
                  position: position + Vector2(0, size.y / 2),
                  angle: baseAngle + (i - 1.5) * 0.15,
                  isPlayerBullet: false,
                  bulletType: bullet_component.BulletType.enemySpiral,
                  speedMultiplier: speedMult,
                ),
              );
            }
          });
        }
        break;
      case 3:
        // 狂暴連射（使用追蹤彈幕）
        if (isEnraged) {
          for (int burst = 0; burst < 4; burst++) {
            Future.delayed(Duration(milliseconds: burst * 120), () {
              if (isMounted) {
                final burstAngle = baseAngle + (burst - 1.5) * 0.08;
                game.world.add(
                  bullet_component.Bullet(
                    position: position + Vector2(0, size.y / 2),
                    angle: burstAngle,
                    isPlayerBullet: false,
                    bulletType: bullet_component.BulletType.enemyHoming,
                    speedMultiplier: speedMult * 1.2,  // 狂暴時稍快
                  ),
                );
              }
            });
          }
        } else {
          game.world.add(
            bullet_component.Bullet(
              position: position + Vector2(0, size.y / 2),
              angle: baseAngle,
              isPlayerBullet: false,
              speedMultiplier: speedMult,
            ),
          );
        }
        break;
    }
    attackPattern++;
  }

  void takeDamage([int damage = 1]) {
    health -= damage;
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
      final damage = other.getDamage();
      if (!other.isPiercing) {
        other.removeFromParent();
      }
      takeDamage(damage);
    }
  }
}

/// 敵人生成器配置
class EnemySpawnConfig {
  static final _random = Random();

  static EnemyType getRandomType(int wave) {
    final roll = _random.nextDouble();

    // 根據波數調整敵人出現機率
    if (wave < 3) {
      // 前期只有基本和快速敵人
      return roll < 0.7 ? EnemyType.basic : EnemyType.fast;
    } else if (wave < 6) {
      // 中期加入更多種類
      if (roll < 0.35) return EnemyType.basic;
      if (roll < 0.55) return EnemyType.fast;
      if (roll < 0.70) return EnemyType.zigzag;
      if (roll < 0.85) return EnemyType.shooter;
      return EnemyType.tracker;
    } else if (wave < 10) {
      // 中後期引入更多種類
      if (roll < 0.20) return EnemyType.basic;
      if (roll < 0.35) return EnemyType.fast;
      if (roll < 0.50) return EnemyType.zigzag;
      if (roll < 0.65) return EnemyType.shooter;
      if (roll < 0.80) return EnemyType.tracker;
      if (roll < 0.90) return EnemyType.diver;
      return EnemyType.orbiter;
    } else {
      // 後期全種類
      if (roll < 0.15) return EnemyType.basic;
      if (roll < 0.25) return EnemyType.fast;
      if (roll < 0.35) return EnemyType.zigzag;
      if (roll < 0.50) return EnemyType.shooter;
      if (roll < 0.65) return EnemyType.tracker;
      if (roll < 0.75) return EnemyType.diver;
      if (roll < 0.85) return EnemyType.orbiter;
      return EnemyType.tank;
    }
  }

  /// 根據波數獲取隨機生成方向
  static SpawnDirection getRandomDirection(int wave) {
    final roll = _random.nextDouble();

    if (wave < 4) {
      // 前期只從上方
      return SpawnDirection.top;
    } else if (wave < 7) {
      // 中期引入側面
      if (roll < 0.6) return SpawnDirection.top;
      if (roll < 0.8) return SpawnDirection.left;
      return SpawnDirection.right;
    } else {
      // 後期全方向
      if (roll < 0.4) return SpawnDirection.top;
      if (roll < 0.55) return SpawnDirection.left;
      if (roll < 0.70) return SpawnDirection.right;
      if (roll < 0.85) return SpawnDirection.topLeft;
      return SpawnDirection.topRight;
    }
  }

  /// 根據生成方向獲取初始位置
  static Vector2 getSpawnPosition(SpawnDirection direction, Vector2 gameSize) {
    switch (direction) {
      case SpawnDirection.top:
        return Vector2(
          _random.nextDouble() * (gameSize.x - 80) + 40,
          -60,
        );
      case SpawnDirection.left:
        return Vector2(
          -60,
          _random.nextDouble() * (gameSize.y * 0.4) + 50,
        );
      case SpawnDirection.right:
        return Vector2(
          gameSize.x + 60,
          _random.nextDouble() * (gameSize.y * 0.4) + 50,
        );
      case SpawnDirection.topLeft:
        return Vector2(
          -60,
          -60,
        );
      case SpawnDirection.topRight:
        return Vector2(
          gameSize.x + 60,
          -60,
        );
    }
  }
}
