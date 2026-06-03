import 'package:flutter/material.dart';

class VideoBackButton extends StatelessWidget {
  const VideoBackButton({super.key, required this.onTapBackButton});

  final void Function() onTapBackButton;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTapBackButton();
      },
      child: Container(
        height: 35,
        width: 35,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: Colors.white,
        ),
      ),
    );
  }
}
