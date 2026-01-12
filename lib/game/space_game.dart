import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../components/bullet.dart';
import '../components/enemy.dart';
import '../components/hud.dart';
import '../components/player.dart';
import '../components/power_up.dart';
import '../components/star_background.dart';

class SpaceGame extends FlameGame
    with HasCollisionDetection, HasKeyboardHandlerComponents, TapCallbacks {

  late Player player;
  SpawnComponent? enemySpawner;

  int score = 0;
  int highScore = 0;
  bool isPlaying = false;

  // 波數系統
  int wave = 1;
  int enemiesKilledInWave = 0;
  int enemiesPerWave = 10;
  bool isBossBattle = false;
  Boss? currentBoss;

  final Random _random = Random();

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 設定 Camera 使用左上角為原點（更直覺的 2D 座標系統）
    camera.viewfinder.anchor = Anchor.topLeft;

    // Add starfield background
    world.add(StarBackground());
  }

  void startGame() {
    // Reset game state
    score = 0;
    wave = 1;
    enemiesKilledInWave = 0;
    isBossBattle = false;
    isPlaying = true;

    // Remove any existing game components
    _cleanupGameComponents();

    // Create player at center bottom
    player = Player(
      position: Vector2(size.x / 2, size.y - 120),
    );
    player.reset();
    world.add(player);

    // Add HUD
    camera.viewport.add(Hud());

    // Start enemy spawner
    _startWave();

    // Remove menu overlay
    overlays.remove('MainMenu');
    overlays.remove('GameOver');

    debugPrint('=== Game started ===');
  }

  void _cleanupGameComponents() {
    world.children.whereType<Player>().toList().forEach((p) => p.removeFromParent());
    world.children.whereType<Enemy>().toList().forEach((e) => e.removeFromParent());
    world.children.whereType<Boss>().toList().forEach((b) => b.removeFromParent());
    world.children.whereType<Bullet>().toList().forEach((b) => b.removeFromParent());
    world.children.whereType<PowerUp>().toList().forEach((p) => p.removeFromParent());
    world.children.whereType<Explosion>().toList().forEach((e) => e.removeFromParent());
    camera.viewport.children.whereType<Hud>().toList().forEach((h) => h.removeFromParent());
    enemySpawner?.removeFromParent();
    currentBoss = null;
  }

  void _startWave() {
    enemiesKilledInWave = 0;

    // 每 5 波出現 Boss
    if (wave % 5 == 0) {
      _startBossBattle();
      return;
    }

    // 根據波數調整生成速度和敵人數量
    final spawnInterval = (1.2 - wave * 0.05).clamp(0.4, 1.2);
    enemiesPerWave = 10 + wave * 2;

    enemySpawner = SpawnComponent(
      factory: (_) {
        final enemyType = EnemySpawnConfig.getRandomType(wave);
        return Enemy(
          position: Vector2(
            _random.nextDouble() * (size.x - 80) + 40,
            -60,
          ),
          type: enemyType,
        );
      },
      period: spawnInterval,
      selfPositioning: true,
    );
    world.add(enemySpawner!);

    debugPrint('=== Wave $wave started (${enemiesPerWave} enemies) ===');
  }

  void _startBossBattle() {
    isBossBattle = true;
    enemySpawner?.removeFromParent();

    // 清除場上所有普通敵人
    world.children.whereType<Enemy>().toList().forEach((e) => e.removeFromParent());

    // 生成 Boss
    final stage = wave ~/ 5;
    currentBoss = Boss(stage: stage);
    world.add(currentBoss!);

    debugPrint('=== BOSS BATTLE (Stage $stage) ===');
  }

  void onEnemyKilled() {
    if (isBossBattle) return;

    enemiesKilledInWave++;
    if (enemiesKilledInWave >= enemiesPerWave) {
      _completeWave();
    }
  }

  void _completeWave() {
    enemySpawner?.removeFromParent();
    wave++;
    _startWave();
  }

  void onBossDefeated() {
    isBossBattle = false;
    currentBoss = null;
    wave++;

    // 給予額外獎勵
    addScore(500);

    // 短暫延遲後開始下一波
    Future.delayed(const Duration(seconds: 2), () {
      if (isPlaying) {
        _startWave();
      }
    });

    debugPrint('=== Boss defeated! Proceeding to wave $wave ===');
  }

  void pauseGame() {
    if (!isPlaying) return;
    pauseEngine();
    overlays.add('PauseMenu');
  }

  void resumeGame() {
    overlays.remove('PauseMenu');
    resumeEngine();
  }

  void gameOver() {
    isPlaying = false;
    isBossBattle = false;

    // Update high score
    if (score > highScore) {
      highScore = score;
    }

    // Stop spawner
    enemySpawner?.removeFromParent();

    // Show game over screen
    pauseEngine();
    overlays.add('GameOver');

    debugPrint('=== Game Over - Final Score: $score ===');
  }

  void addScore(int points) {
    score += points;
  }

  // 獲取當前玩家生命數（給 HUD 使用）
  int get playerLives => player.lives;

  // 獲取當前波數（給 HUD 使用）
  int get currentWave => wave;

  // 是否正在 Boss 戰
  bool get inBossBattle => isBossBattle;

  @override
  Color backgroundColor() => const Color(0xFF0a0a1a);
}
