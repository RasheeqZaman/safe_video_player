import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:safe_video_player/src/interfaces/video_identifiable.dart';
import 'package:safe_video_player/src/multi_video_controller.dart';
import 'package:safe_video_player/src/video_controller.dart';
import 'package:safe_video_player/src/widgets/play_pause_button_widget.dart';
import 'package:safe_video_player/src/widgets/video_back_button.dart';
import 'package:safe_video_player/src/widgets/video_mute_button_widget.dart';
import 'package:safe_video_player/src/widgets/video_player_widget.dart';
import 'package:safe_video_player/src/widgets/video_slider_widget.dart';

class MultiVideoPlayerWidget<T extends VideoIdentifiable>
    extends StatefulWidget {
  const MultiVideoPlayerWidget({
    super.key,
    required this.initialVideoIndex,
    required this.videoModels,
    required this.multiVideoPlayerController,
    required this.onTapBackButton,
    this.overlayBuilder,
    this.onLongPressVideo,
    this.onInitVideoScreen,
    this.onPageChange,
    this.onSwipeRight,
    this.isLocalThumbnail = false,
    this.backButtonBuilder,
    this.muteButtonBuilder,
    this.headerBuilder,
  });

  final int initialVideoIndex;
  final SafeMultiVideoPlayerController<T> multiVideoPlayerController;
  final List<T> videoModels;
  final void Function() onTapBackButton;
  final Future<void> Function(int previousPageIndex, int currentPageIndex)?
  onPageChange;
  final void Function(int index)? onInitVideoScreen;
  final Future<void> Function(int index)? onSwipeRight;
  final bool isLocalThumbnail;
  final void Function(int index)? onLongPressVideo;
  final Widget Function(T videoModel, int index)? overlayBuilder;
  final Widget Function(void Function() onTapBackButton)? backButtonBuilder;
  final Widget Function(void Function() onTapMute)? muteButtonBuilder;
  final Widget Function({
    required Widget Function() backButtonBuilder,
    required Widget Function() muteButtonBuilder,
  })?
  headerBuilder;

  @override
  State<MultiVideoPlayerWidget<T>> createState() =>
      _MultiVideoPlayerWidgetState<T>();
}

