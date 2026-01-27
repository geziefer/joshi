import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flame/parallax.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SpaceGame extends FlameGame
    with KeyboardEvents, TapCallbacks, DragCallbacks, HasCollisionDetection {
  // --- Tuning ---
  final double shipX = 110;
  final double shipSize = 96; // try 96..128
  final double shipSpeed = 420; // px/s
  final double screenMargin = 40;

  // World speed for scrolling objects
  double worldSpeed = 260; // px/s
  double _elapsed = 0;

  // Keyboard state
  bool upPressed = false;
  bool downPressed = false;

  late final ParallaxComponent parallax;
  late final PlayerShip ship;
  late final AsteroidSpawner spawner;
  bool _isLoaded = false;
  bool isGameOver = false;
  int score = 0;
  int lives = 3;
  late final TextComponent scoreText;
  final List<SpriteComponent> lifeIcons = [];

  @override
  Future<void> onLoad() async {
    // Parallax background (seamless tiles)
    parallax = await loadParallaxComponent(
      [
        ParallaxImageData('backgrounds/parallax_nebula_1024x512.png'),
        ParallaxImageData('backgrounds/parallax_stars_far_1024x512.png'),
        ParallaxImageData('backgrounds/parallax_stars_near_1024x512.png'),
      ],
      baseVelocity: Vector2(30, 0),
      velocityMultiplierDelta: Vector2(1.6, 1.0),
      repeat: ImageRepeat.repeat,
    );
    add(parallax);

    // Ship
    final shipSprite = await loadSprite('ships/ship_256.png');
    ship =
        PlayerShip(
            sprite: shipSprite,
            fixedX: shipX,
            speed: shipSpeed,
            screenMargin: screenMargin,
          )
          ..size = Vector2.all(shipSize)
          ..position = Vector2(shipX, size.y / 2)
          ..anchor = Anchor.center;
    ship.updateBounds(size);
    add(ship);

    // Spawner (asteroids)
    spawner = AsteroidSpawner();
    add(spawner);

    // Score display
    scoreText = TextComponent(
      text: 'Score: 0',
      position: Vector2(20, 20),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(scoreText);

    // Life icons
    for (int i = 0; i < 3; i++) {
      final lifeIcon = SpriteComponent(
        sprite: shipSprite,
        size: Vector2.all(64),
        position: Vector2(40 + i * 80.0, size.y - 60),
        anchor: Anchor.center,
      );
      lifeIcons.add(lifeIcon);
      add(lifeIcon);
    }

    _isLoaded = true;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isGameOver) return;

    // Slight difficulty ramp over time (optional)
    _elapsed += dt;
    if (_elapsed > 1) {
      _elapsed = 0;
      worldSpeed = (worldSpeed + 2).clamp(260, 520);
    }

    // Ship input
    double dir = 0;
    if (upPressed) dir -= 1;
    if (downPressed) dir += 1;

    ship.move(dir, dt);

    // Keep X fixed
    ship.position.x = shipX;
  }

  void loseLife() {
    if (lives > 0) {
      lives--;
      if (lives < lifeIcons.length) {
        lifeIcons[lives].removeFromParent();
      }
      if (lives <= 0) {
        gameOver();
      }
    }
  }

  void addScore(int points) {
    score += points;
    scoreText.text = 'Score: $score';
  }

  void gameOver() {
    isGameOver = true;
    overlays.add('gameOver');
  }

  void restart() {
    isGameOver = false;
    overlays.remove('gameOver');
    worldSpeed = 260;
    _elapsed = 0;
    score = 0;
    lives = 3;
    scoreText.text = 'Score: 0';

    // Remove all asteroids
    children.whereType<Asteroid>().toList().forEach(
      (a) => a.removeFromParent(),
    );

    // Reset life icons
    for (var icon in lifeIcons) {
      icon.removeFromParent();
    }
    lifeIcons.clear();

    // Re-add life icons
    loadSprite('ships/ship_256.png').then((shipSprite) {
      for (int i = 0; i < 3; i++) {
        final lifeIcon = SpriteComponent(
          sprite: shipSprite,
          size: Vector2.all(64),
          position: Vector2(40 + i * 80.0, size.y - 60),
          anchor: Anchor.center,
        );
        lifeIcons.add(lifeIcon);
        add(lifeIcon);
      }
    });

    // Reset ship
    ship.position = Vector2(shipX, size.y / 2);
    ship.opacity = 1.0;
    add(ship);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (_isLoaded) {
      ship.updateBounds(size);
      ship.position.x = shipX;
    }
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    upPressed = keysPressed.contains(LogicalKeyboardKey.arrowUp);
    downPressed = keysPressed.contains(LogicalKeyboardKey.arrowDown);
    return KeyEventResult.handled;
  }

  bool _isDragging = false;

  @override
  void onTapDown(TapDownEvent event) {
    if (ship.containsPoint(event.localPosition)) {
      _isDragging = true;
    } else {
      ship.startShooting();
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    _isDragging = false;
    ship.stopShooting();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _isDragging = false;
    ship.stopShooting();
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (ship.containsPoint(event.localPosition)) {
      _isDragging = true;
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (_isDragging) {
      ship.setTargetY(event.localEndPosition.y);
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _isDragging = false;
  }
}

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

  PlayerShip({
    required Sprite sprite,
    required this.fixedX,
    required this.speed,
    required this.screenMargin,
  }) : super(sprite: sprite);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_shooting) {
      _shootTimer += dt;
      if (_shootTimer >= _shootDelay) {
        _shootTimer = 0;
        _fireLaser();
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
    final laser = Laser(position: position.clone() + Vector2(size.x / 2, 0));
    game.add(laser);
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
      // Respawn ship
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!game.isGameOver) {
          position = Vector2(fixedX, game.size.y / 2);
          game.add(this);
        }
      });
    }
  }
}

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

      // Spawn interval becomes slightly shorter as speed increases
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

    if (rand < 0.25) {
      // Debris (25%)
      spritePath = 'targets/tier1_thruster_nozzle.png';
      size = 70.0;
      health = 2;
      points = 0;
    } else if (rand < 0.60) {
      // Tier 2 (35%)
      spritePath = 'targets/tier2_rock_cracked_lava.png';
      size = 120.0;
      health = 3;
      points = 2;
    } else {
      // Tier 1 (40%)
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

class Laser extends PositionComponent
    with HasGameReference<SpaceGame>, CollisionCallbacks {
  final double speed = 600;

  Laser({required Vector2 position})
    : super(position: position, size: Vector2(20, 4), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), paint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.x += speed * dt;
    if (position.x > game.size.x + 50) removeFromParent();
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Asteroid) {
      removeFromParent();
    }
  }
}

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
      removeFromParent();
      other.explode();
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
