import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'space_game.dart';
import 'player_ship.dart';
import 'laser.dart';
import 'level_manager.dart';

class Asteroid extends SpriteComponent
    with HasGameReference<SpaceGame>, CollisionCallbacks {
  double _rot = 0;
  int health;
  final int points;
  final String spritePath;
  final Vector2 velocity;

  Asteroid({
    required super.sprite,
    required this.health,
    required this.points,
    required this.spritePath,
    required this.velocity,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    if (spritePath.contains('rock_cracked_lava')) {
      add(PolygonHitbox.relative([
        Vector2(0.40, 0.30),
        Vector2(0.60, 0.28),
        Vector2(0.70, 0.50),
        Vector2(0.65, 0.70),
        Vector2(0.45, 0.72),
        Vector2(0.30, 0.52),
      ], parentSize: size, collisionType: CollisionType.passive));
      add(PolygonHitbox.relative([
        Vector2(0.35, 0.25),
        Vector2(0.65, 0.23),
        Vector2(0.75, 0.50),
        Vector2(0.70, 0.75),
        Vector2(0.40, 0.77),
        Vector2(0.25, 0.52),
      ], parentSize: size, collisionType: CollisionType.inactive, isSolid: true));
    } else if (spritePath.contains('rock_green_spikes')) {
      add(PolygonHitbox.relative([
        Vector2(0.42, 0.35),
        Vector2(0.58, 0.35),
        Vector2(0.65, 0.50),
        Vector2(0.58, 0.65),
        Vector2(0.42, 0.65),
        Vector2(0.35, 0.50),
      ], parentSize: size, collisionType: CollisionType.passive));
      add(PolygonHitbox.relative([
        Vector2(0.38, 0.30),
        Vector2(0.62, 0.30),
        Vector2(0.70, 0.50),
        Vector2(0.62, 0.70),
        Vector2(0.38, 0.70),
        Vector2(0.30, 0.50),
      ], parentSize: size, collisionType: CollisionType.inactive, isSolid: true));
    } else if (spritePath.contains('thruster_nozzle')) {
      add(CircleHitbox(radius: size.x * 0.28, position: size / 2, anchor: Anchor.center, collisionType: CollisionType.passive));
      add(CircleHitbox(radius: size.x * 0.35, position: size / 2, anchor: Anchor.center, collisionType: CollisionType.inactive, isSolid: true));
    } else {
      add(CircleHitbox(radius: size.x * 0.26, position: size / 2, anchor: Anchor.center, collisionType: CollisionType.passive));
      add(CircleHitbox(radius: size.x * 0.33, position: size / 2, anchor: Anchor.center, collisionType: CollisionType.inactive, isSolid: true));
    }
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
    position += velocity * dt;

    _rot += dt * 0.8;
    angle = _rot;

    if (position.x < -size.x - 120 || position.y < -size.y - 120 || position.y > game.size.y + size.y + 120) {
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
      _nextSpawn = LevelManager.currentLevel.spawnRate;
      _spawnAsteroid();
    }
  }

  Future<void> _spawnAsteroid() async {
    final asteroids = LevelManager.currentLevel.asteroids;
    final selectedAsteroid = asteroids[_rng.nextInt(asteroids.length)];

    final String spritePath = 'targets/$selectedAsteroid';
    final double size;
    final int health;
    final int points;

    if (selectedAsteroid.contains('rock_green_spikes')) {
      size = 90.0;
      health = 3;
      points = 0;
    } else if (selectedAsteroid.contains('thruster_nozzle')) {
      size = 70.0;
      health = 2;
      points = 0;
    } else if (selectedAsteroid.contains('rock_cracked_lava')) {
      size = 120.0;
      health = 3;
      points = 2;
    } else {
      size = 84.0;
      health = 2;
      points = 1;
    }

    final Vector2 spawnPos;
    final Vector2 velocity;

    if (LevelManager.currentLevelNumber >= 3 && _rng.nextDouble() < 0.3) {
      final fromTop = _rng.nextBool();
      if (fromTop) {
        spawnPos = Vector2(game.size.x + 80, 80);
        velocity = Vector2(-game.worldSpeed * 0.8, game.worldSpeed * 0.6);
      } else {
        spawnPos = Vector2(game.size.x + 80, game.size.y - 80);
        velocity = Vector2(-game.worldSpeed * 0.8, -game.worldSpeed * 0.6);
      }
    } else {
      final lane = _lanes[_rng.nextInt(_lanes.length)];
      spawnPos = Vector2(game.size.x + 80, lane + _rng.nextDouble() * 40 - 20);
      velocity = Vector2(-game.worldSpeed, 0);
    }

    final sprite = await game.loadSprite(spritePath);
    final asteroid =
        Asteroid(
            sprite: sprite,
            health: health,
            points: points,
            spritePath: spritePath,
            velocity: velocity,
          )
          ..size = Vector2.all(size)
          ..anchor = Anchor.center
          ..position = spawnPos;

    game.add(asteroid);
  }
}
