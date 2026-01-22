import 'package:flutter/material.dart';
import 'package:practice_game/highscore_manager.dart';

class StartScreen extends StatefulWidget {
  final VoidCallback onStart;
  final VoidCallback onBack;
  final String username;

  const StartScreen({
    super.key,
    required this.onStart,
    required this.onBack,
    required this.username,
  });

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xffa9d6e5), Color(0xfff2e8cf)],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 40),
                const Text(
                  'BRICK BREAKER',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff1e6091),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Willkommen, ${widget.username}!',
                  style: const TextStyle(
                    fontSize: 24,
                    color: Color(0xff1e6091),
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  width: 350,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(255, 255, 255, 0.8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Deine Top 10 Highscores',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      StreamBuilder<List<HighscoreEntry>>(
                        stream: HighscoreManager.watchUserHighscores(widget.username),
                        builder: (context, snapshot) {
                          final scores = snapshot.data ?? [];
                          if (scores.isEmpty) {
                            return const Text('Noch keine Highscores');
                          }
                          return Column(
                            children: List.generate(
                              scores.length,
                              (i) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  '${i + 1}. ${scores[i].score}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: widget.onStart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff1e6091),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 20,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('SPIEL STARTEN'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: widget.onBack,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 20,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('ZURÜCK'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
