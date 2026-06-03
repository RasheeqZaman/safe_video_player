import 'dart:async';
import 'dart:math' as math;

import 'package:video_player/video_player.dart';

import 'interfaces/video_identifiable.dart';
import 'logger_utils.dart';
import 'video_controller.dart';

const int _defaultCacheVideoCount = 5;

class SafeMultiVideoPlayerController<T extends VideoIdentifiable> {
  final Map<T, SafeVideoPlayerController> _videoControllers = {};

  Map<T, SafeVideoPlayerController> get videoControllers => _videoControllers;

  final Map<SafeVideoPlayerController, Completer<void>> _videoCompleters = {};

  Completer<void>? get videoCompleterFocused =>
      _videoCompleters[_focusedVideoController];

  int _focusedPageIndex = 0;

  int get focusedPageIndex => _focusedPageIndex;

  List<T>? _videoModels;

  bool get _isRunning => (_videoModels != null);

  T? get _focusedVideo =>
      (_videoModels == null ||
          _focusedPageIndex < 0 ||
          _focusedPageIndex >= _videoModels!.length)
      ? null
      : _videoModels![_focusedPageIndex];

  SafeVideoPlayerController? get _focusedVideoController =>
      _videoControllers[_focusedVideo];

  VideoPlayerValue? get _videoPlayerValue => _focusedVideoController?.value;

  bool get isVideoPlayingFocusedVideo => _videoPlayerValue?.isPlaying ?? false;

  void startFocusedVideo(int initialIndex, List<T> videoModels) async {
    _focusedPageIndex = initialIndex;
    _videoModels = videoModels;

    preCache(
      initialIndex,
      totalVideos: videoModels.length,
      getVideoModel: (index) => (index < 0 || index >= videoModels.length)
          ? null
          : videoModels[index],
    );

    await _videoCompleters[_focusedVideoController]?.future;
    _focusedVideoController?.play();
    LoggerUtils.print(
      1133,
      'Init: ${_videoControllers.keys.map((e) => e.videoUrl).toList()}, focused: ${_focusedVideoController?.dataSource}',
    );
  }

  void stopFocusedVideo() async {
    LoggerUtils.print(
      3001,
      'Dispose multi video videoUrl: controllers: ${_videoControllers.keys.map((e) => e.videoUrl).toList()} focusedVideo: ${_focusedVideo?.videoUrl} time: ${DateTime.now()}',
    );

    final SafeVideoPlayerController? videoPlayerController =
        _focusedVideoController;

    _videoModels = null;
    _focusedPageIndex = 0;

    await videoPlayerController?.pause();
  }

  bool get isMutedFocusedVideo =>
      (_focusedVideoController?.value.volume ?? 1.0) == 0.0;

  void switchMuteFocusedVideo() {
    final currentStatus = (_focusedVideoController?.value.volume ?? 1.0) == 0.0
        ? 1.0
        : 0.0;
    _focusedVideoController?.setVolume(currentStatus);
  }

  void playFocusedVideo() async {
    await _videoCompleters[_focusedVideoController]?.future;
    if (_isRunning) _focusedVideoController?.play();
  }

  void onChangePage(int index, List<T> videoModels) async {
    if (index < 0 || index >= videoModels.length) {
      return;
    }

    _videoModels = videoModels;

    int previousPageIndex = _focusedPageIndex;
    int currentPageIndex = index;
    _focusedPageIndex = currentPageIndex;

    final T? previousVideoModel =
        (previousPageIndex < 0 || previousPageIndex >= videoModels.length)
        ? null
        : videoModels[previousPageIndex];

    final T? currentVideoModel =
        (currentPageIndex < 0 || currentPageIndex >= videoModels.length)
        ? null
        : videoModels[currentPageIndex];

    LoggerUtils.print(
      3001,
      'OnChange: PrePauseStart current: ${currentVideoModel?.videoUrl} previous: ${previousVideoModel?.videoUrl} isRunning: $_isRunning time: ${DateTime.now()}',
    );
    _videoControllers[previousVideoModel]?.pause().then((value) async {
      await _videoCompleters[_videoControllers[currentVideoModel]]?.future;
      LoggerUtils.print(
        3001,
        'OnChange: CurPlayStart current: ${currentVideoModel?.videoUrl} previous: ${previousVideoModel?.videoUrl} isRunning: $_isRunning time: ${DateTime.now()}',
      );
      if (_isRunning &&
          currentVideoModel?.videoUrl == _focusedVideo?.videoUrl) {
        _videoControllers[currentVideoModel]?.play();
      }
      await _videoControllers[previousVideoModel]?.seekTo(Duration.zero);
    });
  }

