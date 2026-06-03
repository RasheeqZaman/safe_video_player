import 'package:flutter/material.dart';

class VideoMuteButtonWidget extends StatelessWidget {
  const VideoMuteButtonWidget({
    super.key,
    required this.isMuted,
    required this.onTapMute,
  });

  final bool isMuted;
  final VoidCallback onTapMute;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTapMute,
      child: Container(
        height: 35,
        width: 35,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isMuted ? Icons.volume_off : Icons.volume_up,
          size: 20,
          color: Colors.white,
        ),
      ),
    );
  }
}
