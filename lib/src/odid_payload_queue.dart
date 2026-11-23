import 'dart:async';
import 'dart:collection';

typedef PayloadHandler<T> = void Function(T payload);
typedef PayloadErrorHandler = void Function(Object error, StackTrace stack);
typedef ScheduleCallback = void Function(void Function() callback);

/// Schedules [callback] as an event-loop task.
///
/// A microtask is not enough: JNI and FFI callbacks invoked on the platform
/// thread enter the isolate directly, outside the event loop, and microtasks
/// queued there only run when some unrelated event arrives later. A
/// zero-duration timer posts a message to the isolate, which wakes the event
/// loop and flushes microtasks (stream deliveries, `setState`) afterwards.
void _defaultSchedule(void Function() callback) => Timer.run(callback);

/// Buffers payloads delivered by a synchronous native callback and processes
/// them in a later event-loop task, so the native caller never runs Dart
/// parsing.
///
/// Guarantees:
/// * payloads are delivered in arrival order;
/// * at most one drain is scheduled at a time;
/// * a throwing [onPayload] is reported to [onError] and does not stop later
///   payloads from being processed;
/// * when more than [maxPending] payloads are waiting, the oldest is dropped
///   and [onOverflow] fires once per overflow episode.
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
  ///
  /// The counter keeps increasing while the queue stays full, but the callback
  /// is not repeated until a later overflow episode.
  final void Function()? onOverflow;
  final Queue<T> _pending = Queue<T>();
  bool _drainScheduled = false;
  int _droppedPayloadCount = 0;

  /// Total payloads discarded because the queue was full.
  int get droppedPayloadCount => _droppedPayloadCount;

  /// Enqueues [payload] and schedules a drain if none is pending.
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

  /// Delivers every queued payload. Errors are isolated per payload.
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