  void preCache(
    int currentIndex, {
    required int totalVideos,
    required T? Function(int) getVideoModel,
    SafeVideoPlayerController Function(T)? controllerCreator,
  }) async {
    final T? currentVideoModel = getVideoModel(currentIndex);

    _initializeVideo(currentVideoModel, controllerCreator: controllerCreator);

    int rangeCenterPreIndex = _defaultCacheVideoCount ~/ 2;
    int rangeCenterPostIndex = totalVideos - (_defaultCacheVideoCount ~/ 2);

    int rangeCenterIndex = (rangeCenterPreIndex > rangeCenterPostIndex)
        ? currentIndex
        : currentIndex.clamp(rangeCenterPreIndex, rangeCenterPostIndex);
    int preCacheIndex = math.max(
      0,
      rangeCenterIndex - (_defaultCacheVideoCount ~/ 2),
    );
    int postCacheIndex = math.min(
      rangeCenterIndex + (_defaultCacheVideoCount ~/ 2),
      totalVideos,
    );

    int totalPreCache = preCacheIndex;
    int totalCache = postCacheIndex - preCacheIndex;
    int totalPostCache = (totalVideos - postCacheIndex);

    List<Future<void> Function()> preCachedDispose = List.generate(
      math.max(0, totalPreCache),
      (i) =>
          () => _onDisposeVideo(getVideoModel(i)),
    );
    List<Future<void> Function()> cachedInit = List.generate(
      math.max(0, totalCache),
      (i) =>
          () => _initializeVideo(
            getVideoModel(i + preCacheIndex),
            controllerCreator: controllerCreator,
          ),
    );
    List<Future<void> Function()> postCachedDispose = List.generate(
      math.max(0, totalPostCache),
      (i) =>
          () => _onDisposeVideo(getVideoModel(i + postCacheIndex)),
    );

    await Future.wait([
      ...preCachedDispose.sublist(preCachedDispose.length ~/ 2).map((e) => e()),
      ...postCachedDispose
          .sublist(0, postCachedDispose.length ~/ 2)
          .map((e) => e()),
    ]);

    await Future.wait([
      ...cachedInit
          .sublist(cachedInit.length ~/ 4, cachedInit.length ~/ 2)
          .map((e) => e()),
      ...cachedInit
          .sublist(cachedInit.length ~/ 2, ((cachedInit.length * 3) ~/ 4))
          .map((e) => e()),
    ]);

    await Future.wait([
      ...preCachedDispose
          .sublist(0, preCachedDispose.length ~/ 2)
          .map((e) => e()),
      ...postCachedDispose
          .sublist(postCachedDispose.length ~/ 2)
          .map((e) => e()),
      ...cachedInit.sublist(0, cachedInit.length ~/ 4).map((e) => e()),
      ...cachedInit.sublist((cachedInit.length * 3) ~/ 4).map((e) => e()),
    ]);
  }

  Future<void> _initializeVideo(
    T? videoModel, {
    SafeVideoPlayerController Function(T)? controllerCreator,
  }) async {
    if (videoModel == null || videoModel.videoUrl.isEmpty) return;

    if (!videoModel.isReadyToPlay) {
      SafeVideoPlayerController? controller = _videoControllers.remove(
        videoModel,
      );
      _videoCompleters.remove(controller);
      return;
    }

    SafeVideoPlayerController? localController = _videoControllers[videoModel];
    if (localController != null) return;

    SafeVideoPlayerController controller =
        controllerCreator?.call(videoModel) ??
        SafeVideoPlayerController.networkUrl(Uri.parse(videoModel.videoUrl));

    _videoControllers[videoModel] = controller;
    _videoCompleters[controller] = Completer();

    try {
      await _videoControllers[videoModel]?.initialize();
      _videoCompleters[controller]?.complete();
    } on Exception {
      _videoCompleters[controller]?.complete();
    }
  }

  Future<void> _onDisposeVideo(T? videoModel) async {
    if (videoModel == null) return;

    SafeVideoPlayerController? controller = _videoControllers[videoModel];
    if (controller == null) return;

    _videoControllers.remove(videoModel);
    _videoCompleters.remove(controller);

    await controller.dispose();
  }

  Future<void> _onPauseVideo(T? videoModel) async {
    if (videoModel == null) return;

    SafeVideoPlayerController? controller = _videoControllers[videoModel];
    if (controller == null) return;

    await controller.pause();
  }

  Future<void> clearAll() async {
    List<T> videoModels = _videoControllers.keys.toList();
    await Future.wait(videoModels.map((e) => _onPauseVideo(e)).toList());
    await Future.wait(videoModels.map((e) => _onDisposeVideo(e)).toList());
  }
}
