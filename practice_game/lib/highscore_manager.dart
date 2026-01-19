import 'package:shared_preferences/shared_preferences.dart';

class HighscoreManager {
  static const String _key = 'highscores';

  static Future<List<int>> getHighscores() async {
    final prefs = await SharedPreferences.getInstance();
    final scores = prefs.getStringList(_key) ?? [];
    return scores.map((s) => int.parse(s)).toList();
  }

  static Future<void> addScore(int score) async {
    final scores = await getHighscores();
    scores.add(score);
    scores.sort((a, b) => b.compareTo(a));
    if (scores.length > 10) scores.removeRange(10, scores.length);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, scores.map((s) => s.toString()).toList());
  }
}
