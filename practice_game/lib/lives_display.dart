import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:practice_game/brick_breaker.dart';

class LivesDisplay extends PositionComponent with HasGameReference<BrickBreaker> {
  LivesDisplay() : super(position: Vector2(650, 20), size: Vector2(150, 30));

  final List<CircleComponent> hearts = [];

  @override
  Future<void> onLoad() async {
    for (int i = 0; i < 3; i++) {
      final heart = CircleComponent(
        radius: 12,
        position: Vector2(i * 40.0, 0),
        paint: Paint()..color = const Color(0xFFE74C3C),
      );
      hearts.add(heart);
      add(heart);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (int i = 0; i < hearts.length; i++) {
      hearts[i].paint.color = i < game.lives 
          ? const Color(0xFFE74C3C) 
          : const Color(0x40E74C3C);
    }
  }
}
