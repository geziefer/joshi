import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:practice_game/ball.dart';
import 'package:practice_game/brick_breaker.dart';
import 'package:practice_game/main.dart';

class Brick extends RectangleComponent
    with CollisionCallbacks, HasGameReference<BrickBreaker> {
  Brick(Vector2 position, Color color, {this.hitsRequired = 1, Vector2? customSize, this.isIndestructible = false, this.isMoving = false, this.moveSpeed = 0.0})
    : _baseColor = color,
      super(
        position: position,
        size: customSize ?? Vector2(brickWidth, brickHeight),
        anchor: Anchor.center,
        paint: Paint()
          ..color = isIndestructible ? const Color(0xff505050) : color
          ..style = PaintingStyle.fill,
        children: [RectangleHitbox()],
      );

  final int hitsRequired;
  final Color _baseColor;
  final bool isIndestructible;
  final bool isMoving;
  final double moveSpeed;
  int _currentHits = 0;
  double _moveDirection = 1.0;

  @override
  void update(double dt) {
    super.update(dt);
    
    if (isMoving) {
      position.x += moveSpeed * _moveDirection * dt;
      
      // Richtung umkehren bei Rand
      if (position.x <= size.x / 2 || position.x >= game.width - size.x / 2) {
        _moveDirection *= -1;
      }
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    
    if (other is! Ball || isIndestructible) {
      return;
    }
    
    _currentHits++;

    // Level 4: Punkte ab dem 2. Treffer
    if (game.level >= 4 && _currentHits >= 2) {
      game.incScore();
    }

    if (_currentHits >= hitsRequired) {
      removeFromParent();
      // Nur in Level 1-3 Punkte beim Zerstören geben
      if (game.level < 4) {
        game.incScore();
      }
      game.onBrickDestroyed(position);
    } else {
      paint.color = Color.lerp(
        _baseColor,
        Colors.white,
        _currentHits / hitsRequired,
      )!;
    }
  }
}
