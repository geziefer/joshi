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
    final shipSprite = await loadSprite('ships/ship_192.png');
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

    _isLoaded = true;
  }

  @override
  void update(double dt) {
    super.update(dt);

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
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    _isDragging = false;
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _isDragging = false;
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
}

class AsteroidSpawner extends Component with HasGameReference<SpaceGame> {
  final _rng = math.Random(7);

  double _timer = 0;
  double _nextSpawn = 0.8;

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
      final base = 0.85 - 0.30 * speedT;
      _nextSpawn = (base + _rng.nextDouble() * 0.25).clamp(0.35, 1.2);

      _spawnAsteroid();
    }
  }

  Future<void> _spawnAsteroid() async {
    final lane = _lanes[_rng.nextInt(_lanes.length)];
    final isBig = _rng.nextDouble() < 0.25;

    final spritePath = isBig
        ? 'targets/tier1_barrel_small.png'
        : 'targets/tier1_beacon_orange.png';

    final sprite = await game.loadSprite(spritePath);

    final size = isBig ? 120.0 : 84.0;
    final asteroid = Asteroid(sprite: sprite)
      ..size = Vector2.all(size)
      ..anchor = Anchor.center
      ..position = Vector2(
        game.size.x + 80,
        lane + _rng.nextDouble() * 22 - 11,
      );

    game.add(asteroid);
  }
}

class Asteroid extends SpriteComponent
    with HasGameReference<SpaceGame>, CollisionCallbacks {
  double _rot = 0;

  Asteroid({required super.sprite});

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
