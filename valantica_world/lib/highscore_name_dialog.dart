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
      color: Colors.black.withValues(alpha: 0.9),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xff1a1a2e),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.cyan, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🎉 Top 10! 🎉',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyan,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Score: ${widget.score}',
                style: const TextStyle(fontSize: 24, color: Colors.white),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: 'Dein Name',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.cyan),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.cyan, width: 2),
                  ),
                ),
                maxLength: 20,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
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
                child: const Text('SPEICHERN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
