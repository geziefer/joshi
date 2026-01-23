import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:practice_game/brick_breaker.dart';
import 'package:practice_game/paddle.dart';

class ShooterPowerUp extends CircleComponent
    with CollisionCallbacks, HasGameReference<BrickBreaker> {
  ShooterPowerUp({required super.position})
    : super(
        radius: 30,
        anchor: Anchor.center,
        paint: Paint()
          ..color = const Color(0xffff00ff)
          ..style = PaintingStyle.fill,
        children: [CircleHitbox()],
      );

  static const double fallSpeed = 300;

  @override
  void update(double dt) {
    super.update(dt);
    position.y += fallSpeed * dt;

    if (position.y > game.height) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Paddle) {
      game.activateShooterMode();
      removeFromParent();
    }
  }
}
