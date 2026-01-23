/// A simplified brick-breaker game,
/// built using the Flame game engine for Flutter.
///
/// To learn how to build a more complete version of this game yourself,
/// check out the codelab at https://flutter.dev/to/brick-breaker.
library;

import 'package:firebase_core/firebase_core.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:practice_game/brick_breaker.dart';
import 'package:practice_game/login_screen.dart';
import 'package:practice_game/register_dialog.dart';
import 'package:practice_game/login_dialog.dart';
import 'package:practice_game/start_screen.dart';
// import 'package:practice_game/level_manager.dart';

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

  // Levels zu Firebase hochladen (nur einmal ausführen)
  // await LevelManager.uploadLevelsToFirebase();

  runApp(const GameApp());
}

class GameApp extends StatefulWidget {
  const GameApp({super.key});

  @override
  State<GameApp> createState() => _GameAppState();
}

class _GameAppState extends State<GameApp> {
  late BrickBreaker game;
  bool _gameStarted = false;
  String _currentScreen = 'login'; // 'login', 'register', 'loginDialog', 'menu'
  String _currentUsername = '';

  @override
  void initState() {
    super.initState();
    game = BrickBreaker(onGameOver: _onGameOver);
  }

  void _onGameOver() {
    setState(() {
      _gameStarted = false;
      _currentScreen = 'menu';
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        game = BrickBreaker(onGameOver: _onGameOver);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: _gameStarted
            ? Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xffa9d6e5), Color(0xfff2e8cf)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: FittedBox(
                        child: SizedBox(
                          width: gameWidth,
                          height: gameHeight,
                          child: GameWidget(game: game),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : _buildCurrentScreen(),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentScreen) {
      case 'login':
        return LoginScreen(
          onRegister: () {
            setState(() {
              _currentScreen = 'register';
            });
          },
          onLogin: () {
            setState(() {
              _currentScreen = 'loginDialog';
            });
          },
        );
      case 'register':
        return RegisterDialog(
          onRegister: (username) {
            setState(() {
              _currentUsername = username;
              _currentScreen = 'menu';
            });
          },
          onCancel: () {
            setState(() {
              _currentScreen = 'login';
            });
          },
        );
      case 'loginDialog':
        return LoginDialog(
          onLogin: (username) {
            setState(() {
              _currentUsername = username;
              _currentScreen = 'menu';
            });
          },
          onCancel: () {
            setState(() {
              _currentScreen = 'login';
            });
          },
        );
      case 'menu':
        return StartScreen(
          username: _currentUsername,
          onStart: () async {
            setState(() {
              _gameStarted = true;
            });
            await Future.delayed(const Duration(milliseconds: 50));
            game.startGame(withCountdown: true);
          },
          onBack: () {
            setState(() {
              _currentScreen = 'login';
            });
          },
        );
      default:
        return Container();
    }
  }
}

const brickColors = [
  Color(0xff90be6d), // Level 1: Grün
  Color(0xff5a67d8), // Level 2: Lila-Blau (unterscheidet sich von Ball/Paddle)
  Color(0xffffe66d), // Level 3: Noch helleres Gelb
  Color(0xffffbb55), // Level 4: Noch helleres Orange
  Color(0xfff94144), // Level 5: Rot
  Color(0xff9d4edd), // Level 6: Lila
];

const gameWidth = 820.0;
const gameHeight = 1600.0;
const ballRadius = gameWidth * 0.02;
const paddleWidth = gameWidth * 0.2;
const paddleHeight = ballRadius * 2;
const paddleStep = gameWidth * 0.05;
const brickGutter = gameWidth * 0.015;
final brickWidth =
    (gameWidth - (brickGutter * (brickColors.length + 1))) / brickColors.length;
const brickHeight = gameHeight * 0.03;
const difficultyModifier = 1.05;
