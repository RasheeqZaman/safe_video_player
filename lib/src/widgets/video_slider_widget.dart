import 'package:flutter/material.dart';
import 'package:safe_video_player/safe_video_player.dart';

class VideoSliderWidget extends StatelessWidget {
  const VideoSliderWidget({
    super.key,
    required this.videoModel,
    required this.controller,
  });

  final VideoIdentifiable? videoModel;
  final SafeVideoPlayerController? controller;

  @override
  Widget build(BuildContext context) {
    if ((controller == null) ||
        (!controller!.isVideoInitialized ||
            (videoModel == null || !(videoModel?.isReadyToPlay ?? false)) ||
            controller!.isBuffering)) {
      return LinearProgressIndicator(
        color: Colors.blueAccent.withValues(alpha: 0.5),
        backgroundColor: Colors.black,
        minHeight: 3.0,
        borderRadius: BorderRadius.circular(10.0),
      );
    }

    if ((videoModel?.hasPlaybackError ??
            false || (controller?.hasError ?? false)) ||
        controller!.currentPosition == null) {
      return SizedBox.shrink();
    }

    return Stack(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            overlayShape: SliderComponentShape.noThumb,
            trackShape: const RectangularSliderTrackShape(),
            trackHeight: 3.0,
            thumbColor: Colors.transparent,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0.0),
          ),
          child: Slider(
            activeColor: Colors.black.withValues(alpha: 0.8),
            inactiveColor: Colors.white10,
            value:
                (controller!.bufferedRanges.isEmpty ||
                    controller!.bufferedRanges[0].end.inSeconds <
                        controller!.currentPosition!.inSeconds)
                ? controller!.currentPosition!.inSeconds.toDouble()
                : (controller!.bufferedRanges[0].end.inSeconds + 1 <
                      controller!.totalDuration.inSeconds)
                ? controller!.bufferedRanges[0].end.inSeconds.toDouble()
                : controller!.totalDuration.inSeconds.toDouble(),
            max: controller!.totalDuration.inSeconds.toDouble(),
            onChanged: (_) {},
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            overlayShape: SliderComponentShape.noThumb,
            trackShape: const RectangularSliderTrackShape(),
            trackHeight: 3.0,
            thumbColor: Colors.transparent,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0.0),
          ),
          child: Slider(
            activeColor: Colors.blueAccent.withValues(alpha: 0.7),
            inactiveColor: Colors.white10,
            value: controller!.currentPosition!.inSeconds.toDouble(),
            max: controller!.totalDuration.inSeconds.toDouble(),
            onChanged: (_) {},
          ),
        ),
      ],
    );
  }
}
