import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'space_game.dart';
import 'player_ship.dart';
import 'laser.dart';
import 'level_manager.dart';
import 'powerup.dart';

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
    
    add(CircleHitbox(collisionType: CollisionType.passive));
    add(CircleHitbox(radius: size.x * 0.45, position: size / 2, anchor: Anchor.center, collisionType: CollisionType.inactive, isSolid: true));
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
  final Map<String, double> _powerUpTimers = {};
  final Map<String, double> _nextPowerUpSpawns = {};
  final Map<String, bool> _powerUpSpawned = {};

  List<double> get _lanes {
    final h = game.size.y;
    final isLandscape = game.size.x > game.size.y;
    final isMobileLandscape = isLandscape && game.size.y < 500;
    final top = isLandscape ? 100.0 : 140.0;
    final bottom = isLandscape ? h - 100.0 : h - 160.0;
    final laneCount = isMobileLandscape ? 3 : 5;
    final step = (bottom - top) / (laneCount - 1);
    return List.generate(laneCount, (i) => top + step * i);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;
    if (_timer >= _nextSpawn) {
      _timer = 0;
      final isLandscape = game.size.x > game.size.y;
      _nextSpawn = isLandscape ? LevelManager.currentLevel.spawnRate * 1.3 : LevelManager.currentLevel.spawnRate;
      _spawnAsteroid();
    }

    for (var powerUpConfig in LevelManager.currentLevel.powerups) {
      final key = powerUpConfig.sprite;
      _powerUpTimers[key] = (_powerUpTimers[key] ?? 0) + dt;
      
      if (!(_powerUpSpawned[key] ?? false)) {
        final nextSpawn = _nextPowerUpSpawns[key] ?? powerUpConfig.spawnInterval[0];
        if (_powerUpTimers[key]! >= nextSpawn) {
          _powerUpTimers[key] = 0;
          _powerUpSpawned[key] = true;
          _spawnPowerUp(powerUpConfig);
        }
      }
    }
  }

  void resetPowerUpTimer() {
    for (var powerUpConfig in LevelManager.currentLevel.powerups) {
      final key = powerUpConfig.sprite;
      _powerUpSpawned[key] = false;
      final min = powerUpConfig.spawnInterval[0];
      final max = powerUpConfig.spawnInterval[1];
      _nextPowerUpSpawns[key] = min + _rng.nextDouble() * (max - min);
    }
  }

  void resetAllPowerUpTimers() {
    _powerUpTimers.clear();
    _nextPowerUpSpawns.clear();
    _powerUpSpawned.clear();
    
    for (var powerUpConfig in LevelManager.currentLevel.powerups) {
      final key = powerUpConfig.sprite;
      _powerUpTimers[key] = 0;
      final min = powerUpConfig.spawnInterval[0];
      final max = powerUpConfig.spawnInterval[1];
      _nextPowerUpSpawns[key] = min + _rng.nextDouble() * (max - min);
      _powerUpSpawned[key] = false;
    }
  }

  Future<void> _spawnAsteroid() async {
    final asteroids = LevelManager.currentLevel.asteroids;
    final selectedAsteroid = asteroids[_rng.nextInt(asteroids.length)];

    final String spritePath = 'targets/$selectedAsteroid';
    final double baseSize;
    final int health;
    final int points;

    if (selectedAsteroid.contains('rock_green_spikes')) {
      baseSize = 90.0;
      health = 3;
      points = 0;
    } else if (selectedAsteroid.contains('thruster_nozzle')) {
      baseSize = 70.0;
      health = 2;
      points = 0;
    } else if (selectedAsteroid.contains('rock_cracked_lava')) {
      baseSize = 120.0;
      health = 3;
      points = 2;
    } else {
      baseSize = 84.0;
      health = 2;
      points = 1;
    }

    final isMobile = game.size.x < 600;
    final isLandscape = game.size.x > game.size.y;
    final size = isMobile ? baseSize * 0.65 : (isLandscape && game.size.y < 500 ? baseSize * 0.4 : baseSize);

    final Vector2 spawnPos;
    final Vector2 velocity;

    if (LevelManager.currentLevelNumber >= 3 && _rng.nextDouble() < 0.3) {
      final fromTop = _rng.nextBool();
      if (fromTop) {
        spawnPos = Vector2(game.size.x + 80, 80);
        velocity = Vector2(-game.worldSpeed * 1.4, game.worldSpeed * 1.0);
      } else {
        spawnPos = Vector2(game.size.x + 80, game.size.y - 80);
        velocity = Vector2(-game.worldSpeed * 1.4, -game.worldSpeed * 1.0);
      }
    } else if (LevelManager.currentLevelNumber >= 4 && _rng.nextDouble() < 0.2) {
      final lane = _lanes[_rng.nextInt(_lanes.length)];
      spawnPos = Vector2(game.size.x + 80, lane + _rng.nextDouble() * 40 - 20);
      velocity = Vector2(-game.worldSpeed * 1.3, 0);
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

  Future<void> _spawnPowerUp(PowerUpConfig powerUpConfig) async {
    final lane = _lanes[_rng.nextInt(_lanes.length)];

    final sprite = await game.loadSprite('targets/${powerUpConfig.sprite}');
    final powerUp = PowerUp(
      sprite: sprite,
      velocity: Vector2(-game.worldSpeed * 0.7, 0),
      type: powerUpConfig.type,
      health: powerUpConfig.health,
    )
      ..size = Vector2.all(60)
      ..anchor = Anchor.center
      ..position = Vector2(game.size.x + 80, lane);

    game.add(powerUp);
  }
}
