import 'package:flutter/material.dart';

class MobileControls extends StatelessWidget {
  final VoidCallback onUpPressed;
  final VoidCallback onUpReleased;
  final VoidCallback onDownPressed;
  final VoidCallback onDownReleased;
  final VoidCallback onShootPressed;
  final VoidCallback onShootReleased;

  const MobileControls({
    super.key,
    required this.onUpPressed,
    required this.onUpReleased,
    required this.onDownPressed,
    required this.onDownReleased,
    required this.onShootPressed,
    required this.onShootReleased,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    
    return Stack(
      children: [
        // Left controls (up/down)
        Positioned(
          left: 20,
          bottom: 20,
          child: isLandscape
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTapDown: (_) => onUpPressed(),
                      onTapUp: (_) => onUpReleased(),
                      onTapCancel: onUpReleased,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.keyboard_arrow_up,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTapDown: (_) => onDownPressed(),
                      onTapUp: (_) => onDownReleased(),
                      onTapCancel: onDownReleased,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTapDown: (_) => onUpPressed(),
                      onTapUp: (_) => onUpReleased(),
                      onTapCancel: onUpReleased,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.keyboard_arrow_up,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTapDown: (_) => onDownPressed(),
                      onTapUp: (_) => onDownReleased(),
                      onTapCancel: onDownReleased,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        // Right control (shoot)
        Positioned(
          right: 20,
          bottom: 20,
          child: GestureDetector(
            onTapDown: (_) => onShootPressed(),
            onTapUp: (_) => onShootReleased(),
            onTapCancel: onShootReleased,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.circle, color: Colors.white, size: 40),
            ),
          ),
        ),
      ],
    );
  }
}
