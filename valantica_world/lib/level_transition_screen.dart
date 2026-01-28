import 'package:flutter/material.dart';

class LevelTransitionScreen extends StatelessWidget {
  final int levelNumber;

  const LevelTransitionScreen({super.key, required this.levelNumber});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A0E27), Color(0xFF1A1F3A)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'LEVEL $levelNumber',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 64,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'GET READY!',
              style: TextStyle(
                color: Colors.orangeAccent,
                fontSize: 32,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
