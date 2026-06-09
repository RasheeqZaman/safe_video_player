import 'package:flutter/material.dart';
import 'package:safe_video_player/safe_video_player.dart';

class VideoSliderWidget extends StatefulWidget {
  const VideoSliderWidget({
    super.key,
    required this.videoModel,
    required this.controller,
    this.activeColor = Colors.white,
    this.bufferColor,
    this.trackColor,
    this.thumbColor = Colors.white,
    this.padding,
  });

  final VideoIdentifiable videoModel;
  final SafeVideoPlayerController controller;
  final Color activeColor;
  final Color? bufferColor;
  final Color? trackColor;
  final Color thumbColor;
  final EdgeInsetsGeometry? padding;

  @override
  State<VideoSliderWidget> createState() => _VideoSliderWidgetState();
}

class _VideoSliderWidgetState extends State<VideoSliderWidget> {
  double? _dragValue;
  bool _isDragging = false;
  bool _wasPlaying = false;

  double get _maxValue => widget.controller.totalDuration.inSeconds.toDouble();

  double get _currentValue {
    if (_isDragging && _dragValue != null) return _dragValue!;
    return widget.controller.currentPosition?.inSeconds.toDouble() ?? 0.0;
  }

  double _getBufferValue() {
    final buffered = widget.controller.bufferedRanges;
    return buffered.isNotEmpty ? buffered[0].end.inSeconds.toDouble() : 0.0;
  }

  void _onDragStart(double value) {
    _wasPlaying = widget.controller.isVideoPlaying;
    widget.controller.pause();
    setState(() {
      _isDragging = true;
      _dragValue = value;
    });
  }

  void _onDragUpdate(double value) {
    setState(() => _dragValue = value);
  }

  void _onDragEnd(double value) {
    widget.controller.seekTo(Duration(milliseconds: (value * 1000).round()));
    if (_wasPlaying) widget.controller.play();
    setState(() {
      _isDragging = false;
      _dragValue = null;
    });
  }

  Color get _bufferColor =>
      widget.bufferColor ?? widget.activeColor.withValues(alpha: 0.3);

  Color get _trackColor =>
      widget.trackColor ?? widget.activeColor.withValues(alpha: 0.15);

  Widget _buildLoadingBar() {
    return Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: LinearProgressIndicator(
        color: _bufferColor,
        backgroundColor: _trackColor,
        minHeight: 3.0,
        borderRadius: BorderRadius.circular(10.0),
      ),
    );
  }

  SliderThemeData _baseTheme(BuildContext context) {
    return SliderTheme.of(context).copyWith(
      overlayShape: SliderComponentShape.noThumb,
      trackShape: const RectangularSliderTrackShape(),
      trackHeight: _isDragging ? 4.0 : 3.0,
      thumbColor: Colors.transparent,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videoModel.hasPlaybackError ||
        widget.controller.hasError ||
        widget.controller.currentPosition == null) {
      return const SizedBox.shrink();
    }

    if (!widget.controller.isVideoInitialized ||
        !widget.videoModel.isReadyToPlay ||
        widget.controller.isBuffering) {
      return _buildLoadingBar();
    }

    final double max = _maxValue;
    if (max <= 0) return const SizedBox.shrink();

    Widget slider = Stack(
      children: [
        // Buffer layer
        SliderTheme(
          data: _baseTheme(context),
          child: Slider(
            activeColor: _bufferColor,
            inactiveColor: _trackColor,
            value: _getBufferValue().clamp(0.0, max),
            max: max,
            onChanged: (_) {},
          ),
        ),
        // Playback layer — interactive
        SliderTheme(
          data: _baseTheme(context).copyWith(
            thumbColor: widget.thumbColor,
            thumbShape: RoundSliderThumbShape(
              enabledThumbRadius: _isDragging ? 6.0 : 0.0,
            ),
          ),
          child: Slider(
            activeColor: widget.activeColor,
            inactiveColor: Colors.transparent,
            value: _currentValue.clamp(0.0, max),
            max: max,
            onChangeStart: _onDragStart,
            onChanged: _onDragUpdate,
            onChangeEnd: _onDragEnd,
          ),
        ),
      ],
    );

    if (widget.padding != null) {
      return Padding(padding: widget.padding!, child: slider);
    }
    return slider;
  }
}
