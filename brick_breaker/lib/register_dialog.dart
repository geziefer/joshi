import 'package:flutter/material.dart';
import 'package:practice_game/highscore_manager.dart';
import 'package:practice_game/username_dialog.dart';

class RegisterDialog extends StatefulWidget {
  final Function(String) onRegister;
  final VoidCallback onCancel;

  const RegisterDialog({
    super.key,
    required this.onRegister,
    required this.onCancel,
  });

  @override
  State<RegisterDialog> createState() => _RegisterDialogState();
}

class _RegisterDialogState extends State<RegisterDialog> {
  final _controller = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final username = _controller.text.trim();
    if (username.isEmpty) {
      setState(() {
        _errorMessage = 'Bitte gib einen Namen ein';
      });
      return;
    }

    final exists = await HighscoreManager.usernameExistsInGlobal(username);
    
    if (exists) {
      setState(() {
        _errorMessage = 'Benutzername gibt es bereits';
      });
    } else {
      currentUsername = username;
      widget.onRegister(username);
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
                'Registrieren',
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
                  if (_errorMessage != null) {
                    setState(() {
                      _errorMessage = null;
                    });
                  }
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: widget.onCancel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('ZURÜCK'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff1e6091),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('REGISTRIEREN'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
