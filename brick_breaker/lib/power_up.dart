import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:practice_game/ball.dart';
import 'package:practice_game/brick_breaker.dart';

class PowerUp extends CircleComponent
    with CollisionCallbacks, HasGameReference<BrickBreaker> {
  PowerUp({required super.position})
    : super(
        radius: 40,
        anchor: Anchor.center,
        paint: Paint()
          ..color = const Color(0xfff9c74f)
          ..style = PaintingStyle.fill,
        children: [CircleHitbox()],
      );

  double _lifeTime = 0;
  bool _collected = false;

  @override
  void update(double dt) {
    super.update(dt);
    _lifeTime += dt;

    if (_lifeTime >= 10) {
      final blinkSpeed = (_lifeTime - 10) * 3;
      paint.color = Color.lerp(
        const Color(0xfff9c74f),
        const Color(0xffffffff),
        (blinkSpeed % 1.0),
      )!;
    }

    if (_lifeTime >= 15 && !_collected) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Ball && !other.isBonus && !_collected) {
      _collected = true;
      game.activatePowerUp();
      removeFromParent();
    }
  }
}
