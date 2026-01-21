import 'package:flutter/material.dart';
import 'package:practice_game/highscore_manager.dart';

class UsernameDialog extends StatefulWidget {
  final VoidCallback onStart;

  const UsernameDialog({super.key, required this.onStart});

  @override
  State<UsernameDialog> createState() => _UsernameDialogState();
}

class _UsernameDialogState extends State<UsernameDialog> {
  final _controller = TextEditingController();
  bool _showWarning = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkAndStart() async {
    final username = _controller.text.trim();
    if (username.isEmpty) return;

    final exists = await HighscoreManager.usernameExistsInGlobal(username);
    
    if (exists && !_showWarning) {
      setState(() {
        _showWarning = true;
      });
    } else {
      currentUsername = username;
      widget.onStart();
    }
  }

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
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Benutzername eingeben',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Dein Name',
                ),
                maxLength: 20,
                onChanged: (_) {
                  if (_showWarning) {
                    setState(() {
                      _showWarning = false;
                    });
                  }
                },
              ),
              if (_showWarning)
                const SizedBox(height: 16),
              if (_showWarning)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(255, 165, 0, 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Text(
                    'Dieser Username ist bereits vergeben. Dies beeinflusst die Highscore Tabelle. Trotzdem weitermachen?',
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _checkAndStart,
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
                child: Text(_showWarning ? 'JA' : 'GO'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String currentUsername = 'Spieler';
