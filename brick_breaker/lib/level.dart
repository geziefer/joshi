import 'dart:convert';
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:practice_game/brick.dart';
import 'package:practice_game/main.dart';

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
        ballSpeedModifier = json['ballSpeedModifier'];
}

class LevelConfig {
  static Map<int, LevelData>? _levels;

  static Future<void> loadLevels() async {
    final jsonString = await rootBundle.loadString('assets/levels.json');
    final data = json.decode(jsonString);
    _levels = {};
    for (var levelJson in data['levels']) {
      final levelData = LevelData.fromJson(levelJson);
      _levels![levelData.level] = levelData;
    }
  }

  static LevelData _getLevel(int level) {
    return _levels![level] ?? _levels![4]!;
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
    return rand.nextInt(levelData.yellowPowerUpMax - levelData.yellowPowerUpMin + 1) + levelData.yellowPowerUpMin;
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

  static List<Brick> buildLevel(int level, double width, double height, math.Random rand) {
    final levelData = _getLevel(level);
    final levelColor = brickColors[(level - 1) % brickColors.length];
    final color = levelData.hitsRequired >= 2 ? _getContrastColor(levelColor) : levelColor;

    final brickW = (width - ((levelData.columns + 1) * brickGutter)) / levelData.columns;
    final brickH = brickHeight * levelData.brickHeightMultiplier;

    final indestructiblePositions = _generateIndestructiblePositions(
      levelData.columns,
      levelData.rows,
      levelData.indestructibleCount,
      rand,
    );

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
            moveSpeed: levelData.moveSpeedBase + (j * levelData.moveSpeedIncrement),
            isIndestructible: indestructiblePositions.contains(i * levelData.rows + j),
          ),
    ];
  }

  static Set<int> _generateIndestructiblePositions(int cols, int rows, int count, math.Random rand) {
    if (count == 0) return {};

    final allPositions = <int>[];
    for (var i = 0; i < cols; i++) {
      for (var j = 0; j < rows; j++) {
        allPositions.add(i * rows + j);
      }
    }
    allPositions.shuffle(rand);

    final indestructiblePositions = <int>{};
    for (final pos in allPositions) {
      if (indestructiblePositions.length >= count) break;

      final row = pos ~/ rows;
      final col = pos % rows;
      var adjacentCount = 0;

      final neighbors = [
        (row - 1) * rows + col,
        (row + 1) * rows + col,
        row * rows + (col - 1),
        row * rows + (col + 1),
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
    final brightness = baseColor.computeLuminance();
    return brightness > 0.5 ? Colors.black : Colors.orange;
  }
}
