import 'dart:async';

class QueuedOperation<TOperationType> {
  final Future<void> Function() operation;
  final int priorityLevel;
  final Completer<void> completer;
  final TOperationType type;

  QueuedOperation({
    required this.operation,
    required this.priorityLevel,
    required this.completer,
    required this.type,
  });
}

class OperationQueue<TOperationType> {
  final _queue = <QueuedOperation<TOperationType>>[];

  List<TOperationType> get opQueueTypes => _queue.map((e) => e.type).toList();

  bool _isProcessing = false;

  void Function(dynamic error, StackTrace stackTrace)? onError;

  OperationQueue({this.onError});

  Future<void> enqueue(
    TOperationType type,
    Future<void> Function() operation, {
    int priorityLevel = 0,
  }) async {
    final completer = Completer<void>();

    final queuedOp = QueuedOperation(
      type: type,
      operation: operation,
      priorityLevel: priorityLevel,
      completer: completer,
    );

    _queue.add(queuedOp);
    _sortQueueByPriority();
    _processQueue();

    return completer.future;
  }

  void _sortQueueByPriority() {
    _queue.sort((a, b) {
      if (_queue.indexOf(a) == 0 && _isProcessing) return -1;
      if (_queue.indexOf(b) == 0 && _isProcessing) return 1;
      return b.priorityLevel.compareTo(a.priorityLevel);
    });
  }

  Future<void> _processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;

    _isProcessing = true;

    while (_queue.isNotEmpty) {
      final queuedOp = _queue.removeAt(0);

      try {
        await queuedOp.operation();
        queuedOp.completer.complete();
      } catch (e, stackTrace) {
        onError?.call(e, stackTrace);
        queuedOp.completer.completeError(e, stackTrace);
      }
    }

    _isProcessing = false;
  }

  void cancelAll() {
    for (int i = 1; i < _queue.length; i++) {
      _queue[i].completer.complete();
    }
    _queue.removeRange(1, _queue.length);
  }

  void cancelOperationsWhere(
      bool Function(QueuedOperation<TOperationType>) test) {
    final toCancel = _queue.where(test).toList();
    for (var op in toCancel) {
      op.completer.complete();
      _queue.remove(op);
    }
  }

  int get pendingOperations => _queue.length;

  bool get isProcessing => _isProcessing;
}
