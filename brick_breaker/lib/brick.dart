import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:practice_game/brick_breaker.dart';
import 'package:practice_game/main.dart';

class Brick extends RectangleComponent
    with CollisionCallbacks, HasGameReference<BrickBreaker> {
  Brick(Vector2 position, Color color, {this.hitsRequired = 1})
    : _baseColor = color,
      super(
        position: position,
        size: Vector2(brickWidth, brickHeight),
        anchor: Anchor.center,
        paint: Paint()
          ..color = color
          ..style = PaintingStyle.fill,
        children: [RectangleHitbox()],
      );

  final int hitsRequired;
  final Color _baseColor;
  int _currentHits = 0;

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    _currentHits++;

    if (_currentHits >= hitsRequired) {
      removeFromParent();
      game.incScore();

      if (game.world.children.query<Brick>().length == 1) {
        game.nextLevel();
      }
    } else {
      // Farbe aufhellen bei jedem Treffer
      paint.color = Color.lerp(
        _baseColor,
        Colors.white,
        _currentHits / hitsRequired,
      )!;
    }
  }
}
