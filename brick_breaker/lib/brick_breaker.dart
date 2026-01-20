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
  double _bonusBallTimer = 0;

  int _level = 1;
  int get level => _level;

  double getInitialBallSpeed() {
    return height / (3 - (_level * 0.25));
  }

  double getPreviousLevelSpeed() {
    return height / (3 - ((_level - 1) * 0.25));
  }

  void loseLife() {
    _lives--;
    if (_lives <= 0) {
      onGameOver();
    } else {
      respawnBall();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_activeBonusBalls > 0) {
      _bonusBallTimer += dt;
      if (_bonusBallTimer >= 30.0) {
        final bonusBalls = world.children
            .query<Ball>()
            .where((b) => b.isBonus)
            .toList();
        for (final ball in bonusBalls) {
          ball.removeFromParent();
        }
        _activeBonusBalls = 0;
        _bonusBallTimer = 0;

        if (_mainBall != null) {
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
    // Counter nur erhöhen wenn kein Power-Up aktiv ist
    final powerUpExists = world.children.query<PowerUp>().isNotEmpty;
    final bonusBallsActive = _activeBonusBalls > 0;
    
    if (!powerUpExists && !bonusBallsActive) {
      _bricksDestroyed++;
    }

    // Ball beschleunigen bei Brick-Zerstörung (ab Level 2)
    if (_level >= 2) {
      final balls = world.children.query<Ball>();
      final levelModifier = 1.0 + (_level * 0.01);
      
      for (final ball in balls) {
        ball.velocity.setFrom(ball.velocity * levelModifier);
      }
    }

    // Power-Up nur spawnen wenn Counter erreicht und keins existiert
    if (_level >= 2 && _bricksDestroyed >= _bricksUntilPowerUp) {
      if (world.children.query<PowerUp>().isEmpty && _activeBonusBalls == 0) {
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
    _bonusBallTimer = 0;
    final bonusSpeed = _level > 1
        ? getPreviousLevelSpeed()
        : getInitialBallSpeed();

    final sharedDirection = Vector2(
      (rand.nextDouble() - 0.5) * width,
      height * 0.3,
    ).normalized()..scale(bonusSpeed);

    for (var i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 300), () {
        if (_activeBonusBalls > 0) {
          world.add(
            Ball(
              isBonus: true,
              difficultyModifier: difficultyModifier,
              radius: ballRadius,
              position: size / 2,
              velocity: Vector2(sharedDirection.x, sharedDirection.y),
            ),
          );
        }
      });
    }
  }

  void onBonusBallLost() {
    _activeBonusBalls--;
    if (_activeBonusBalls <= 0) {
      _bonusBallTimer = 0;
      if (_mainBall != null) {
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
    _bonusBallTimer = 0;

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
    final hitsRequired = _level >= 2 ? 2 : 1;
    final multiHitColor = _level >= 2
        ? getContrastColor(levelColor)
        : levelColor;

    if (_level == 1) {
      // Level 1: 10 große Bricks (2 Reihen x 5 Spalten)
      final largeBrickWidth = (width - (6 * brickGutter)) / 5;
      final largeBrickHeight = brickHeight * 3;
      
      world.addAll([
        for (var i = 0; i < 5; i++)
          for (var j = 0; j < 2; j++)
            Brick(
              Vector2(
                (i + 0.5) * largeBrickWidth + (i + 1) * brickGutter,
                (j + 2.0) * largeBrickHeight + (j + 1) * brickGutter,
              ),
              levelColor,
              hitsRequired: hitsRequired,
              customSize: Vector2(largeBrickWidth, largeBrickHeight),
            ),
      ]);
    } else if (_level == 2) {
      // Level 2: 24 Bricks (4 Reihen x 6 Spalten)
      final mediumBrickWidth = (width - (7 * brickGutter)) / 6;
      final mediumBrickHeight = brickHeight * 1.25;
      
      world.addAll([
        for (var i = 0; i < 6; i++)
          for (var j = 0; j < 4; j++)
            Brick(
              Vector2(
                (i + 0.5) * mediumBrickWidth + (i + 1) * brickGutter,
                (j + 2.0) * mediumBrickHeight + (j + 1) * brickGutter,
              ),
              multiHitColor,
              hitsRequired: hitsRequired,
              customSize: Vector2(mediumBrickWidth, mediumBrickHeight),
            ),
      ]);
    } else {
      // Level 2+: Normale 50 Bricks
      world.addAll([
        for (var i = 0; i < brickColors.length; i++)
          for (var j = 1; j <= 5; j++)
            Brick(
              Vector2(
                (i + 0.5) * brickWidth + (i + 1) * brickGutter,
                (j + 2.0) * brickHeight + j * brickGutter,
              ),
              multiHitColor,
              hitsRequired: hitsRequired,
            ),
      ]);
    }
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
