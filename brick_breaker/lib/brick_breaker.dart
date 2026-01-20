import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:practice_game/ball.dart';
import 'package:practice_game/brick.dart';
import 'package:practice_game/level_display.dart';
import 'package:practice_game/lives_display.dart';
import 'package:practice_game/main.dart';
import 'package:practice_game/paddle.dart';
import 'package:practice_game/play_area.dart';
import 'package:practice_game/power_up.dart';
import 'package:practice_game/score_display.dart';

class BrickBreaker extends FlameGame
    with HasCollisionDetection, KeyboardEvents, TapCallbacks {
  BrickBreaker({required this.onGameOver})
    : super(
        camera: CameraComponent.withFixedResolution(
          width: gameWidth,
          height: gameHeight,
        ),
      );

  final VoidCallback onGameOver;

  final rand = math.Random();
  double get width => size.x;
  double get height => size.y;

  int _score = 0;
  int get score => _score;

  int _lives = 3;
  int get lives => _lives;

  int _bricksDestroyed = 0;
  int _bricksUntilPowerUp = 5;
  Ball? _mainBall;
  int _activeBonusBalls = 0;

  int _level = 1;
  int get level => _level;

  double getInitialBallSpeed() {
    return height / (3 - (_level * 0.2));
  }

  double getPreviousLevelSpeed() {
    return height / (3 - ((_level - 1) * 0.2));
  }

  void loseLife() {
    _lives--;
    if (_lives <= 0) {
      onGameOver();
    } else {
      respawnBall();
    }
  }

  void respawnBall() {
    world.removeAll(world.children.query<Ball>());
    world.add(
      Ball(
        difficultyModifier: difficultyModifier,
        radius: ballRadius,
        position: size / 2,
        velocity: Vector2(
          (rand.nextDouble() - 0.5) * width,
          height * 0.3,
        ).normalized()..scale(getInitialBallSpeed()),
      ),
    );
  }

  void setScore(int newScore) {
    _score = newScore;
  }

  void incScore() {
    _score++;
  }

  void onBrickDestroyed(Vector2 brickPosition) {
    _bricksDestroyed++;

    // Ball beschleunigen bei Brick-Zerstörung (ab Level 2)
    if (_level >= 2) {
      final balls = world.children.query<Ball>();
      for (final ball in balls) {
        if (!ball.isBonus) {
          final levelModifier = 1.0 + (_level * 0.02); // 2% pro Level
          ball.velocity.setFrom(ball.velocity * levelModifier);
        }
      }
    }

    if (_bricksDestroyed >= _bricksUntilPowerUp) {
      if (world.children.query<PowerUp>().isEmpty) {
        _bricksDestroyed = 0;
        _bricksUntilPowerUp = rand.nextInt(6) + 5;
        world.add(PowerUp(position: size / 2));
      }
    }
  }

  void activatePowerUp() {
    _mainBall = world.children.query<Ball>().firstOrNull;
    if (_mainBall != null) {
      _mainBall!.removeFromParent();
    }

    _activeBonusBalls = 3;
    final bonusSpeed = _level > 1
        ? getPreviousLevelSpeed()
        : getInitialBallSpeed();
    for (var i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 300), () {
        if (_activeBonusBalls > 0) {
          world.add(
            Ball(
              isBonus: true,
              difficultyModifier: difficultyModifier,
              radius: ballRadius,
              position: size / 2,
              velocity: Vector2(
                (rand.nextDouble() - 0.5) * width,
                height * 0.3,
              ).normalized()..scale(bonusSpeed),
            ),
          );
        }
      });
    }
  }

  void onBonusBallLost() {
    _activeBonusBalls--;
    if (_activeBonusBalls <= 0 && _mainBall != null) {
      world.add(
        Ball(
          difficultyModifier: difficultyModifier,
          radius: ballRadius,
          position: size / 2,
          velocity: Vector2(
            (rand.nextDouble() - 0.5) * width,
            height * 0.3,
          ).normalized()..scale(getInitialBallSpeed()),
        ),
      );
      _mainBall = null;
    }
  }

  @override
  void onLoad() {
    super.onLoad();
    camera.viewfinder.anchor = Anchor.topLeft;
    world.add(PlayArea());
    world.add(ScoreDisplay());
    world.add(LivesDisplay());
    world.add(LevelDisplay());
    startGame();
  }

  void startGame() {
    world.removeAll(world.children.query<Ball>());
    world.removeAll(world.children.query<Paddle>());
    world.removeAll(world.children.query<Brick>());
    world.removeAll(world.children.query<PowerUp>());

    _bricksDestroyed = 0;
    _bricksUntilPowerUp = rand.nextInt(6) + 5;
    _mainBall = null;
    _activeBonusBalls = 0;

    world.add(
      Ball(
        isBonus: false,
        difficultyModifier: difficultyModifier,
        radius: ballRadius,
        position: size / 2,
        velocity: Vector2(
          (rand.nextDouble() - 0.5) * width,
          height * 0.3,
        ).normalized()..scale(getInitialBallSpeed()),
      ),
    );

    world.add(
      Paddle(
        size: Vector2(paddleWidth, paddleHeight),
        cornerRadius: const Radius.circular(ballRadius / 2),
        position: Vector2(width / 2, height * 0.95),
      ),
    );

    final levelColor = brickColors[(_level - 1) % brickColors.length];
    final hitsRequired = _level >= 2 ? 2 : 1; // Ab Level 2: 2 Treffer
    final multiHitColor = _level >= 2
        ? getContrastColor(levelColor)
        : levelColor;

    world.addAll([
      for (var i = 0; i < brickColors.length; i++)
        for (var j = 1; j <= 5; j++)
          Brick(
            Vector2(
              (i + 0.5) * brickWidth + (i + 1) * brickGutter,
              (j + 2.0) * brickHeight + j * brickGutter,
            ),
            _level >= 2 ? multiHitColor : levelColor,
            hitsRequired: hitsRequired,
          ),
    ]);
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    startGame();
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    super.onKeyEvent(event, keysPressed);
    switch (event.logicalKey) {
      case LogicalKeyboardKey.space:
      case LogicalKeyboardKey.enter:
        startGame();
    }
    return KeyEventResult.handled;
  }

  void nextLevel() {
    _level++;
    startGame();
  }

  @override
  Color backgroundColor() => const Color(0xfff2e8cf);

  // Kontrastreiche Farbe für Multi-Hit Bricks
  Color getContrastColor(Color baseColor) {
    final brightness = baseColor.computeLuminance();
    return brightness > 0.5 ? Colors.black : Colors.orange;
  }
}
