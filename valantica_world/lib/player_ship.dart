import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'space_game.dart';
import 'ship_debris.dart';
import 'laser.dart';

class PlayerShip extends SpriteComponent
    with HasGameReference<SpaceGame>, CollisionCallbacks {
  final double fixedX;
  final double speed;
  final double screenMargin;

  double _minY = 0;
  double _maxY = 0;
  bool _shooting = false;
  double _shootTimer = 0;
  final double _shootDelay = 0.25;
  bool isInvincible = false;
  double _invincibleTimer = 0;
  bool _powerUpActive = false;
  double _powerUpTimer = 0;

  PlayerShip({
    required Sprite sprite,
    required this.fixedX,
    required this.speed,
    required this.screenMargin,
  }) : super(sprite: sprite);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox(radius: size.x * 0.30, position: size / 2, anchor: Anchor.center));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_shooting) {
      _shootTimer += dt;
      final delay = _powerUpActive ? 0.08 : _shootDelay;
      if (_shootTimer >= delay) {
        _shootTimer = 0;
        _fireLaser();
      }
    }
    
    if (isInvincible) {
      _invincibleTimer += dt;
      if (_invincibleTimer >= 1.0) {
        isInvincible = false;
        _invincibleTimer = 0;
        opacity = 1.0;
      } else {
        opacity = 0.5 + 0.5 * ((_invincibleTimer * 10) % 1);
      }
    }

    if (_powerUpActive) {
      _powerUpTimer += dt;
      if (_powerUpTimer >= 5.0) {
        _powerUpActive = false;
        _powerUpTimer = 0;
      }
    }
  }

  void updateBounds(Vector2 screenSize) {
    final half = size.y / 2;
    _minY = screenMargin + half;
    _maxY = screenSize.y - screenMargin - half;
    position.y = position.y.clamp(_minY, _maxY);
  }

  void move(double direction, double dt) {
    if (direction == 0) return;
    position.y = (position.y + direction * speed * dt).clamp(_minY, _maxY);
    position.x = fixedX;
  }

  void setTargetY(double y) {
    position.y = y.clamp(_minY, _maxY);
  }

  void startShooting() {
    _shooting = true;
    _shootTimer = _shootDelay;
  }

  void stopShooting() {
    _shooting = false;
  }

  void _fireLaser() {
    final laserSize = _powerUpActive ? Vector2(30, 8) : Vector2(20, 4);
    final laser = Laser(
      position: position.clone() + Vector2(size.x / 2, 0),
      laserSize: laserSize,
    );
    game.add(laser);
  }

  void activatePowerUp() {
    _powerUpActive = true;
    _powerUpTimer = 0;
    if (!_shooting) {
      startShooting();
    }
    Future.delayed(const Duration(seconds: 5), () {
      game.onPowerUpExpired();
    });
  }

  void explode() {
    final rng = math.Random();
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * math.pi + rng.nextDouble() * 0.5;
      final speed = 150 + rng.nextDouble() * 100;
      final particle = ShipDebris(
        position: position.clone(),
        velocity: Vector2(math.cos(angle), math.sin(angle)) * speed,
        size: 8 + rng.nextDouble() * 8,
      );
      game.add(particle);
    }
    removeFromParent();
    game.loseLife();

    if (game.lives > 0) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!game.isGameOver) {
          position = Vector2(fixedX, game.size.y / 2);
          isInvincible = true;
          _invincibleTimer = 0;
          game.add(this);
        }
      });
    }
  }
}
