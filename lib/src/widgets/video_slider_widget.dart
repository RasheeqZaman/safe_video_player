import 'package:flutter/material.dart';
import 'package:safe_video_player/safe_video_player.dart';
import 'package:video_player/video_player.dart';

class VideoSliderWidget extends StatelessWidget {
  const VideoSliderWidget({
    super.key,
    required this.videoModel,
    required this.controller,
  });

  final VideoIdentifiable videoModel;
  final SafeVideoPlayerController controller;

  Widget _buildProgressIndicator() {
    return LinearProgressIndicator(
      color: Colors.blueAccent.withValues(alpha: 0.5),
      backgroundColor: Colors.black,
      minHeight: 3.0,
      borderRadius: BorderRadius.circular(10.0),
    );
  }

  double _getSliderValue(
    List<DurationRange> bufferedRanges,
    Duration currentPosition,
    Duration totalDuration,
  ) {
    final double bufferedRangesEndInSec = bufferedRanges.isNotEmpty
        ? bufferedRanges[0].end.inSeconds.toDouble()
        : 0.0;
    final double currentPositionInSec = currentPosition.inSeconds.toDouble();
    final double totalDurationInSec = totalDuration.inSeconds.toDouble();

    return (bufferedRangesEndInSec < currentPositionInSec)
        ? currentPositionInSec
        : (bufferedRangesEndInSec + 1 < totalDurationInSec)
        ? bufferedRangesEndInSec
        : totalDurationInSec;
  }

  @override
  Widget build(BuildContext context) {
    if (videoModel.hasPlaybackError ||
        controller.hasError ||
        controller.currentPosition == null) {
      return SizedBox.shrink();
    }

    if (!controller.isVideoInitialized ||
        !videoModel.isReadyToPlay ||
        controller.isBuffering) {
      return _buildProgressIndicator();
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
            value: _getSliderValue(
              controller.bufferedRanges,
              controller.currentPosition!,
              controller.totalDuration,
            ),
            max: controller.totalDuration.inSeconds.toDouble(),
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
            value: controller.currentPosition!.inSeconds.toDouble(),
            max: controller.totalDuration.inSeconds.toDouble(),
            onChanged: (_) {},
          ),
        ),
      ],
    );
  }
}
