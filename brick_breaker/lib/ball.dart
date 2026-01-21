import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:practice_game/brick.dart';
import 'package:practice_game/brick_breaker.dart';
import 'package:practice_game/highscore_manager.dart';
import 'package:practice_game/paddle.dart';
import 'package:practice_game/play_area.dart';

class Ball extends CircleComponent
    with CollisionCallbacks, HasGameReference<BrickBreaker> {
  Ball({
    required this.velocity,
    required super.position,
    required double radius,
    required this.difficultyModifier,
    this.isBonus = false,
  }) : super(
         radius: radius,
         anchor: Anchor.center,
         paint: Paint()
           ..color = isBonus ? const Color(0xfff94144) : const Color(0xff1e6091)
           ..style = PaintingStyle.fill,
         children: [CircleHitbox()],
       );

  final Vector2 velocity;
  final double difficultyModifier;
  final bool isBonus;
  static const double maxSpeed = 900.0;

  @override
  void update(double dt) {
    super.update(dt);
    
    // Geschwindigkeit begrenzen
    final currentSpeed = velocity.length;
    if (currentSpeed > maxSpeed) {
      velocity.normalize();
      velocity.scale(maxSpeed);
    }
    
    position += velocity * dt;
    
    // Sicherheits-Check: Ball innerhalb halten
    if (position.y < 0) {
      position.y = 0;
      velocity.y = velocity.y.abs();
    }
    if (position.x < 0) {
      position.x = 0;
      velocity.x = velocity.x.abs();
    }
    if (position.x > game.width) {
      position.x = game.width;
      velocity.x = -velocity.x.abs();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is PlayArea) {
      if (intersectionPoints.first.y <= 0) {
        velocity.y = -velocity.y;
      } else if (intersectionPoints.first.x <= 0) {
        velocity.x = -velocity.x;
      } else if (intersectionPoints.first.x >= game.width) {
        velocity.x = -velocity.x;
      } else if (intersectionPoints.first.y >= game.height) {
        if (isBonus) {
          add(RemoveEffect(delay: 0.35, onComplete: () {
            game.onBonusBallLost();
          }));
        } else {
          // Nur Leben abziehen wenn nicht unsterblich
          if (!game.isInvincible) {
            final currentScore = game.score;
            add(
              RemoveEffect(
                delay: 0.35,
                onComplete: () {
                  if (game.lives <= 1) {
                    if (currentScore > 0) {
                      HighscoreManager.addScore(currentScore);
                    }
                  }
                  game.loseLife();
                },
              ),
            );
          } else {
            // Unsterblich: Ball einfach entfernen und respawnen
            add(RemoveEffect(delay: 0.35, onComplete: () {
              game.respawnBall();
            }));
          }
        }
      }
    } else if (other is Paddle) {
      velocity.y = -velocity.y;
      velocity.x =
          velocity.x +
          (position.x - other.position.x) / other.size.x * game.width * 0.3;
    } else if (other is Brick) {
      if (position.y < other.position.y - other.size.y / 2) {
        velocity.y = -velocity.y;
      } else if (position.y > other.position.y + other.size.y / 2) {
        velocity.y = -velocity.y;
      } else if (position.x < other.position.x) {
        velocity.x = -velocity.x;
      } else if (position.x > other.position.x) {
        velocity.x = -velocity.x;
      }
      // Level 1: Beschleunigung bei jedem Hit (nur blauer Ball)
      if (game.level == 1 && !isBonus) {
        velocity.setFrom(velocity * difficultyModifier);
      }
      if (!isBonus) {
        game.onBrickDestroyed(other.position);
      }
    }
  }
}
