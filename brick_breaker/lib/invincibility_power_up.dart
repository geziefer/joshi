import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:practice_game/brick_breaker.dart';
import 'package:practice_game/paddle.dart';

class InvincibilityPowerUp extends CircleComponent
    with CollisionCallbacks, HasGameReference<BrickBreaker> {
  InvincibilityPowerUp({required super.position})
      : super(
          radius: 25,
          anchor: Anchor.center,
          paint: Paint()
            ..color = const Color(0xff00ff00)
            ..style = PaintingStyle.fill,
          children: [CircleHitbox()],
        );

  final double fallSpeed = 350.0;
  bool _collected = false;

  @override
  void update(double dt) {
    super.update(dt);
    position.y += fallSpeed * dt;

    if (position.y > game.height && !_collected) {
      game.onInvincibilityPowerUpMissed();
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Paddle && !_collected) {
      _collected = true;
      game.activateInvincibility();
      removeFromParent();
    }
    // Ignoriere Brick-Kollisionen
  }
}
