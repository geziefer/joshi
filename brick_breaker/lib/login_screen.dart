import 'package:flutter/material.dart';
import 'package:practice_game/highscore_manager.dart';

class LoginScreen extends StatelessWidget {
  final VoidCallback onRegister;
  final VoidCallback onLogin;

  const LoginScreen({
    super.key,
    required this.onRegister,
    required this.onLogin,
  });

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
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
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
                        const Text(
                          'Highscores',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        StreamBuilder<List<HighscoreEntry>>(
                          stream: HighscoreManager.watchGlobalHighscores(),
                          builder: (context, snapshot) {
                            final scores = snapshot.data ?? [];
                            if (scores.isEmpty) {
                              return const Text('Noch keine Highscores');
                            }
                            return Column(
                              children: List.generate(
                                scores.length,
                                (i) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    '${i + 1}. ${scores[i].username} - ${scores[i].score}',
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
                    onPressed: onRegister,
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
                    child: const Text('REGISTRIEREN'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: onLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff43aa8b),
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
                    child: const Text('ANMELDEN'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
