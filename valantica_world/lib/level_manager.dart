import 'dart:convert';
import 'package:flutter/services.dart';

class LevelConfig {
  final int id;
  final String name;
  final double duration;
  final double worldSpeed;
  final double spawnRate;
  final List<String> asteroids;
  final List<PowerUpConfig> powerups;

  LevelConfig({
    required this.id,
    required this.name,
    required this.duration,
    required this.worldSpeed,
    required this.spawnRate,
    required this.asteroids,
    required this.powerups,
  });

  factory LevelConfig.fromJson(Map<String, dynamic> json) {
    return LevelConfig(
      id: json['id'],
      name: json['name'],
      duration: (json['duration'] as num).toDouble(),
      worldSpeed: (json['worldSpeed'] as num).toDouble(),
      spawnRate: (json['spawnRate'] as num).toDouble(),
      asteroids: List<String>.from(json['asteroids']),
      powerups: (json['powerups'] as List? ?? [])
          .map((p) => PowerUpConfig.fromJson(p))
          .toList(),
    );
  }
}

class PowerUpConfig {
  final String sprite;
  final String type;
  final int health;
  final List<double> spawnInterval;

  PowerUpConfig({
    required this.sprite,
    required this.type,
    required this.health,
    required this.spawnInterval,
  });

  factory PowerUpConfig.fromJson(Map<String, dynamic> json) {
    return PowerUpConfig(
      sprite: json['sprite'],
      type: json['type'],
      health: json['health'],
      spawnInterval: List<double>.from(
        (json['spawnInterval'] as List).map((e) => (e as num).toDouble()),
      ),
    );
  }
}

class LevelManager {
  static List<LevelConfig> _levels = [];
  static int _currentLevelIndex = 9;

  static Future<void> loadLevels() async {
    final jsonString = await rootBundle.loadString('assets/json/levels.json');
    final jsonData = json.decode(jsonString);
    _levels = (jsonData['levels'] as List)
        .map((level) => LevelConfig.fromJson(level))
        .toList();
  }

  static LevelConfig get currentLevel => _levels[_currentLevelIndex];

  static bool get hasNextLevel => _currentLevelIndex < _levels.length - 1;

  static void nextLevel() {
    if (hasNextLevel) _currentLevelIndex++;
  }

  static void reset() {
    _currentLevelIndex = 0;
  }

  static int get currentLevelNumber => _currentLevelIndex + 1;
}
