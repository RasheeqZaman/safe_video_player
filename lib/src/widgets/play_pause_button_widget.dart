import 'package:flutter/material.dart';

class PlayPauseButtonWidget extends StatelessWidget {
  const PlayPauseButtonWidget({
    super.key,
    required this.isVideoPlaying,
    required this.isVisible,
  });

  final bool isVideoPlaying;
  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(20.0),
          child: Icon(
            isVideoPlaying ? Icons.pause : Icons.play_arrow,
            size: 50.0,
          ),
        ),
      ),
    );
  }
}
