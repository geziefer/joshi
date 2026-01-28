import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'space_game.dart';
import 'player_ship.dart';
import 'laser.dart';

class Asteroid extends SpriteComponent
    with HasGameReference<SpaceGame>, CollisionCallbacks {
  double _rot = 0;
  int health;
  final int points;

  Asteroid({required super.sprite, required this.health, required this.points});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is PlayerShip) {
      if (other.isInvincible) {
        removeFromParent();
      } else {
        removeFromParent();
        other.explode();
      }
    } else if (other is Laser) {
      health--;
      if (health <= 0) {
        game.addScore(points);
        removeFromParent();
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.x -= game.worldSpeed * dt;

    _rot += dt * 0.8;
    angle = _rot;

    if (position.x < -size.x - 120) {
      removeFromParent();
    }
  }
}

class AsteroidSpawner extends Component with HasGameReference<SpaceGame> {
  final _rng = math.Random(7);

  double _timer = 0;
  double _nextSpawn = 0.3;

  List<double> get _lanes {
    final h = game.size.y;
    final top = 80.0;
    final bottom = h - 80.0;
    final step = (bottom - top) / 4;
    return List.generate(5, (i) => top + step * i);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;
    if (_timer >= _nextSpawn) {
      _timer = 0;

      final speedT = (game.worldSpeed - 260) / (520 - 260);
      final base = 0.4 - 0.15 * speedT;
      _nextSpawn = (base + _rng.nextDouble() * 0.15).clamp(0.2, 0.6);

      _spawnAsteroid();
    }
  }

  Future<void> _spawnAsteroid() async {
    final lane = _lanes[_rng.nextInt(_lanes.length)];
    final rand = _rng.nextDouble();

    final String spritePath;
    final double size;
    final int health;
    final int points;

    if (rand < 0.10) {
      spritePath = 'targets/tier4_rock_green_spikes.png';
      size = 90.0;
      health = 3;
      points = 0;
    } else if (rand < 0.30) {
      spritePath = 'targets/tier1_thruster_nozzle.png';
      size = 70.0;
      health = 2;
      points = 0;
    } else if (rand < 0.60) {
      spritePath = 'targets/tier2_rock_cracked_lava.png';
      size = 120.0;
      health = 3;
      points = 2;
    } else {
      spritePath = 'targets/tier1_rock_small.png';
      size = 84.0;
      health = 2;
      points = 1;
    }

    final sprite = await game.loadSprite(spritePath);
    final asteroid = Asteroid(sprite: sprite, health: health, points: points)
      ..size = Vector2.all(size)
      ..anchor = Anchor.center
      ..position = Vector2(
        game.size.x + 80,
        lane + _rng.nextDouble() * 40 - 20,
      );

    game.add(asteroid);
  }
}
