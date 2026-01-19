import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:practice_game/ball.dart';
import 'package:practice_game/brick.dart';
import 'package:practice_game/lives_display.dart';
import 'package:practice_game/main.dart';
import 'package:practice_game/paddle.dart';
import 'package:practice_game/play_area.dart';
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
        ).normalized()..scale(height / 4),
      ),
    );
  }

  void setScore(int newScore) {
    _score = newScore;
  }

  void incScore() {
    _score++;
  }

  @override
  void onLoad() {
    super.onLoad();
    camera.viewfinder.anchor = Anchor.topLeft;
    world.add(PlayArea());
    world.add(ScoreDisplay());
    world.add(LivesDisplay());
    startGame();
  }

  void startGame() {
    world.removeAll(world.children.query<Ball>());
    world.removeAll(world.children.query<Paddle>());
    world.removeAll(world.children.query<Brick>());

    world.add(
      Ball(
        difficultyModifier: difficultyModifier,
        radius: ballRadius,
        position: size / 2,
        velocity: Vector2(
          (rand.nextDouble() - 0.5) * width,
          height * 0.3,
        ).normalized()..scale(height / 4),
      ),
    );

    world.add(
      Paddle(
        size: Vector2(paddleWidth, paddleHeight),
        cornerRadius: const Radius.circular(ballRadius / 2),
        position: Vector2(width / 2, height * 0.95),
      ),
    );

    world.addAll([
      for (var i = 0; i < brickColors.length; i++)
        for (var j = 1; j <= 5; j++)
          Brick(
            Vector2(
              (i + 0.5) * brickWidth + (i + 1) * brickGutter,
              (j + 2.0) * brickHeight + j * brickGutter,
            ),
            brickColors[i],
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

  @override
  Color backgroundColor() => const Color(0xfff2e8cf);
}
