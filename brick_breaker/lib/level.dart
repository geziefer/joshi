import 'dart:convert';
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:practice_game/brick.dart';
import 'package:practice_game/main.dart';
import 'package:practice_game/level_manager.dart';

class LevelData {
  final int level;
  final int columns;
  final int rows;
  final int hitsRequired;
  final double brickWidthMultiplier;
  final double brickHeightMultiplier;
  final int indestructibleCount;
  final bool isMoving;
  final double moveSpeedBase;
  final double moveSpeedIncrement;
  final String ballSpeedFormula;
  final int yellowPowerUpMin;
  final int yellowPowerUpMax;
  final bool greenPowerUpEnabled;
  final bool heartPowerUpEnabled;
  final double ballSpeedModifier;
  final bool chaosMode;

  LevelData.fromJson(Map<String, dynamic> json)
    : level = json['level'],
      columns = json['columns'],
      rows = json['rows'],
      hitsRequired = json['hitsRequired'],
      brickWidthMultiplier = json['brickWidthMultiplier'],
      brickHeightMultiplier = json['brickHeightMultiplier'],
      indestructibleCount = json['indestructibleCount'],
      isMoving = json['isMoving'],
      moveSpeedBase = json['moveSpeedBase'],
      moveSpeedIncrement = json['moveSpeedIncrement'],
      ballSpeedFormula = json['ballSpeedFormula'],
      yellowPowerUpMin = json['yellowPowerUpMin'],
      yellowPowerUpMax = json['yellowPowerUpMax'],
      greenPowerUpEnabled = json['greenPowerUpEnabled'],
      heartPowerUpEnabled = json['heartPowerUpEnabled'],
      ballSpeedModifier = json['ballSpeedModifier'],
      chaosMode = json['chaosMode'] ?? false;
}

class LevelConfig {
  static Map<int, LevelData>? _levels;

  static Future<void> loadLevels() async {
    try {
      final data = await LevelManager.loadLevelsFromFirebase();
      _levels = {};
      for (var levelJson in data['levels']) {
        final levelData = LevelData.fromJson(levelJson);
        _levels![levelData.level] = levelData;
      }
    } catch (e) {
      final jsonString = await rootBundle.loadString('assets/levels.json');
      final data = json.decode(jsonString);
      _levels = {};
      for (var levelJson in data['levels']) {
        final levelData = LevelData.fromJson(levelJson);
        _levels![levelData.level] = levelData;
      }
    }
  }

  static LevelData _getLevel(int level) {
    return _levels![level] ?? _levels![5]!;
  }

  static double getBallSpeed(int level, double height) {
    final levelData = _getLevel(level);
    final formula = levelData.ballSpeedFormula;
    return _evaluateFormula(formula, height);
  }

  static double _evaluateFormula(String formula, double height) {
    formula = formula.replaceAll('height', height.toString());
    final parts = formula.split('/');
    return double.parse(parts[0].trim()) / double.parse(parts[1].trim());
  }

  static int getYellowPowerUpInterval(int level, math.Random rand) {
    final levelData = _getLevel(level);
    if (levelData.yellowPowerUpMax == 0) return 999999;
    return rand.nextInt(
          levelData.yellowPowerUpMax - levelData.yellowPowerUpMin + 1,
        ) +
        levelData.yellowPowerUpMin;
  }

  static double getGreenPowerUpSpawnTime(math.Random rand) {
    return 15.0 + (rand.nextInt(10) * 1.0);
  }

  static double getHeartPowerUpSpawnTime(math.Random rand) {
    return 30.0 + (rand.nextInt(15) * 1.0);
  }

  static double getBallSpeedModifier(int level) {
    return _getLevel(level).ballSpeedModifier;
  }

