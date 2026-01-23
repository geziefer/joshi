import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:practice_game/ball.dart';
import 'package:practice_game/brick_breaker.dart';

class FireballPowerUp extends CircleComponent
    with CollisionCallbacks, HasGameReference<BrickBreaker> {
  FireballPowerUp({required Vector2 position})
      : super(
          position: position,
          radius: 20,
          anchor: Anchor.center,
          paint: Paint()..color = const Color(0xffff6600),
          children: [CircleHitbox()],
        );

  double _lifetime = 0;
  bool _isBlinking = false;

  @override
  void update(double dt) {
    super.update(dt);
    _lifetime += dt;

    if (_lifetime >= 8.0 && !_isBlinking) {
      _isBlinking = true;
    }

    if (_isBlinking) {
      final blinkSpeed = 8.0;
      paint.color = (_lifetime * blinkSpeed) % 1.0 < 0.5
          ? const Color(0xffff6600)
          : const Color(0xffff9944);
    }

    if (_lifetime >= 12.0) {
      removeFromParent();
      game.onFireballPowerUpMissed();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Ball) {
      removeFromParent();
      game.activateFireball();
    }
  }
}
