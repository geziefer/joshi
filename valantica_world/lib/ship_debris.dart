import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'space_game.dart';

class ShipDebris extends PositionComponent with HasGameReference<SpaceGame> {
  final Vector2 velocity;
  final double debrisSize;
  double _life = 1.5;

  ShipDebris({
    required Vector2 position,
    required this.velocity,
    required double size,
  }) : debrisSize = size,
       super(position: position, size: Vector2.all(size));

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.orange.withValues(alpha: _life / 1.5)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, debrisSize, debrisSize), paint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;
    _life -= dt;
    if (_life <= 0) removeFromParent();
  }
}
