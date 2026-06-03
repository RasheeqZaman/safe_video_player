import 'package:flutter/material.dart';
import 'package:safe_video_player/src/constant.dart';
import 'package:safe_video_player/src/video_controller.dart';
import 'package:video_player/video_player.dart';

class HorizontalVideoPlayerWidget extends StatelessWidget {
  const HorizontalVideoPlayerWidget({super.key, required this.videoController});

  final SafeVideoPlayerController videoController;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: videoController.value.aspectRatio,
      child: VideoPlayer(videoController),
    );
  }
}

class VerticalVideoPlayerWidget extends StatelessWidget {
  const VerticalVideoPlayerWidget({super.key, required this.videoController});

  final SafeVideoPlayerController videoController;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: context.screenWidth,
              height: context.screenWidth / (videoController.value.aspectRatio),
              child: VideoPlayer(videoController),
            ),
          ),
        ),
      ],
    );
  }
}
