import 'package:flutter/material.dart';
import 'package:valantica_world/highscore_manager.dart';

class StartScreen extends StatelessWidget {
  final VoidCallback onStart;

  const StartScreen({
    super.key,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 40),
                const Text(
                  'SPACE RUNNER',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyan,
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  width: 350,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xff1a1a2e),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.cyan, width: 2),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Highscores',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.cyan,
                        ),
                      ),
                      const SizedBox(height: 16),
                      StreamBuilder<List<HighscoreEntry>>(
                        stream: HighscoreManager.watchGlobalHighscores(),
                        builder: (context, snapshot) {
                          final scores = snapshot.data ?? [];
                          if (scores.isEmpty) {
                            return const Text(
                              'Noch keine Highscores',
                              style: TextStyle(color: Colors.white),
                            );
                          }
                          return Column(
                            children: List.generate(
                              scores.length,
                              (i) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  '${i + 1}. ${scores[i].username} - ${scores[i].score}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
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
                  onPressed: onStart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    foregroundColor: Colors.black,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
