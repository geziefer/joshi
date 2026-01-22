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
    return HighscoreEntry(map['username'], map['score']);
  }
}

class HighscoreManager {
  static const String _key = 'highscores';
  static final _database = FirebaseDatabase.instance.ref();

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

  static Future<bool> usernameExistsInGlobal(String username) async {
    try {
      final snapshot = await _database.child('highscores').get();
      if (!snapshot.exists) return false;
      
      final data = snapshot.value as Map<dynamic, dynamic>;
      return data.values.any((entry) => entry['username'] == username);
    } catch (e) {
      return false;
    }
  }

  static Future<List<HighscoreEntry>> getGlobalHighscores() async {
    try {
      final snapshot = await _database.child('highscores').get();
      if (!snapshot.exists) return [];

      final data = snapshot.value as Map<dynamic, dynamic>;
      final allScores = data.values
          .map((e) => HighscoreEntry.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      return _filterBestScorePerUsername(allScores);
    } catch (e) {
      return [];
    }
  }

  static Stream<List<HighscoreEntry>> watchGlobalHighscores() {
    return _database.child('highscores').onValue.map((event) {
      if (!event.snapshot.exists) return <HighscoreEntry>[];

      final data = event.snapshot.value as Map<dynamic, dynamic>;
      final allScores = data.values
          .map((e) => HighscoreEntry.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      return _filterBestScorePerUsername(allScores);
    });
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
      await _addToFirebase(username, score);
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> _addToFirebase(String username, int score) async {
    try {
      await _database.child('highscores').push().set({
        'username': username,
        'score': score,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      // Error adding to Firebase
    }
  }
}
