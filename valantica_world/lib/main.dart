import 'package:firebase_core/firebase_core.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:valantica_world/highscore_manager.dart';
import 'package:valantica_world/highscore_name_dialog.dart';
import 'package:valantica_world/start_screen.dart';

import 'space_game.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  bool _showingHighscoreDialog = false;
  int? _finalScore;

  @override
  void initState() {
    super.initState();
    _game = SpaceGame(onGameOver: _onGameOver);
  }

  void _onGameOver() async {
    final score = _game.score;
    _finalScore = score;

    final isTop10 = await HighscoreManager.isTop10Score(score);

    setState(() {
      _gameStarted = false;
      _showingHighscoreDialog = isTop10;
    });

    if (!isTop10) {
      Future.delayed(const Duration(milliseconds: 100), () {
        setState(() {
          _game = SpaceGame(onGameOver: _onGameOver);
        });
      });
    }
  }

  void _onHighscoreSubmit(String username) async {
    if (_finalScore != null) {
      await HighscoreManager.addScore(username, _finalScore!);
    }
    setState(() {
      _showingHighscoreDialog = false;
      _game = SpaceGame(onGameOver: _onGameOver);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: _showingHighscoreDialog
            ? HighscoreNameDialog(
                score: _finalScore!,
                onSubmit: _onHighscoreSubmit,
              )
            : _gameStarted
            ? GameWidget(game: _game)
            : StartScreen(
                onStart: () {
                  setState(() {
                    _gameStarted = true;
                  });
                },
              ),
      ),
    );
  }
}
