import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:practice_game/ball.dart';
import 'package:practice_game/brick.dart';
import 'package:practice_game/heart_power_up.dart';
import 'package:practice_game/invincibility_border.dart';
import 'package:practice_game/invincibility_power_up.dart';
import 'package:practice_game/level.dart';
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

  bool _isInvincible = false;
  double _invincibilityTimer = 0;
  double _invincibilityPowerUpTimer = 0;
  double _heartPowerUpTimer = 0;

  int _level = 1;
  int get level => _level;
  bool get isInvincible => _isInvincible;

  bool _isPaddleFrozen = false;
  bool get isPaddleFrozen => _isPaddleFrozen;

  bool _checkForLevelComplete = false;

  double getInitialBallSpeed() {
    return LevelConfig.getBallSpeed(_level, height);
  }

  double getPreviousLevelSpeed() {
    return LevelConfig.getBallSpeed(_level - 1, height);
  }

  void loseLife() {
    _lives--;
    if (_lives <= 0) {
      onGameOver();
    } else {
      respawnBallWithoutPowerUpCollection();
    }
  }

  void addLife() {
    if (_lives < 3) {
      _lives++;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Prüfe Level-Abschluss
    if (_checkForLevelComplete) {
      final remainingBricks = world.children
          .query<Brick>()
          .where((b) => !b.isIndestructible)
          .length;

      if (remainingBricks == 0) {
        _checkForLevelComplete = false;
        _level++;
        startGame();
        return;
      }
    }

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
              position: Vector2(width / 2, height * 0.5),
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

    // Invincibility timer
    if (_isInvincible) {
      _invincibilityTimer += dt;
      if (_invincibilityTimer >= 10.0) {
        _isInvincible = false;
        _invincibilityTimer = 0;
        _invincibilityPowerUpTimer = 0;
        // Border entfernen
        world.removeAll(world.children.query<InvincibilityBorder>());
      }
    }

    // Invincibility Power-Up spawner (Level 3+)
    // Timer läuft nur wenn keine roten Bälle aktiv sind
    if (_level >= 3 && !_isInvincible && _activeBonusBalls == 0) {
      _invincibilityPowerUpTimer += dt;
      final spawnTime = 15.0 + (rand.nextDouble() * 10.0);
      if (_invincibilityPowerUpTimer >= spawnTime) {
        if (world.children.query<InvincibilityPowerUp>().isEmpty) {
          // Nur spawnen wenn kein Heart Power-Up existiert
          if (world.children.query<HeartPowerUp>().isEmpty) {
            final randomX = rand.nextDouble() * width;
            final spawnY = height * 0.4;
            world.add(InvincibilityPowerUp(position: Vector2(randomX, spawnY)));
            _invincibilityPowerUpTimer = 0;
          }
          // Timer NICHT zurücksetzen wenn Heart Power-Up existiert - wartet bis es weg ist
        }
      }
    }

    // Heart Power-Up spawner (Level 4+)
    if (_level >= 4 && _lives < 3) {
      _heartPowerUpTimer += dt;
      final spawnTime = 30.0 + (rand.nextDouble() * 15.0);
      if (_heartPowerUpTimer >= spawnTime) {
        if (world.children.query<HeartPowerUp>().isEmpty) {
          // Nur spawnen wenn kein Invincibility Power-Up existiert
          if (world.children.query<InvincibilityPowerUp>().isEmpty) {
            final randomX = rand.nextDouble() * width;
            final spawnY = height * 0.4;
            world.add(HeartPowerUp(position: Vector2(randomX, spawnY)));
            _heartPowerUpTimer = 0;
          }
          // Timer NICHT zurücksetzen wenn Invincibility Power-Up existiert - wartet bis es weg ist
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
        position: Vector2(width / 2, height * 0.5),
        velocity: Vector2(
          (rand.nextDouble() - 0.5) * width,
          height * 0.3,
        ).normalized()..scale(getInitialBallSpeed()),
      ),
    );
  }

  void respawnBallWithoutPowerUpCollection() {
    world.removeAll(world.children.query<Ball>());
    final newBall = Ball(
      difficultyModifier: difficultyModifier,
      radius: ballRadius,
      position: Vector2(width / 2, height * 0.5),
      velocity: Vector2(
        (rand.nextDouble() - 0.5) * width,
        height * 0.3,
      ).normalized()..scale(getInitialBallSpeed()),
    );
    newBall.canCollectPowerUp = false;
    world.add(newBall);
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
    final invincibilityActive = _isInvincible;

    if (!powerUpExists && !bonusBallsActive && !invincibilityActive) {
      _bricksDestroyed++;
    }

    // Ball beschleunigen bei Brick-Zerstörung (ab Level 2)
    if (_level >= 2) {
      final balls = world.children.query<Ball>();
      final levelModifier = LevelConfig.getBallSpeedModifier(_level);

      for (final ball in balls) {
        ball.velocity.setFrom(ball.velocity * levelModifier);
      }
    }

    // Power-Up nur spawnen wenn Counter erreicht und keins existiert
    if (_level >= 2 && _bricksDestroyed >= _bricksUntilPowerUp) {
      if (world.children.query<PowerUp>().isEmpty &&
          _activeBonusBalls == 0 &&
          !_isInvincible) {
        _bricksDestroyed = 0;
        _bricksUntilPowerUp = LevelConfig.getYellowPowerUpInterval(
          _level,
          rand,
        );
        world.add(PowerUp(position: size / 2));
      }
    }

    // Markiere für Level-Abschluss-Prüfung im nächsten Frame
    _checkForLevelComplete = true;
  }

  void activatePowerUp() {
    _mainBall = world.children.query<Ball>().firstOrNull;
    if (_mainBall != null) {
      _mainBall!.removeFromParent();
    }

    _activeBonusBalls = 3;
    _bonusBallTimer = 0;

    // Grünes Power-Up entfernen wenn vorhanden
    world.removeAll(world.children.query<InvincibilityPowerUp>());

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
              position: Vector2(width / 2, height * 0.5),
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
      _activeBonusBalls = 0;
      _bonusBallTimer = 0;
      // Immer einen neuen Ball spawnen wenn alle Bonus-Bälle weg sind
      world.add(
        Ball(
          difficultyModifier: difficultyModifier,
          radius: ballRadius,
          position: Vector2(width / 2, height * 0.5),
          velocity: Vector2(
            (rand.nextDouble() - 0.5) * width,
            height * 0.3,
          ).normalized()..scale(getInitialBallSpeed()),
        ),
      );
      _mainBall = null;
    }
  }

  void activateInvincibility() {
    _isInvincible = true;
    _invincibilityTimer = 0;

    // Border-Effekt hinzufügen
    world.add(InvincibilityBorder());

    // Text-Anzeige hinzufügen
    final textComponent = TextComponent(
      text: 'Unsterblichkeit',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 60,
          color: Color(0xff00ff00),
          fontWeight: FontWeight.bold,
        ),
      ),
      position: Vector2(width / 2, height / 2),
      anchor: Anchor.center,
    );
    world.add(textComponent);

    // Text nach 2 Sekunden entfernen
    Future.delayed(const Duration(seconds: 2), () {
      textComponent.removeFromParent();
    });
  }

  void onInvincibilityPowerUpMissed() {
    _invincibilityPowerUpTimer = 0;
  }

  @override
  void onLoad() async {
    super.onLoad();
    await LevelConfig.loadLevels();
    camera.viewfinder.anchor = Anchor.topLeft;
    world.add(PlayArea());
    world.add(ScoreDisplay());
    world.add(LivesDisplay());
    world.add(LevelDisplay());
  }

  void startGame({bool withCountdown = false}) async {
    _checkForLevelComplete = false;
    world.removeAll(world.children.query<Ball>());
    world.removeAll(world.children.query<Paddle>());
    world.removeAll(world.children.query<Brick>());
    world.removeAll(world.children.query<PowerUp>());
    world.removeAll(world.children.query<InvincibilityPowerUp>());
    world.removeAll(world.children.query<HeartPowerUp>());

    _bricksDestroyed = 0;
    _bricksUntilPowerUp = LevelConfig.getYellowPowerUpInterval(_level, rand);
    _mainBall = null;
    _activeBonusBalls = 0;
    _bonusBallTimer = 0;
    _isInvincible = false;
    _invincibilityTimer = 0;
    _invincibilityPowerUpTimer = 0;
    _heartPowerUpTimer = 0;

    // Paddle sofort hinzufügen
    final paddle = Paddle(
      size: Vector2(paddleWidth, paddleHeight),
      cornerRadius: const Radius.circular(ballRadius / 2),
      position: Vector2(width / 2, height * 0.95),
    );
    world.add(paddle);

    // Bricks hinzufügen
    world.addAll(LevelConfig.buildLevel(_level, width, height, rand));

    if (withCountdown) {
      _isPaddleFrozen = true;

      // Countdown: 3, 2, 1, GO
      for (var i = 3; i > 0; i--) {
        final countText = TextComponent(
          text: '$i',
          textRenderer: TextPaint(
            style: const TextStyle(
              fontSize: 120,
              color: Color(0xff1e6091),
              fontWeight: FontWeight.bold,
            ),
          ),
          position: Vector2(width / 2, height / 2),
          anchor: Anchor.center,
        );
        world.add(countText);
        await Future.delayed(const Duration(seconds: 1));
        countText.removeFromParent();
      }

      // GO!
      final goText = TextComponent(
        text: 'GO!',
        textRenderer: TextPaint(
          style: const TextStyle(
            fontSize: 120,
            color: Color(0xff43aa8b),
            fontWeight: FontWeight.bold,
          ),
        ),
        position: Vector2(width / 2, height / 2),
        anchor: Anchor.center,
      );
      world.add(goText);
      await Future.delayed(const Duration(milliseconds: 800));
      goText.removeFromParent();

      _isPaddleFrozen = false;
    }

    // Ball spawnen
    world.add(
      Ball(
        isBonus: false,
        difficultyModifier: difficultyModifier,
        radius: ballRadius,
        position: Vector2(width / 2, height * 0.5),
        velocity: Vector2(
          (rand.nextDouble() - 0.5) * width,
          height * 0.3,
        ).normalized()..scale(getInitialBallSpeed()),
      ),
    );
  }

  void nextLevel() {
    _level++;
    startGame();
  }
}
