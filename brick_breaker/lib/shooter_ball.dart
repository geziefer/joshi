import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:practice_game/brick.dart';
import 'package:practice_game/brick_breaker.dart';

class ShooterBall extends CircleComponent
    with CollisionCallbacks, HasGameReference<BrickBreaker> {
  ShooterBall({required super.position})
    : super(
        radius: 12,
        anchor: Anchor.center,
        paint: Paint()
          ..color = const Color(0xffff00ff)
          ..style = PaintingStyle.fill,
        children: [CircleHitbox()],
      );

  static const double speed = 800;

  @override
  void update(double dt) {
    super.update(dt);
    position.y -= speed * dt;

    if (position.y < 0) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Brick) {
      add(RemoveEffect(delay: 0.01));
    }
  }
}
