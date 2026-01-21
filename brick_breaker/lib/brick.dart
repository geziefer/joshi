import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:practice_game/brick_breaker.dart';
import 'package:practice_game/main.dart';

class Brick extends RectangleComponent
    with CollisionCallbacks, HasGameReference<BrickBreaker> {
  Brick(Vector2 position, Color color, {this.hitsRequired = 1, Vector2? customSize, this.isIndestructible = false})
    : _baseColor = color,
      super(
        position: position,
        size: customSize ?? Vector2(brickWidth, brickHeight),
        anchor: Anchor.center,
        paint: Paint()
          ..color = isIndestructible ? const Color(0xff808080) : color
          ..style = PaintingStyle.fill,
        children: [RectangleHitbox()],
      );

  final int hitsRequired;
  final Color _baseColor;
  final bool isIndestructible;
  int _currentHits = 0;

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    
    if (isIndestructible) {
      return;
    }
    
    _currentHits++;

    if (_currentHits >= hitsRequired) {
      removeFromParent();
      game.incScore();

      // Nur zerstörbare Bricks zählen für Level-Fortschritt
      final remainingDestructibleBricks = game.world.children
          .query<Brick>()
          .where((b) => !b.isIndestructible)
          .length;
      
      if (remainingDestructibleBricks == 1) {
        game.nextLevel();
      }
    } else {
      paint.color = Color.lerp(
        _baseColor,
        Colors.white,
        _currentHits / hitsRequired,
      )!;
    }
  }
}
