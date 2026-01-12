import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game/space_game.dart';
import 'overlays/game_over_menu.dart';
import 'overlays/main_menu.dart';
import 'overlays/pause_menu.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flame Demo Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late SpaceGame game;

  @override
  void initState() {
    super.initState();
    game = SpaceGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: game,
        overlayBuilderMap: {
          'MainMenu': (context, game) => MainMenu(game: game as SpaceGame),
          'PauseMenu': (context, game) => PauseMenu(game: game as SpaceGame),
          'GameOver': (context, game) => GameOverMenu(game: game as SpaceGame),
        },
        initialActiveOverlays: const ['MainMenu'],
      ),
    );
  }
}
