import 'package:flutter/material.dart';

class UsernameDialog extends StatefulWidget {
  final VoidCallback onStart;

  const UsernameDialog({super.key, required this.onStart});

  @override
  State<UsernameDialog> createState() => _UsernameDialogState();
}

class _UsernameDialogState extends State<UsernameDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  final username = _controller.text.trim();
                  if (username.isNotEmpty) {
                    currentUsername = username;
                    widget.onStart();
                  }
                },
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
                child: const Text('GO'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String currentUsername = 'Spieler';
