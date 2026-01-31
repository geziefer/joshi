import 'package:firebase_database/firebase_database.dart';
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
    return HighscoreEntry(
      map['username']?.toString() ?? 'Unknown',
      (map['score'] is int) ? map['score'] : int.tryParse(map['score']?.toString() ?? '0') ?? 0,
    );
  }
}

class HighscoreManager {
  static const String _key = 'highscores';
  static final _database = FirebaseDatabase.instance.ref();
  static const String _firebasePath = 'brick_breaker_highscores';

  static Future<List<HighscoreEntry>> getHighscores() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scores = prefs.getStringList(_key) ?? [];
      final validScores = <HighscoreEntry>[];
      
      for (final s in scores) {
        if (s.isNotEmpty && s != 'undefined') {
          try {
            validScores.add(HighscoreEntry.fromJson(s));
          } catch (e) {
            // Removing corrupt score
          }
        }
      }
      
      if (validScores.length != scores.length) {
        await prefs.setStringList(_key, validScores.map((s) => s.toJson()).toList());
      }
      
      return validScores;
    } catch (e) {
      return [];
    }
  }

  static Future<bool> isTop10Score(int score) async {
    if (score <= 0) return false;
    try {
      final scores = await getGlobalHighscores();
      if (scores.length < 10) return true;
      return score > scores.last.score;
    } catch (e) {
      return false;
    }
  }

  static Future<List<HighscoreEntry>> getGlobalHighscores() async {
    try {
      final snapshot = await _database.child(_firebasePath).get();
      if (!snapshot.exists) return [];

      final data = snapshot.value;
      if (data == null) return [];
      
      final allScores = <HighscoreEntry>[];
      
      // Handle both List and Map formats
      if (data is List) {
        for (var item in data) {
          if (item != null && item is Map) {
            try {
              allScores.add(HighscoreEntry.fromMap(Map<String, dynamic>.from(item)));
            } catch (e) {
              // Skip invalid entries
            }
          }
        }
      } else if (data is Map) {
        data.forEach((key, value) {
          if (value is Map) {
            try {
              allScores.add(HighscoreEntry.fromMap(Map<String, dynamic>.from(value)));
            } catch (e) {
              // Skip invalid entries
            }
          }
        });
      }

      allScores.sort((a, b) => b.score.compareTo(a.score));
      return allScores.take(10).toList();
    } catch (e) {
      return [];
    }
  }

  static Stream<List<HighscoreEntry>> watchGlobalHighscores() {
    return _database.child(_firebasePath).onValue.map((event) {
      if (!event.snapshot.exists) return <HighscoreEntry>[];

      final data = event.snapshot.value;
      if (data == null) return <HighscoreEntry>[];
      
      final allScores = <HighscoreEntry>[];
      
      // Handle both List and Map formats
      if (data is List) {
        for (var item in data) {
          if (item != null && item is Map) {
            try {
              allScores.add(HighscoreEntry.fromMap(Map<String, dynamic>.from(item)));
            } catch (e) {
              // Skip invalid entries
            }
          }
        }
      } else if (data is Map) {
        data.forEach((key, value) {
          if (value is Map) {
            try {
              allScores.add(HighscoreEntry.fromMap(Map<String, dynamic>.from(value)));
            } catch (e) {
              // Skip invalid entries
            }
          }
        });
      }

      allScores.sort((a, b) => b.score.compareTo(a.score));
      return allScores.take(10).toList();
    });
  }


  static Future<void> addScore(String username, int score) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scores = await getHighscores();
      scores.add(HighscoreEntry(username, score));
      scores.sort((a, b) => b.score.compareTo(a.score));
      if (scores.length > 10) scores.removeRange(10, scores.length);

      await prefs.setStringList(_key, scores.map((s) => s.toJson()).toList());
      await _syncTop10ToFirebase();
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> _syncTop10ToFirebase() async {
    try {
      final snapshot = await _database.child(_firebasePath).get();
      final allScores = <HighscoreEntry>[];
      
      if (snapshot.exists) {
        final data = snapshot.value;
        if (data is Map) {
          data.forEach((key, value) {
            if (value is Map) {
              try {
                allScores.add(HighscoreEntry.fromMap(Map<String, dynamic>.from(value)));
              } catch (e) {
                // Skip invalid entries
              }
            }
          });
        }
      }
      
      final localScores = await getHighscores();
      allScores.addAll(localScores);
      allScores.sort((a, b) => b.score.compareTo(a.score));
      final top10 = allScores.take(10).toList();
      
      await _database.child(_firebasePath).set(
        Map.fromEntries(
          top10.asMap().entries.map((e) => MapEntry(
            e.key.toString(),
            {
              'username': e.value.username,
              'score': e.value.score,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            },
          )),
        ),
      );
    } catch (e) {
      // Error syncing to Firebase
    }
  }
}
