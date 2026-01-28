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
  static const String _key = 'space_highscores';
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

  static Future<bool> isTop10Score(int score) async {
    try {
      final scores = await getGlobalHighscores();
      if (scores.length < 10) return true;
      return score > scores.last.score;
    } catch (e) {
      return true;
    }
  }

  static Future<List<HighscoreEntry>> getGlobalHighscores() async {
    try {
      final snapshot = await _database.child('space_highscores').get();
      if (!snapshot.exists) return [];

      final data = snapshot.value as Map<dynamic, dynamic>;
      final allScores = data.values
          .map((e) => HighscoreEntry.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      allScores.sort((a, b) => b.score.compareTo(a.score));
      return allScores.take(10).toList();
    } catch (e) {
      return [];
    }
  }

  static Stream<List<HighscoreEntry>> watchGlobalHighscores() {
    return _database.child('space_highscores').onValue.map((event) {
      if (!event.snapshot.exists) return <HighscoreEntry>[];

      final data = event.snapshot.value as Map<dynamic, dynamic>;
      final allScores = data.values
          .map((e) => HighscoreEntry.fromMap(Map<String, dynamic>.from(e)))
          .toList();

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
      final snapshot = await _database.child('space_highscores').get();
      final allScores = <HighscoreEntry>[];
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        allScores.addAll(
          data.values.map((e) => HighscoreEntry.fromMap(Map<String, dynamic>.from(e))),
        );
      }
      
      final localScores = await getHighscores();
      allScores.addAll(localScores);
      allScores.sort((a, b) => b.score.compareTo(a.score));
      final top10 = allScores.take(10).toList();
      
      // Alte Einträge löschen
      await _database.child('space_highscores').remove();
      
      // Nur Top 10 speichern
      for (final entry in top10) {
        await _database.child('space_highscores').push().set({
          'username': entry.username,
          'score': entry.score,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      }
    } catch (e) {
      // Error syncing to Firebase
    }
  }
}
