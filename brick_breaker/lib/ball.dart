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
  }) : _originalColor = isBonus ? const Color(0xfff94144) : const Color(0xff1e6091),
       super(
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
  int _brickHitsWithoutPaddle = 0;
  final Color _originalColor;
  bool canCollectPowerUp = true;
  bool _isRemoving = false;

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
        if (_isRemoving) return;
        _isRemoving = true;
        
        if (isBonus) {
          add(RemoveEffect(delay: 0.35, onComplete: () {
            game.onBonusBallLost();
          }));
        } else {
          // Hauptball durchgefallen
          final wasInvincible = game.isInvincible;
          if (!wasInvincible) {
            // Nicht unsterblich: Leben abziehen
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
            // Unsterblich: kein Leben abziehen, aber respawnen
            add(RemoveEffect(delay: 0.35, onComplete: () {
              game.respawnBallWithoutPowerUpCollection();
            }));
          }
        }
      }
    } else if (other is Paddle) {
      velocity.y = -velocity.y;
      velocity.x =
          velocity.x +
          (position.x - other.position.x) / other.size.x * game.width * 0.3;
      
      // Counter zurücksetzen und Farbe zurücksetzen
      _brickHitsWithoutPaddle = 0;
      paint.color = _originalColor;
      canCollectPowerUp = true;
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
      
      // Level 4+: Brick-Hit Counter für alle Bälle (außer unzerstörbare Bricks)
      if (game.level >= 4 && !other.isIndestructible) {
        _brickHitsWithoutPaddle++;
        
        if (_brickHitsWithoutPaddle == 2) {
          // Gelb
          paint.color = const Color(0xffffff00);
        } else if (_brickHitsWithoutPaddle == 3) {
          // Orange
          paint.color = const Color(0xffffa500);
        } else if (_brickHitsWithoutPaddle >= 4) {
          // Kaputt gehen
          if (_isRemoving) return;
          _isRemoving = true;
          
          if (isBonus) {
            // Bonus Ball: einfach entfernen
            add(RemoveEffect(delay: 0.1, onComplete: () {
              game.onBonusBallLost();
            }));
          } else {
            // Haupt Ball: entfernen und neuen blauen Ball spawnen
            add(RemoveEffect(delay: 0.1, onComplete: () {
              game.respawnBallWithoutPowerUpCollection();
            }));
          }
        }
      }
    }
  }
}
