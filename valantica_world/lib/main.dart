import 'package:firebase_core/firebase_core.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:valantica_world/game_over_screen.dart';
import 'package:valantica_world/highscore_manager.dart';
import 'package:valantica_world/highscore_name_dialog.dart';
import 'package:valantica_world/mobile_controls.dart';
import 'package:valantica_world/start_screen.dart';
import 'package:valantica_world/level_manager.dart';
import 'package:valantica_world/level_transition_screen.dart';

import 'space_game.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDu91gsy60LFajTQOIOcYAvaVjLJGJWmik",
      authDomain: "brick-breaker-32771.firebaseapp.com",
      databaseURL:
          "https://brick-breaker-32771-default-rtdb.europe-west1.firebasedatabase.app",
      projectId: "brick-breaker-32771",
      storageBucket: "brick-breaker-32771.firebasestorage.app",
      messagingSenderId: "223791541084",
      appId: "1:223791541084:web:b7ff83daf05e4cf4a62f99",
    ),
  );

  await LevelManager.loadLevels();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late SpaceGame _game;
  bool _gameStarted = false;
  bool _showingGameOver = false;
  bool _showingHighscoreDialog = false;
  bool _showingLevelTransition = false;
  int? _finalScore;

  @override
  void initState() {
    super.initState();
    _game = SpaceGame(
      onGameOver: _onGameOver,
      onLevelComplete: _onLevelComplete,
    );
  }

  void _onLevelComplete() async {
    if (LevelManager.hasNextLevel) {
      LevelManager.nextLevel();
      _game.isGameOver = true;
      setState(() {
        _showingLevelTransition = true;
      });
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _showingLevelTransition = false;
      });
      _game.loadLevel();
      _game.isGameOver = false;
    } else {
      _onGameOver();
    }
  }

  void _onGameOver() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );

    final score = _game.score;
    _finalScore = score;

    setState(() {
      _showingGameOver = true;
    });

    await Future.delayed(const Duration(seconds: 3));

    final isTop10 = await HighscoreManager.isTop10Score(score);

    setState(() {
      _showingGameOver = false;
      _gameStarted = false;
      _showingHighscoreDialog = isTop10;
    });

    if (!isTop10) {
      Future.delayed(const Duration(milliseconds: 100), () {
        setState(() {
          LevelManager.reset();
          _game = SpaceGame(
            onGameOver: _onGameOver,
            onLevelComplete: _onLevelComplete,
          );
        });
      });
    }
  }

  void _onHighscoreSubmit(String username) async {
    if (_finalScore != null) {
      try {
        debugPrint('Saving highscore: $username - $_finalScore');
        await HighscoreManager.addScore(username, _finalScore!);
        debugPrint('Highscore saved successfully');
      } catch (e, stackTrace) {
        debugPrint('Error saving highscore: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    }
    setState(() {
      _showingHighscoreDialog = false;
      LevelManager.reset();
      _game = SpaceGame(
        onGameOver: _onGameOver,
        onLevelComplete: _onLevelComplete,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: _showingLevelTransition
            ? LevelTransitionScreen(
                levelNumber: LevelManager.currentLevelNumber,
              )
            : _showingHighscoreDialog
            ? HighscoreNameDialog(
                score: _finalScore!,
                onSubmit: _onHighscoreSubmit,
              )
            : _showingGameOver
            ? GameOverScreen(score: _finalScore!)
            : _gameStarted
            ? Stack(
                children: [
                  GameWidget(game: _game),
                  MobileControls(
                    onUpPressed: () => _game.setUpPressed(true),
                    onUpReleased: () => _game.setUpPressed(false),
                    onDownPressed: () => _game.setDownPressed(true),
                    onDownReleased: () => _game.setDownPressed(false),
                    onShootPressed: () => _game.startShooting(),
                    onShootReleased: () => _game.stopShooting(),
                  ),
                ],
              )
            : StartScreen(
                onStart: () async {
                  await SystemChrome.setEnabledSystemUIMode(
                    SystemUiMode.immersiveSticky,
                  );
                  setState(() {
                    _gameStarted = true;
                  });
                },
              ),
      ),
    );
  }
}
