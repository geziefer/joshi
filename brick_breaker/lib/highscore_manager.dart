import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HighscoreEntry {
  final String username;
  final int score;

  HighscoreEntry(this.username, this.score);

  String toJson() => '$username:$score';

  Map<String, dynamic> toMap() => {'username': username, 'score': score};

  static HighscoreEntry fromJson(String json) {
    final parts = json.split(':');
    return HighscoreEntry(parts[0], int.parse(parts[1]));
  }

  static HighscoreEntry fromMap(Map<String, dynamic> map) {
    return HighscoreEntry(map['username'], map['score']);
  }
}

class HighscoreManager {
  static const String _key = 'highscores';
  static const String _globalKey = 'global_highscores';

  static Future<List<HighscoreEntry>> getHighscores() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scores = prefs.getStringList(_key) ?? [];
      final validScores = <HighscoreEntry>[];
      
      for (final s in scores) {
        if (s != null && s.isNotEmpty && s != 'undefined') {
          try {
            validScores.add(HighscoreEntry.fromJson(s));
          } catch (e) {
            print('Removing corrupt score: $s');
          }
        }
      }
      
      // Speichere nur valide Scores zurück
      if (validScores.length != scores.length) {
        await prefs.setStringList(_key, validScores.map((s) => s.toJson()).toList());
      }
      
      return validScores;
    } catch (e) {
      print('Error loading highscores: $e');
      // Lösche korrupte Daten komplett
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_key);
      } catch (_) {}
      return [];
    }
  }

  static Future<bool> usernameExistsInGlobal(String username) async {
    final globalScores = await getGlobalHighscores();
    return globalScores.any((entry) => entry.username == username);
  }

  static Future<List<HighscoreEntry>> getGlobalHighscores() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final jsonString = prefs.getString(_globalKey);
        if (jsonString == null) return [];

        final data = json.decode(jsonString);
        final allScores = (data['globalHighscores'] as List)
            .map((e) => HighscoreEntry.fromMap(e))
            .toList();

        return _filterBestScorePerUsername(allScores);
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/global_highscores.json');

        if (!await file.exists()) {
          return [];
        }

        final jsonString = await file.readAsString();
        final data = json.decode(jsonString);
        final allScores = (data['globalHighscores'] as List)
            .map((e) => HighscoreEntry.fromMap(e))
            .toList();

        return _filterBestScorePerUsername(allScores);
      }
    } catch (e) {
      return [];
    }
  }

  static List<HighscoreEntry> _filterBestScorePerUsername(
    List<HighscoreEntry> scores,
  ) {
    final Map<String, HighscoreEntry> bestScores = {};

    for (final score in scores) {
      if (!bestScores.containsKey(score.username) ||
          bestScores[score.username]!.score < score.score) {
        bestScores[score.username] = score;
      }
    }

    final result = bestScores.values.toList();
    result.sort((a, b) => b.score.compareTo(a.score));
    return result.take(10).toList();
  }

  static Future<void> addScore(String username, int score) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scores = await getHighscores();
      scores.add(HighscoreEntry(username, score));
      scores.sort((a, b) => b.score.compareTo(a.score));
      if (scores.length > 10) scores.removeRange(10, scores.length);

      await prefs.setStringList(_key, scores.map((s) => s.toJson()).toList());
      await _addGlobalScore(username, score);
    } catch (e) {
      print('Error in addScore: $e');
      rethrow;
    }
  }

  static Future<void> _addGlobalScore(String username, int score) async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final jsonString = prefs.getString(_globalKey);

        List<HighscoreEntry> scores = [];
        if (jsonString != null && jsonString.isNotEmpty && jsonString != 'undefined') {
          try {
            final data = json.decode(jsonString);
            if (data != null && data['globalHighscores'] != null) {
              scores = (data['globalHighscores'] as List)
                  .map((e) => HighscoreEntry.fromMap(e))
                  .toList();
            }
          } catch (e) {
            print('Error parsing existing scores: $e');
            scores = [];
          }
        }

        scores.add(HighscoreEntry(username, score));

        final data = {
          'globalHighscores': scores.map((s) => s.toMap()).toList(),
        };
        await prefs.setString(_globalKey, json.encode(data));
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/global_highscores.json');

        List<HighscoreEntry> scores = [];
        if (await file.exists()) {
          final jsonString = await file.readAsString();
          final data = json.decode(jsonString);
          scores = (data['globalHighscores'] as List)
              .map((e) => HighscoreEntry.fromMap(e))
              .toList();
        }

        scores.add(HighscoreEntry(username, score));

        final data = {
          'globalHighscores': scores.map((s) => s.toMap()).toList(),
        };
        await file.writeAsString(json.encode(data));
      }
    } catch (e) {
      // Fehler ignorieren
    }
  }
}
