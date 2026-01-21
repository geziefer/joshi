import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:practice_game/brick_breaker.dart';
import 'package:practice_game/paddle.dart';

class HeartPowerUp extends PositionComponent
    with CollisionCallbacks, HasGameReference<BrickBreaker> {
  HeartPowerUp({required super.position})
    : super(size: Vector2.all(80), anchor: Anchor.center);

  static const double fallSpeed = 450.0;
  bool _collected = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += fallSpeed * dt;

    if (position.y > game.height && !_collected) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final paint = Paint()
      ..color = const Color(0xffff0066)
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.x;
    final h = size.y;

    path.moveTo(w / 2, h * 0.75);
    path.cubicTo(w * 0.1, h * 0.5, w * 0.1, h * 0.1, w / 2, h * 0.3);
    path.cubicTo(w * 0.9, h * 0.1, w * 0.9, h * 0.5, w / 2, h * 0.75);

    canvas.drawPath(path, paint);
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Paddle && !_collected && game.lives < 3) {
      _collected = true;
      game.addLife();
      removeFromParent();
    }
  }
}