  static List<Brick> buildLevel(
    int level,
    double width,
    double height,
    math.Random rand,
  ) {
    final levelData = _getLevel(level);
    final levelColor = brickColors[(level - 1) % brickColors.length];

    final brickW =
        (width - ((levelData.columns + 1) * brickGutter)) / levelData.columns;
    final brickH = brickHeight * levelData.brickHeightMultiplier;

    final indestructiblePositions = _generateIndestructiblePositions(
      levelData.columns,
      levelData.rows,
      levelData.indestructibleCount,
      rand,
    );

    if (levelData.chaosMode) {
      return [
        for (var i = 0; i < levelData.columns; i++)
          for (var j = 0; j < levelData.rows; j++)
            () {
              final isIndestructible = indestructiblePositions.contains(
                j * levelData.columns + i,
              );
              final hits = isIndestructible ? 1 : rand.nextInt(4) + 1;
              final color = hits >= 2
                  ? _getContrastColor(levelColor)
                  : levelColor;
              // Unzerstörbare Bricks stehen eher still (20% Chance zu bewegen)
              final moveSpeed = isIndestructible
                  ? (rand.nextDouble() < 0.2 ? levelData.moveSpeedBase : 0.0)
                  : (rand.nextBool()
                        ? levelData.moveSpeedBase + (rand.nextDouble() * 100)
                        : 0.0);
              return Brick(
                Vector2(
                  (i + 0.5) * brickW + (i + 1) * brickGutter,
                  (j + 2.0) * brickH + (j + 1) * brickGutter,
                ),
                color,
                hitsRequired: hits,
                customSize: Vector2(brickW, brickH),
                isMoving: moveSpeed > 0,
                moveSpeed: moveSpeed,
                isIndestructible: isIndestructible,
              );
            }(),
      ];
    }

    final color = levelData.hitsRequired >= 2
        ? _getContrastColor(levelColor)
        : levelColor;
    return [
      for (var i = 0; i < levelData.columns; i++)
        for (var j = 0; j < levelData.rows; j++)
          Brick(
            Vector2(
              (i + 0.5) * brickW + (i + 1) * brickGutter,
              (j + 2.0) * brickH + (j + 1) * brickGutter,
            ),
            color,
            hitsRequired: levelData.hitsRequired,
            customSize: Vector2(brickW, brickH),
            isMoving: levelData.isMoving,
            moveSpeed:
                levelData.moveSpeedBase + (j * levelData.moveSpeedIncrement),
            isIndestructible: indestructiblePositions.contains(
              j * levelData.columns + i,
            ),
          ),
    ];
  }

  static Set<int> _generateIndestructiblePositions(
    int cols,
    int rows,
    int count,
    math.Random rand,
  ) {
    if (count == 0) return {};

    final allPositions = <int>[];
    final lastRowPositions = <int>[];

    for (var i = 0; i < cols; i++) {
      for (var j = 0; j < rows; j++) {
        final pos = j * cols + i;
        if (j == rows - 1) {
          lastRowPositions.add(pos);
        } else {
          allPositions.add(pos);
        }
      }
    }

    allPositions.shuffle(rand);
    lastRowPositions.shuffle(rand);

    final indestructiblePositions = <int>{};

    // Maximal 1 unzerstörbarer Brick in der untersten Reihe
    if (lastRowPositions.isNotEmpty && rand.nextBool()) {
      for (final pos in lastRowPositions) {
        if (indestructiblePositions.length >= count) break;

        final row = pos ~/ cols;
        final col = pos % cols;
        var adjacentCount = 0;

        final neighbors = [
          (row - 1) * cols + col,
          (row + 1) * cols + col,
          row * cols + (col - 1),
          row * cols + (col + 1),
        ];

        for (final neighbor in neighbors) {
          if (indestructiblePositions.contains(neighbor)) {
            adjacentCount++;
          }
        }

        if (adjacentCount == 0) {
          indestructiblePositions.add(pos);
          break;
        }
      }
    }

    // Rest aus den anderen Reihen
    for (final pos in allPositions) {
      if (indestructiblePositions.length >= count) break;

      final row = pos ~/ cols;
      final col = pos % cols;
      var adjacentCount = 0;

      final neighbors = [
        (row - 1) * cols + col,
        (row + 1) * cols + col,
        row * cols + (col - 1),
        row * cols + (col + 1),
      ];

      for (final neighbor in neighbors) {
        if (indestructiblePositions.contains(neighbor)) {
          adjacentCount++;
        }
      }

      if (adjacentCount == 0) {
        indestructiblePositions.add(pos);
      }
    }

    return indestructiblePositions;
  }

  static Color _getContrastColor(Color baseColor) {
    return Color.fromRGBO(
      ((baseColor.r * 255.0).round() * 0.85).toInt().clamp(0, 255),
      ((baseColor.g * 255.0).round() * 0.85).toInt().clamp(0, 255),
      ((baseColor.b * 255.0).round() * 0.85).toInt().clamp(0, 255),
      1.0,
    );
  }
}
