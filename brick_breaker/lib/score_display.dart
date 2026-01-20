import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:practice_game/brick_breaker.dart';

class ScoreDisplay extends TextComponent with HasGameReference<BrickBreaker> {
  ScoreDisplay()
      : super(
          text: 'Score: 0',
          textRenderer: TextPaint(
            style: const TextStyle(
              fontSize: 24,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          anchor: Anchor.topLeft,
          position: Vector2(10, 10),
        );

  @override
  void update(double dt) {
    super.update(dt);
    text = 'Score: ${game.score}';
  }
}
