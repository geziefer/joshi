import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:practice_game/brick.dart';
import 'package:practice_game/main.dart';

class LevelConfig {
  // Ball speed formula: height / (2.8 - (level * 0.3))
  static double getBallSpeed(int level, double height) {
    return height / (2.8 - (level * 0.3));
  }

  // Power-Up spawn intervals
  static int getYellowPowerUpInterval(int level, math.Random rand) {
    return level >= 4 
        ? rand.nextInt(11) + 10  // Level 4+: 10-20 bricks
        : rand.nextInt(6) + 5;    // Level 2-3: 5-10 bricks
  }

  // Green power-up: 15-25 seconds (Level 3+)
  static double getGreenPowerUpSpawnTime(math.Random rand) {
    return 15.0 + (rand.nextInt(10) * 1.0);
  }

  // Heart power-up: 30-45 seconds (Level 4+)
  static double getHeartPowerUpSpawnTime(math.Random rand) {
    return 30.0 + (rand.nextInt(15) * 1.0);
  }

  // Ball speed increase per brick destruction (Level 2+)
  static double getBallSpeedModifier(int level) {
    return 1.0 + (level * 0.01);
  }

  // Build bricks for specific level
  static List<Brick> buildLevel(int level, double width, double height, math.Random rand) {
    final levelColor = brickColors[(level - 1) % brickColors.length];
    final hitsRequired = level >= 2 ? 2 : 1;
    final multiHitColor = level >= 2
        ? _getContrastColor(levelColor)
        : levelColor;

    switch (level) {
      case 1:
        return _buildLevel1(width, levelColor, hitsRequired);
      case 2:
        return _buildLevel2(width, multiHitColor, hitsRequired);
      case 3:
        return _buildLevel3(width, multiHitColor, hitsRequired, rand);
      default:
        return _buildLevel4Plus(width, multiHitColor, rand);
    }
  }

  // Level 1: 10 große Bricks (2 Reihen x 5 Spalten)
  static List<Brick> _buildLevel1(double width, Color color, int hits) {
    final largeBrickWidth = (width - (6 * brickGutter)) / 5;
    final largeBrickHeight = brickHeight * 3;

    return [
      for (var i = 0; i < 5; i++)
        for (var j = 0; j < 2; j++)
          Brick(
            Vector2(
              (i + 0.5) * largeBrickWidth + (i + 1) * brickGutter,
              (j + 2.0) * largeBrickHeight + (j + 1) * brickGutter,
            ),
            color,
            hitsRequired: hits,
            customSize: Vector2(largeBrickWidth, largeBrickHeight),
          ),
    ];
  }

  // Level 2: 24 Bricks (4 Reihen x 6 Spalten)
  static List<Brick> _buildLevel2(double width, Color color, int hits) {
    final mediumBrickWidth = (width - (7 * brickGutter)) / 6;
    final mediumBrickHeight = brickHeight * 1.25;

    return [
      for (var i = 0; i < 6; i++)
        for (var j = 0; j < 4; j++)
          Brick(
            Vector2(
              (i + 0.5) * mediumBrickWidth + (i + 1) * brickGutter,
              (j + 2.0) * mediumBrickHeight + (j + 1) * brickGutter,
            ),
            color,
            hitsRequired: hits,
            customSize: Vector2(mediumBrickWidth, mediumBrickHeight),
          ),
    ];
  }

  // Level 3: 50 Bricks mit 10 zufälligen unzerstörbaren (keine Cluster)
  static List<Brick> _buildLevel3(double width, Color color, int hits, math.Random rand) {
    final allPositions = <int>[];
    for (var i = 0; i < brickColors.length; i++) {
      for (var j = 1; j <= 5; j++) {
        allPositions.add(i * 5 + (j - 1));
      }
    }
    allPositions.shuffle(rand);
    
    final indestructiblePositions = <int>{};
    for (final pos in allPositions) {
      if (indestructiblePositions.length >= 10) break;
      
      final row = pos ~/ 5;
      final col = pos % 5;
      var adjacentCount = 0;
      
      final neighbors = [
        (row - 1) * 5 + col,
        (row + 1) * 5 + col,
        row * 5 + (col - 1),
        row * 5 + (col + 1),
      ];
      
      for (final neighbor in neighbors) {
        if (indestructiblePositions.contains(neighbor)) {
          adjacentCount++;
        }
      }
      
      if (adjacentCount < 2) {
        indestructiblePositions.add(pos);
      }
    }

    return [
      for (var i = 0; i < brickColors.length; i++)
        for (var j = 1; j <= 5; j++)
          Brick(
            Vector2(
              (i + 0.5) * brickWidth + (i + 1) * brickGutter,
              (j + 2.0) * brickHeight + j * brickGutter,
            ),
            color,
            hitsRequired: hits,
            isIndestructible: indestructiblePositions.contains(i * 5 + (j - 1)),
          ),
    ];
  }

  // Level 4+: 60 bewegliche Bricks (6 Reihen x 10 Spalten) mit 12 unzerstörbaren
  static List<Brick> _buildLevel4Plus(double width, Color color, math.Random rand) {
    final movingBrickWidth = (width - (11 * brickGutter)) / 10;
    final movingBrickHeight = brickHeight * 0.8;

    final allPositions = <int>[];
    for (var i = 0; i < 10; i++) {
      for (var j = 0; j < 6; j++) {
        allPositions.add(i * 6 + j);
      }
    }
    allPositions.shuffle(rand);
    
    final indestructiblePositions = <int>{};
    for (final pos in allPositions) {
      if (indestructiblePositions.length >= 12) break;
      
      final row = pos ~/ 6;
      final col = pos % 6;
      var adjacentCount = 0;
      
      final neighbors = [
        (row - 1) * 6 + col,
        (row + 1) * 6 + col,
        row * 6 + (col - 1),
        row * 6 + (col + 1),
      ];
      
      for (final neighbor in neighbors) {
        if (indestructiblePositions.contains(neighbor)) {
          adjacentCount++;
        }
      }
      
      if (adjacentCount < 2) {
        indestructiblePositions.add(pos);
      }
    }

    return [
      for (var i = 0; i < 10; i++)
        for (var j = 0; j < 6; j++)
          Brick(
            Vector2(
              (i + 0.5) * movingBrickWidth + (i + 1) * brickGutter,
              (j + 2.0) * movingBrickHeight + (j + 1) * brickGutter,
            ),
            color,
            hitsRequired: 3,
            customSize: Vector2(movingBrickWidth, movingBrickHeight),
            isMoving: true,
            moveSpeed: 100.0 + (j * 20.0),
            isIndestructible: indestructiblePositions.contains(i * 6 + j),
          ),
    ];
  }

  static Color _getContrastColor(Color baseColor) {
    final brightness = baseColor.computeLuminance();
    return brightness > 0.5 ? Colors.black : Colors.orange;
  }
}
