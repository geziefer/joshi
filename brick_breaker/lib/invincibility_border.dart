import 'dart:ui';
import 'package:flame/components.dart';
import 'package:practice_game/brick_breaker.dart';

class InvincibilityBorder extends RectangleComponent
    with HasGameReference<BrickBreaker> {
  InvincibilityBorder()
      : super(
          anchor: Anchor.topLeft,
          paint: Paint()
            ..color = const Color(0x8800ff00)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 20,
        );

  double _glowTimer = 0;

  @override
  void onLoad() {
    super.onLoad();
    size = Vector2(game.width, game.height);
    position = Vector2.zero();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _glowTimer += dt * 3;
    
    final opacity = ((1 + (0.5 * (1 + ((_glowTimer % 1.0) * 2 - 1)))) * 136).toInt();
    paint.color = Color.fromARGB(opacity, 0, 255, 0);
  }
}
