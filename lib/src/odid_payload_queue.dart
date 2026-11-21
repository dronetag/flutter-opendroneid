import 'dart:async';
import 'dart:collection';

typedef PayloadHandler<T> = void Function(T payload);
typedef PayloadErrorHandler = void Function(Object error, StackTrace stack);
typedef ScheduleCallback = void Function(void Function() callback);

void _defaultSchedule(void Function() callback) => scheduleMicrotask(callback);

/// Buffers payloads delivered by a synchronous native callback and processes
/// them in a later microtask, so the native caller never runs Dart parsing.
class OdidPayloadQueue<T> {
  OdidPayloadQueue({
    required this.onPayload,
    ScheduleCallback schedule = _defaultSchedule,
    PayloadErrorHandler? onError,
    this.onOverflow,
    this.maxPending = 1024,
  }) : _schedule = schedule,
       _onError = onError ?? _rethrow;

  final PayloadHandler<T> onPayload;
  final ScheduleCallback _schedule;
  final PayloadErrorHandler _onError;
  final int maxPending;

  /// Called once, when the first payload is dropped because the queue is full.
  final void Function()? onOverflow;
  final Queue<T> _pending = Queue<T>();
  bool _drainScheduled = false;
  int _droppedPayloadCount = 0;

  int get droppedPayloadCount => _droppedPayloadCount;

  void add(T payload) {
    if (_pending.length >= maxPending) {
      final isFirstDrop = _droppedPayloadCount == 0;
      _pending.removeFirst();
      _droppedPayloadCount++;
      if (isFirstDrop) {
        onOverflow?.call();
      }
    }
    _pending.add(payload);
    if (_drainScheduled) {
      return;
    }
    _drainScheduled = true;
    _schedule(_drain);
  }

  void _drain() {
    _drainScheduled = false;
    while (_pending.isNotEmpty) {
      final payload = _pending.removeFirst();
      try {
        onPayload(payload);
      } catch (error, stack) {
        _onError(error, stack);
      }
    }
  }

  static void _rethrow(Object error, StackTrace stack) {
    Error.throwWithStackTrace(error, stack);
  }
}
