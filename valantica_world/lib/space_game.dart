import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'player_ship.dart';
import 'asteroid.dart';
import 'level_manager.dart';
import 'laser.dart';

class SpaceGame extends FlameGame
    with KeyboardEvents, TapCallbacks, DragCallbacks, HasCollisionDetection {
  SpaceGame({required this.onGameOver, required this.onLevelComplete});
  final VoidCallback onGameOver;
  final VoidCallback onLevelComplete;

  // --- Tuning ---
  double shipX = 110;
  double shipSize = 96;
  final double shipSpeed = 420;
  final double screenMargin = 40;

  // World speed for scrolling objects
  double worldSpeed = 260; // px/s
  double _elapsed = 0;
  double _levelTimer = 0;

  // Keyboard state
  bool upPressed = false;
  bool downPressed = false;
  bool _spacePressed = false;

  late ParallaxComponent parallax;
  late final PlayerShip ship;
  late final AsteroidSpawner spawner;
  bool _isLoaded = false;
  bool isGameOver = false;
  int score = 0;
  int lives = 3;
  late final TextComponent scoreText;
  late final TextComponent levelText;
  final List<SpriteComponent> lifeIcons = [];

  @override
  Future<void> onLoad() async {
    // Parallax background (seamless tiles)
    await _loadParallaxForLevel(LevelManager.currentLevelNumber);
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

    // Level display
    levelText = TextComponent(
      text: 'Level ${LevelManager.currentLevelNumber}',
      position: Vector2(size.x / 2, 20),
      anchor: Anchor.topCenter,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(levelText);

    // Life icons
    for (int i = 0; i < 3; i++) {
      final lifeIcon = SpriteComponent(
        sprite: shipSprite,
        size: Vector2.all(80),
        position: Vector2(size.x - 50 - i * 95.0, 70),
        anchor: Anchor.center,
      );
      lifeIcon.paint.colorFilter = const ColorFilter.mode(
        Color(0xFFFF6666),
        BlendMode.modulate,
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

    _levelTimer += dt;
    if (_levelTimer >= LevelManager.currentLevel.duration) {
      levelComplete();
      return;
    }

    _elapsed += dt;
    if (_elapsed > 1) {
      _elapsed = 0;
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

  void activatePowerUp() {
    ship.activatePowerUp();
  }

  void addLife() {
    if (lives < 3) {
      final shipSprite = ship.sprite;
      if (shipSprite != null) {
        final lifeIcon = SpriteComponent(
          sprite: shipSprite,
          size: Vector2.all(80),
          position: Vector2(size.x - 50 - lives * 95.0, 70),
          anchor: Anchor.center,
        );
        lifeIcon.paint.colorFilter = const ColorFilter.mode(
          Color(0xFFFF6666),
          BlendMode.modulate,
        );
        lifeIcons.add(lifeIcon);
        add(lifeIcon);
        lives++;
      }
    }
  }

  void onPowerUpExpired() {
    spawner.resetPowerUpTimer();
  }

  void gameOver() {
    isGameOver = true;
    onGameOver();
  }

  void levelComplete() {
    isGameOver = true;
    ship.stopShooting();
    onLevelComplete();
  }

  Future<void> _loadParallaxForLevel(int level) async {
    final levelStr = level.toString().padLeft(2, '0');
    String theme;

    switch (level) {
      case 1:
        theme = 'blue_nebula';
        break;
      case 2:
        theme = 'purple_mist';
        break;
      case 3:
        theme = 'teal_clouds';
        break;
      case 4:
        theme = 'red_dust';
        break;
      case 5:
        theme = 'green_aurora';
        break;
      case 6:
        theme = 'ice_blue';
        break;
      case 7:
        theme = 'golden_void';
        break;
      case 8:
        theme = 'magenta_waves';
        break;
      case 9:
        theme = 'deep_space';
        break;
      case 10:
        theme = 'storm_blue';
        break;
      default:
        theme = 'blue_nebula';
    }

    final prefix = 'level_${levelStr}_$theme';
    parallax = await loadParallaxComponent(
      [
        ParallaxImageData('backgrounds/${prefix}_parallax_nebula_1024x512.png'),
        ParallaxImageData(
          'backgrounds/${prefix}_parallax_stars_far_1024x512.png',
        ),
        ParallaxImageData(
          'backgrounds/${prefix}_parallax_stars_near_1024x512.png',
        ),
      ],
      baseVelocity: Vector2(30, 0),
      velocityMultiplierDelta: Vector2(1.6, 1.0),
      repeat: ImageRepeat.repeat,
    );
  }

  void loadLevel() async {
    worldSpeed = LevelManager.currentLevel.worldSpeed;
    _levelTimer = 0;
    levelText.text = 'Level ${LevelManager.currentLevelNumber}';

    // Remove all asteroids
    children.whereType<Asteroid>().toList().forEach(
      (a) => a.removeFromParent(),
    );

    // Remove all lasers
    children.whereType<Laser>().toList().forEach((l) => l.removeFromParent());

    // Reset ship
    if (!ship.isMounted) {
      add(ship);
    }
    ship.position = Vector2(shipX, size.y / 2);
    ship.isInvincible = false;
    ship.opacity = 1.0;

    // Reset power-up timers
    spawner.resetAllPowerUpTimers();

    // Update background for new level
    remove(parallax);
    await _loadParallaxForLevel(LevelManager.currentLevelNumber);
    parallax.priority = -1;
    add(parallax);
  }

  void restart() {
    isGameOver = false;
    overlays.remove('gameOver');
    _elapsed = 0;
    _levelTimer = 0;
    score = 0;
    lives = 3;
    scoreText.text = 'Score: 0';
    loadLevel();

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
          size: Vector2.all(80),
          position: Vector2(size.x - 50 - i * 95.0, 70),
          anchor: Anchor.center,
        );
        lifeIcon.paint.colorFilter = const ColorFilter.mode(
          Color(0xFFFF6666),
          BlendMode.modulate,
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
      final isMobile = size.x < 600;
      if (isMobile) {
        shipX = size.x * 0.15;
        shipSize = 64;
        ship.size = Vector2.all(shipSize);
      } else {
        shipX = 110;
        shipSize = 96;
        ship.size = Vector2.all(shipSize);
      }
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
    
    final spacePressed = keysPressed.contains(LogicalKeyboardKey.space);
    if (spacePressed && !_spacePressed) {
      startShooting();
    } else if (!spacePressed && _spacePressed) {
      stopShooting();
    }
    _spacePressed = spacePressed;
    
    return KeyEventResult.handled;
  }

  void setUpPressed(bool pressed) => upPressed = pressed;
  void setDownPressed(bool pressed) => downPressed = pressed;
  void startShooting() {
    if (!isGameOver) ship.startShooting();
  }

  void stopShooting() => ship.stopShooting();

  bool _isDragging = false;

  @override
  void onTapDown(TapDownEvent event) {
    if (isGameOver) return;
    if (ship.containsPoint(event.localPosition)) {
      _isDragging = true;
    } else {
      ship.startShooting();
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (!_isDragging) {
      ship.stopShooting();
    }
    _isDragging = false;
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    ship.stopShooting();
    _isDragging = false;
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (isGameOver) return;
    if (ship.containsPoint(event.localPosition)) {
      _isDragging = true;
    } else {
      ship.startShooting();
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
    ship.stopShooting();
    _isDragging = false;
  }
}
