import 'package:video_player/video_player.dart';

import 'logger_utils.dart';
import 'operation_queue_utils.dart';

enum SafeVideoOperationType { init, play, pause, seekTo, dispose }

class SafeVideoPlayerController extends VideoPlayerController {
  SafeVideoPlayerController.networkUrl(super.url)
    : super.networkUrl(
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
      );

  SafeVideoPlayerController.file(super.file) : super.file();

  final OperationQueue<SafeVideoOperationType> _queue = OperationQueue();

  bool get isVideoEnded => value.isCompleted;

  bool get isVideoInitialized => value.isInitialized;

  bool get isVideoPlaying => value.isPlaying;

  Duration? get currentPosition =>
      value.position < totalDuration ? value.position : null;

  Duration get totalDuration => value.duration;

  List<DurationRange> get bufferedRanges => value.buffered;

  bool get isBuffering => value.isBuffering;

  bool get hasError => value.hasError;

  @override
  Future<void> initialize() async {
    LoggerUtils.print(
      3001,
      'Initialize op start videoUrl: $dataSource allOps: ${_queue.opQueueTypes} time: ${DateTime.now()}',
    );
    await _queue.enqueue(SafeVideoOperationType.init, () async {
      if (isVideoInitialized) return;

      try {
        LoggerUtils.print(
          3001,
          'Initialize start videoUrl: $dataSource allOps: ${_queue.opQueueTypes} time: ${DateTime.now()}',
        );
        await super.initialize();
        LoggerUtils.print(
          3001,
          'Initialize end videoUrl: $dataSource allOps: ${_queue.opQueueTypes} time: ${DateTime.now()}',
        );
      } on Exception catch (e) {
        LoggerUtils.print(
          3001,
          'Initialize Exception e: $e videoUrl: $dataSource allOps: ${_queue.opQueueTypes} time: ${DateTime.now()}',
        );
      }
    });
    LoggerUtils.print(
      3001,
      'Initialize op end videoUrl: $dataSource allOps: ${_queue.opQueueTypes} time: ${DateTime.now()}',
    );
  }

  @override
  Future<void> dispose() async {
    _queue.cancelOperationsWhere((e) {
      return e.type == SafeVideoOperationType.seekTo;
    });

    pause();
    LoggerUtils.print(
      3001,
      'Dispose op start videoUrl: $dataSource allOps: ${_queue.opQueueTypes} time: ${DateTime.now()}',
    );
    await _queue.enqueue(SafeVideoOperationType.dispose, () async {
      if (!isVideoInitialized) return;

      try {
        LoggerUtils.print(
          3001,
          'Dispose start videoUrl: $dataSource allOps: ${_queue.opQueueTypes} time: ${DateTime.now()}',
        );
        await super.dispose();
        LoggerUtils.print(
          3001,
          'Dispose end videoUrl: $dataSource allOps: ${_queue.opQueueTypes} time: ${DateTime.now()}',
        );
      } on Exception catch (e) {
        LoggerUtils.print(
          3001,
          'Dispose Exception e: $e videoUrl: $dataSource allOps: ${_queue.opQueueTypes} time: ${DateTime.now()}',
        );
      }
    });
    LoggerUtils.print(
      3001,
      'Dispose op end videoUrl: $dataSource allOps: ${_queue.opQueueTypes} time: ${DateTime.now()}',
    );
  }

  @override
  Future<void> pause() async {
    _queue.cancelOperationsWhere((e) {
      return e.type == SafeVideoOperationType.play ||
          e.type == SafeVideoOperationType.pause;
    });

    LoggerUtils.print(
      3001,
      'Pause op start videoUrl: $dataSource allOps: ${_queue.opQueueTypes} time: ${DateTime.now()}',
    );
    await _queue.enqueue(SafeVideoOperationType.pause, () async {
      if (!isVideoInitialized) return;

      try {
        LoggerUtils.print(
          3001,
          'Pause start videoUrl: $dataSource allOps: ${_queue.opQueueTypes} time: ${DateTime.now()}',
        );
        await super.pause();
        LoggerUtils.print(
          3001,
          'Pause end videoUrl: $dataSource allOps: ${_queue.opQueueTypes} time: ${DateTime.now()}',
        );
      } on Exception catch (e) {
        LoggerUtils.print(
          3001,
          'Pause Exception e: $e videoUrl: $dataSource allOps: ${_queue.opQueueTypes} time: ${DateTime.now()}',
        );
      }
    });
    LoggerUtils.print(
      3001,
      'Pause op end videoUrl: $dataSource allOps: ${_queue.opQueueTypes} time: ${DateTime.now()}',
    );
  }

  @override
  Future<void> play() async {
    _queue.cancelOperationsWhere((e) {
      return e.type == SafeVideoOperationType.play ||
          e.type == SafeVideoOperationType.pause;
    });

    LoggerUtils.print(
      3001,
      'Play op start videoUrl: $dataSource allOps: ${_queue.opQueueTypes} time: ${DateTime.now()}',
    );
    await _queue.enqueue(SafeVideoOperationType.play, () async {
      if (!isVideoInitialized) return;

      try {
        LoggerUtils.print(
          3001,
          'Play start videoUrl: $dataSource allOps: ${_queue.opQueueTypes} time: ${DateTime.now()}',
        );
        await super.play();
        LoggerUtils.print(
          3001,
          'Play end videoUrl: $dataSource allOps: ${_queue.opQueueTypes} time: ${DateTime.now()}',
        );
      } on Exception catch (e) {
        LoggerUtils.print(
          3001,
          'Play Exception e: $e videoUrl: $dataSource allOps: ${_queue.opQueueTypes} time: ${DateTime.now()}',
        );
      }
    });
    LoggerUtils.print(
      3001,
      'Play op end videoUrl: $dataSource allOps: ${_queue.opQueueTypes} time: ${DateTime.now()}',
    );
  }

  @override
  Future<void> seekTo(Duration position) async {
    _queue.cancelOperationsWhere((e) {
      return e.type == SafeVideoOperationType.seekTo;
    });

    LoggerUtils.print(
      3001,
      'Seek op start videoUrl: $dataSource allOps: ${_queue.opQueueTypes} time: ${DateTime.now()}',
    );
    await _queue.enqueue(SafeVideoOperationType.seekTo, () async {
      if (!isVideoInitialized) return;

      try {
        LoggerUtils.print(
          3001,
          'Seek start videoUrl: $dataSource allOps: ${_queue.opQueueTypes} time: ${DateTime.now()}',
        );
        await super.seekTo(position);
        LoggerUtils.print(
          3001,
          'Seek end videoUrl: $dataSource allOps: ${_queue.opQueueTypes} time: ${DateTime.now()}',
        );
      } on Exception catch (e) {
        LoggerUtils.print(
          3001,
          'Seek Exception e: $e videoUrl: $dataSource allOps: ${_queue.opQueueTypes} time: ${DateTime.now()}',
        );
      }
    });
    LoggerUtils.print(
      3001,
      'Seek op end videoUrl: $dataSource allOps: ${_queue.opQueueTypes} time: ${DateTime.now()}',
    );
  }

  Future<void> reset() async {
    await pause();
    await seekTo(Duration.zero);
  }

  @override
  String toString() => dataSource;
}
