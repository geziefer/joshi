import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'player_ship.dart';
import 'asteroid.dart';

class SpaceGame extends FlameGame
    with KeyboardEvents, TapCallbacks, DragCallbacks, HasCollisionDetection {
  SpaceGame({required this.onGameOver});
  final VoidCallback onGameOver;

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
    onGameOver();
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
