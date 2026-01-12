import 'dart:math';

import 'package:flame/components.dart';

import '../game/space_game.dart';
import 'enemy.dart';
import 'power_up.dart';

/// 敵人編隊類型
enum FormationType {
  vShape,      // V 字形編隊
  line,        // 橫排編隊
  circle,      // 圓形編隊
  arrow,       // 箭頭編隊
  wave,        // 波浪編隊
}

/// 敵人編隊生成器
class EnemyFormation extends Component with HasGameReference<SpaceGame> {
  final FormationType type;
  final EnemyType enemyType;
  final int count;
  final Vector2 startPosition;
  final double spacing;
  final String formationId;  // 編隊識別碼

  // 追蹤編隊成員
  final List<FormationEnemy> _members = [];
  bool _bonusDropped = false;

  EnemyFormation({
    required this.type,
    required this.enemyType,
    this.count = 5,
    required this.startPosition,
    this.spacing = 60,
  }) : formationId = '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';

  @override
  Future<void> onLoad() async {
    final positions = _calculatePositions();

    for (int i = 0; i < positions.length; i++) {
      // 依序生成，有延遲效果
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (isMounted && game.isPlaying) {
          final enemy = FormationEnemy(
            position: positions[i],
            type: enemyType,
            formation: this,
          );
          _members.add(enemy);
          game.world.add(enemy);
        }
      });
    }
  }

  /// 當編隊成員被擊殺時調用
  void onMemberKilled(FormationEnemy member, Vector2 deathPosition) {
    _members.remove(member);

    // 檢查是否全部被消滅
    if (_members.isEmpty && !_bonusDropped) {
      _bonusDropped = true;
      _dropFormationBonus(deathPosition);
    }
  }

  /// 掉落編隊 bonus 道具
  void _dropFormationBonus(Vector2 position) {
    final bonusType = PowerUpSpawner.getFormationBonusType();
    game.world.add(PowerUp(
      position: position,
      type: bonusType,
    ));

    // 額外分數獎勵
    game.addScore(200);
    debugPrint('Formation wiped! Bonus dropped: ${bonusType.name}');
  }

  List<Vector2> _calculatePositions() {
    switch (type) {
      case FormationType.vShape:
        return _vShapePositions();
      case FormationType.line:
        return _linePositions();
      case FormationType.circle:
        return _circlePositions();
      case FormationType.arrow:
        return _arrowPositions();
      case FormationType.wave:
        return _wavePositions();
    }
  }

  List<Vector2> _vShapePositions() {
    final positions = <Vector2>[];
    final halfCount = count ~/ 2;

    // 中心點
    positions.add(startPosition.clone());

    // 左右兩翼
    for (int i = 1; i <= halfCount; i++) {
      positions.add(startPosition + Vector2(-i * spacing * 0.7, i * spacing * 0.5));
      positions.add(startPosition + Vector2(i * spacing * 0.7, i * spacing * 0.5));
    }

    return positions.take(count).toList();
  }

  List<Vector2> _linePositions() {
    final positions = <Vector2>[];
    final startX = startPosition.x - (count - 1) * spacing / 2;

    for (int i = 0; i < count; i++) {
      positions.add(Vector2(startX + i * spacing, startPosition.y));
    }

    return positions;
  }

  List<Vector2> _circlePositions() {
    final positions = <Vector2>[];
    final radius = spacing * 1.5;

    for (int i = 0; i < count; i++) {
      final angle = (i / count) * pi * 2 - pi / 2;
      positions.add(startPosition + Vector2(
        cos(angle) * radius,
        sin(angle) * radius * 0.5 + radius * 0.3,
      ));
    }

    return positions;
  }

  List<Vector2> _arrowPositions() {
    final positions = <Vector2>[];

    // 箭頭頂端
    positions.add(startPosition.clone());

    // 箭頭兩側
    for (int i = 1; i < count; i++) {
      final row = (i + 1) ~/ 2;
      final side = i % 2 == 1 ? -1 : 1;
      positions.add(startPosition + Vector2(
        side * row * spacing * 0.6,
        row * spacing * 0.4,
      ));
    }

    return positions;
  }

  List<Vector2> _wavePositions() {
    final positions = <Vector2>[];
    final startX = startPosition.x - (count - 1) * spacing / 2;

    for (int i = 0; i < count; i++) {
      final waveOffset = sin(i * 0.8) * 40;
      positions.add(Vector2(startX + i * spacing, startPosition.y + waveOffset));
    }

    return positions;
  }
}

/// 編隊敵人（繼承自 Enemy，但有編隊追蹤功能）
class FormationEnemy extends Enemy {
  final EnemyFormation formation;

  FormationEnemy({
    required super.position,
    required super.type,
    required this.formation,
    super.spawnDirection = SpawnDirection.top,
  });

  @override
  void _onDestroyed() {
    // 通知編隊
    formation.onMemberKilled(this, position.clone());

    // 編隊敵人不個別掉落道具（由編隊 bonus 統一掉落）
    // 但仍然計算分數
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
    game.onEnemyKilled();

    // 爆炸效果
    game.world.add(Explosion(position: position.clone()));
    removeFromParent();
  }
}

/// 編隊生成配置
class FormationSpawner {
  static final _random = Random();

  /// 根據波數生成適當的編隊
  static void spawnFormation(SpaceGame game, int wave) {
    final formationType = _getFormationType(wave);
    final enemyType = _getFormationEnemyType(wave);
    final count = _getFormationCount(wave);

    final startX = 100.0 + _random.nextDouble() * (game.size.x - 200);

    game.world.add(EnemyFormation(
      type: formationType,
      enemyType: enemyType,
      count: count,
      startPosition: Vector2(startX, -80),
    ));
  }

  static FormationType _getFormationType(int wave) {
    final types = FormationType.values;
    if (wave < 3) {
      // 前期只有簡單編隊
      return _random.nextBool() ? FormationType.line : FormationType.vShape;
    } else if (wave < 6) {
      // 中期更多種類
      return types[_random.nextInt(3)];
    } else {
      // 後期全種類
      return types[_random.nextInt(types.length)];
    }
  }

  static EnemyType _getFormationEnemyType(int wave) {
    // 編隊敵人通常是同一種類
    if (wave < 3) {
      return EnemyType.basic;
    } else if (wave < 5) {
      return _random.nextBool() ? EnemyType.basic : EnemyType.fast;
    } else if (wave < 8) {
      final types = [EnemyType.basic, EnemyType.fast, EnemyType.zigzag];
      return types[_random.nextInt(types.length)];
    } else {
      // 後期可能是強力敵人編隊
      final roll = _random.nextDouble();
      if (roll < 0.4) return EnemyType.basic;
      if (roll < 0.6) return EnemyType.fast;
      if (roll < 0.75) return EnemyType.zigzag;
      if (roll < 0.9) return EnemyType.shooter;
      return EnemyType.tank;
    }
  }

  static int _getFormationCount(int wave) {
    final baseCount = 3 + wave ~/ 2;
    return baseCount.clamp(3, 9);
  }
}
