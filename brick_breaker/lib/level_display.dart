import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:practice_game/brick_breaker.dart';

class LevelDisplay extends TextComponent with HasGameReference<BrickBreaker> {
  LevelDisplay()
    : super(
        text: 'Level 1',
        textRenderer: TextPaint(
          style: const TextStyle(
            fontSize: 48,
            color: Color(0xff1e6091),
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  @override
  void onLoad() {
    super.onLoad();
    position = Vector2(game.width / 2, 50);
    anchor = Anchor.center;
  }

  @override
  void update(double dt) {
    super.update(dt);
    text = 'Level ${game.level}';
  }
}
