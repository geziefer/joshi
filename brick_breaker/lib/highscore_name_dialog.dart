import 'package:flutter/material.dart';

class HighscoreNameDialog extends StatefulWidget {
  final int score;
  final Function(String) onSubmit;

  const HighscoreNameDialog({
    super.key,
    required this.score,
    required this.onSubmit,
  });

  @override
  State<HighscoreNameDialog> createState() => _HighscoreNameDialogState();
}

class _HighscoreNameDialogState extends State<HighscoreNameDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) {
      widget.onSubmit(name);
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
                '🎉 Top 10! 🎉',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Score: ${widget.score}',
                style: const TextStyle(fontSize: 24, color: Color(0xff1e6091)),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Dein Name',
                ),
                maxLength: 20,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
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
                child: const Text('SPEICHERN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
