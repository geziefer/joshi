import 'package:shared_preferences/shared_preferences.dart';

class HighscoreEntry {
  final String username;
  final int score;

  HighscoreEntry(this.username, this.score);

  String toJson() => '$username:$score';

  static HighscoreEntry fromJson(String json) {
    final parts = json.split(':');
    return HighscoreEntry(parts[0], int.parse(parts[1]));
  }
}

class HighscoreManager {
  static const String _key = 'highscores';

  static Future<List<HighscoreEntry>> getHighscores() async {
    final prefs = await SharedPreferences.getInstance();
    final scores = prefs.getStringList(_key) ?? [];
    return scores.map((s) => HighscoreEntry.fromJson(s)).toList();
  }

  static Future<void> addScore(String username, int score) async {
    final scores = await getHighscores();
    scores.add(HighscoreEntry(username, score));
    scores.sort((a, b) => b.score.compareTo(a.score));
    if (scores.length > 10) scores.removeRange(10, scores.length);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, scores.map((s) => s.toJson()).toList());
  }
}