class _MultiVideoPlayerWidgetState<T extends VideoIdentifiable>
    extends State<MultiVideoPlayerWidget<T>> {
  PageController? _pageController;

  bool _isPlayPauseButtonVisible = false;

  bool get _isVideoPlaying =>
      widget.multiVideoPlayerController.isVideoPlayingFocusedVideo;

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _pageController = PageController(initialPage: widget.initialVideoIndex);
      if (mounted) {
        widget.multiVideoPlayerController.startFocusedVideo(
          widget.initialVideoIndex,
          widget.videoModels,
        );
        setState(() {});
      }
    });
  }

  void _onTapMute() {
    widget.multiVideoPlayerController.switchMuteFocusedVideo();
    setState(() {});
  }

  @override
  void dispose() {
    _pageController?.dispose();
    widget.multiVideoPlayerController.stopFocusedVideo();
    super.dispose();
  }

  Widget _buildHeader() {
    return widget.headerBuilder?.call(
          backButtonBuilder: () {
            return widget.backButtonBuilder?.call(widget.onTapBackButton) ??
                VideoBackButton(
                  onTapBackButton: () {
                    widget.onTapBackButton();
                  },
                );
          },
          muteButtonBuilder: () {
            return widget.muteButtonBuilder?.call(_onTapMute) ??
                VideoMuteButtonWidget(
                  isMuted:
                      widget.multiVideoPlayerController.isMutedFocusedVideo,
                  onTapMute: _onTapMute,
                );
          },
        ) ??
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 45.0, horizontal: 15.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              widget.backButtonBuilder?.call(widget.onTapBackButton) ??
                  VideoBackButton(
                    onTapBackButton: () {
                      widget.onTapBackButton();
                    },
                  ),
              Spacer(),
              widget.muteButtonBuilder?.call(_onTapMute) ??
                  VideoMuteButtonWidget(
                    isMuted:
                        widget.multiVideoPlayerController.isMutedFocusedVideo,
                    onTapMute: _onTapMute,
                  ),
            ],
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: [
          if (_pageController != null)
            PageView.builder(
              itemCount: widget.videoModels.length,
              scrollDirection: Axis.vertical,
              controller: _pageController,
              pageSnapping: true,
              onPageChanged: (index) async {
                final T? videoModel =
                    (index < 0 || index >= widget.videoModels.length)
                    ? null
                    : widget.videoModels[index];
                if (videoModel == null) return;

                int previousPageIndex =
                    widget.multiVideoPlayerController.focusedPageIndex;
                await widget.onPageChange?.call(previousPageIndex, index);
                widget.multiVideoPlayerController.onChangePage(
                  index,
                  widget.videoModels,
                );
                _isPlayPauseButtonVisible = false;
                setState(() {});
              },
              itemBuilder: (context, index) {
                final T? videoModel =
                    (index < 0 || index >= widget.videoModels.length)
                    ? null
                    : widget.videoModels[index];
                final SafeVideoPlayerController? videoController = widget
                    .multiVideoPlayerController
                    .videoControllers[videoModel];
                return (videoModel == null)
                    ? const SizedBox.shrink()
                    : Stack(
                        children: [
                          Column(
                            children: [
                              Expanded(
                                child: Stack(
                                  children: [
                                    VideoPlayerWidget(
                                      videoController: videoController,
                                      isLocalThumbnail: widget.isLocalThumbnail,
                                      thumbnailUrl: videoModel.thumbnailUrl,
                                      onLongPress: () {
                                        widget.onLongPressVideo?.call(index);
                                      },
                                      onTapPlayPause: () {
                                        _onTapPlayPause(context);
                                      },
                                      onChangePlayerValue: _onChangePlayerValue,
                                      onInitVideo: () {
                                        widget.multiVideoPlayerController
                                            .preCache(
                                              index,
                                              totalVideos:
                                                  widget.videoModels.length,
                                              getVideoModel: (index) =>
                                                  (index < 0 ||
                                                      index >=
                                                          widget
                                                              .videoModels
                                                              .length)
                                                  ? null
                                                  : widget.videoModels[index],
                                            );
                                        widget.onInitVideoScreen?.call(index);
                                      },
                                      onSwipeLeft: () {
                                        if (Platform.isIOS) {
                                          widget.onTapBackButton();
                                        }
                                      },
                                      onSwipeRight: () async {
                                        await widget.onSwipeRight?.call(index);
                                      },
                                    ),
                                    Positioned.fill(
                                      child: Align(
                                        alignment: Alignment.center,
                                        child:
                                            (videoModel.hasPlaybackError ||
                                                (videoController?.hasError ??
                                                    false))
                                            ? const Center(
                                                child: Icon(
                                                  Icons.error,
                                                  color: Colors.red,
                                                  size: 70.0,
                                                ),
                                              )
                                            : PlayPauseButtonWidget(
                                                isVideoPlaying: _isVideoPlaying,
                                                isVisible:
                                                    _isPlayPauseButtonVisible,
                                              ),
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: IgnorePointer(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.transparent,
                                                Colors.transparent,
                                                Colors.transparent,
                                                Colors.black.withValues(
                                                  alpha: 1.0,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (videoController != null)
                                VideoSliderWidget(
                                  videoModel: videoModel,
                                  controller: videoController,
                                ),
                            ],
                          ),
                          if (widget.overlayBuilder != null)
                            widget.overlayBuilder!(videoModel, index),
                        ],
                      );
              },
            ),
          Positioned.fill(child: _buildHeader()),
        ],
      ),
    );
  }

  void _onChangePlayerValue() {
    if (mounted) setState(() {});
  }

  void _onTapPlayPause(BuildContext context) async {
    _startHidePlayPauseButtonTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void _startHidePlayPauseButtonTimer() {
    if (_isPlayPauseButtonVisible) return;
    _isPlayPauseButtonVisible = true;
    Timer(const Duration(seconds: 3), () {
      _isPlayPauseButtonVisible = false;
      if (mounted) setState(() {});
    });
  }
}
