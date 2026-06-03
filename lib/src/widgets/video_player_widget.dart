import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:safe_video_player/src/video_controller.dart';
import 'package:safe_video_player/src/video_widget.dart';

class VideoPlayerWidget extends StatefulWidget {
  const VideoPlayerWidget({
    super.key,
    required this.videoController,
    required this.thumbnailUrl,
    required this.onTapPlayPause,
    required this.onChangePlayerValue,
    required this.onInitVideo,
    required this.onSwipeRight,
    required this.onSwipeLeft,
    this.isLocalThumbnail = false,
    this.onLongPress,
  });

  final SafeVideoPlayerController? videoController;
  final String? thumbnailUrl;
  final void Function() onChangePlayerValue;
  final void Function() onTapPlayPause;
  final void Function() onSwipeRight;
  final void Function() onSwipeLeft;
  final void Function() onInitVideo;
  final bool isLocalThumbnail;
  final VoidCallback? onLongPress;

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  SafeVideoPlayerController? get _videoController => widget.videoController;

  Timer? _videoPlayerTimer;

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await _init();
    });
  }

  @override
  void dispose() async {
    super.dispose();
    _videoPlayerTimer?.cancel();
  }

  Future<void> _onEndedVideo() async {
    await _videoController?.reset();
    widget.onChangePlayerValue.call();
    widget.onTapPlayPause();
    if (mounted) setState(() {});
  }

  void _onTimerVideo() {
    if (_videoController?.isVideoEnded ?? false) _onEndedVideo();
    if (mounted) {
      widget.onChangePlayerValue.call();
      setState(() {});
    }
  }

  Future<void> _init() async {
    _videoPlayerTimer = Timer.periodic(const Duration(milliseconds: 500), (
      timer,
    ) {
      _onTimerVideo();
    });

    widget.onInitVideo.call();
  }

  Future<void> _onPlayVideo() async {
    await _videoController?.play();
    widget.onTapPlayPause();
  }

  Future<void> _onPauseVideo() async {
    await _videoController?.pause();
    widget.onTapPlayPause();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: widget.onLongPress,
      child: Stack(
        children: [
          (!(_videoController?.isVideoInitialized ?? false))
              ? ((_videoController?.value.aspectRatio ?? 1.0) >= 1.0)
                    ? HorizontalVideoThumbnailWidget(
                        thumbnailUrl: widget.thumbnailUrl,
                        isLocalThumbnail: widget.isLocalThumbnail,
                      )
                    : VerticalVideoThumbnailWidget(
                        thumbnailUrl: widget.thumbnailUrl,
                        isLocalThumbnail: widget.isLocalThumbnail,
                      )
              : Container(
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onHorizontalDragEnd: (DragEndDetails details) {
                      if ((details.primaryVelocity ?? 0) > 0) {
                        widget.onSwipeLeft();
                      } else if ((details.primaryVelocity ?? 0) < 0) {
                        widget.onSwipeRight();
                      }
                    },
                    onTap: () async {
                      if (_videoController?.isVideoPlaying ?? false) {
                        await _onPauseVideo();
                      } else {
                        await _onPlayVideo();
                      }
                      widget.onChangePlayerValue.call();
                      setState(() {});
                    },
                    child: ((_videoController?.value.aspectRatio ?? 1.0) >= 1.0)
                        ? HorizontalVideoPlayerWidget(
                            videoController: _videoController!,
                          )
                        : VerticalVideoPlayerWidget(
                            videoController: _videoController!,
                          ),
                  ),
                ),
        ],
      ),
    );
  }
}

class VerticalVideoThumbnailWidget extends StatelessWidget {
  const VerticalVideoThumbnailWidget({
    super.key,
    required this.thumbnailUrl,
    required this.isLocalThumbnail,
  });

  final String? thumbnailUrl;
  final bool isLocalThumbnail;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: (thumbnailUrl == null || thumbnailUrl!.isEmpty)
          ? null
          : (isLocalThumbnail)
          ? Container(
              decoration: BoxDecoration(
                color: Colors.black,
                image: DecorationImage(
                  image: FileImage(File(thumbnailUrl ?? '')),
                  fit: BoxFit.cover,
                ),
              ),
            )
          : CachedNetworkImage(
              imageUrl: thumbnailUrl ?? '',
              fit: BoxFit.none,
              imageBuilder: (context, imageProvider) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    image: DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
              progressIndicatorBuilder: (context, url, downloadProgress) {
                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black,
                );
              },
            ),
    );
  }
}

class HorizontalVideoThumbnailWidget extends StatelessWidget {
  const HorizontalVideoThumbnailWidget({
    super.key,
    required this.thumbnailUrl,
    required this.isLocalThumbnail,
  });

  final String? thumbnailUrl;
  final bool isLocalThumbnail;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: (thumbnailUrl == null || thumbnailUrl!.isEmpty)
          ? null
          : (isLocalThumbnail)
          ? Container(
              decoration: BoxDecoration(
                color: Colors.black,
                image: DecorationImage(
                  image: FileImage(File(thumbnailUrl ?? '')),
                  fit: BoxFit.fitWidth,
                ),
              ),
            )
          : CachedNetworkImage(
              imageUrl: thumbnailUrl ?? '',
              fit: BoxFit.none,
              imageBuilder: (context, imageProvider) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    image: DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                );
              },
              progressIndicatorBuilder: (context, url, downloadProgress) {
                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black,
                );
              },
            ),
    );
  }
}
