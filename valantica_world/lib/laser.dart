import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'space_game.dart';
import 'asteroid.dart';

class Laser extends PositionComponent
    with HasGameReference<SpaceGame>, CollisionCallbacks {
  final double speed = 600;

  Laser({required Vector2 position})
    : super(position: position, size: Vector2(20, 4), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox(collisionType: CollisionType.active));
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), paint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.x += speed * dt;
    if (position.x > game.size.x + 50) removeFromParent();
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Asteroid) {
      removeFromParent();
    }
  }
}
