import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'space_game.dart';
import 'laser.dart';

class PowerUp extends SpriteComponent
    with HasGameReference<SpaceGame>, CollisionCallbacks {
  final Vector2 velocity;
  final String type;
  int health;
  double _glowTimer = 0;

  PowerUp({
    required super.sprite,
    required this.velocity,
    required this.type,
    required this.health,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox(radius: size.x * 0.4, position: size / 2, anchor: Anchor.center));
  }

  @override
  void render(Canvas canvas) {
    final glowIntensity = 0.7 + 0.3 * (0.5 + 0.5 * ((_glowTimer * 2) % 1));
    
    final glowColor = type == 'rapidfire' 
        ? Colors.cyan.withValues(alpha: 0.6 * glowIntensity)
        : Colors.lightBlue.withValues(alpha: 0.6 * glowIntensity);
    
    final glowPaint = Paint()
      ..color = glowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x * 0.6,
      glowPaint,
    );
    
    super.render(canvas);
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Laser) {
      health--;
      if (health <= 0) {
        if (type == 'rapidfire') {
          game.activatePowerUp();
        } else if (type == 'extralife') {
          game.addLife();
        }
        removeFromParent();
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;
    _glowTimer += dt;

    if (position.x < -size.x - 120) {
      game.onPowerUpExpired();
      removeFromParent();
    }
  }
}
