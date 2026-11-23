import 'package:flutter_opendroneid/src/odid_payload_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('schedules one drain and delivers in order', () {
    final scheduled = <void Function()>[];
    final delivered = <int>[];
    final queue = OdidPayloadQueue<int>(
      onPayload: delivered.add,
      schedule: scheduled.add,
    );

    queue.add(1);
    queue.add(2);

    expect(delivered, isEmpty);
    expect(scheduled, hasLength(1));

    scheduled.single();

    expect(delivered, <int>[1, 2]);
  });

  test('reschedules after a drain', () {
    final scheduled = <void Function()>[];
    final delivered = <int>[];
    final queue = OdidPayloadQueue<int>(
      onPayload: delivered.add,
      schedule: scheduled.add,
    );

    queue.add(1);
    scheduled.removeAt(0)();
    queue.add(2);

    expect(scheduled, hasLength(1));
    scheduled.removeAt(0)();

    expect(delivered, <int>[1, 2]);
  });

  test('reports an error and continues with later payloads', () {
    final scheduled = <void Function()>[];
    final delivered = <int>[];
    final errors = <Object>[];
    final queue = OdidPayloadQueue<int>(
      onPayload: (payload) {
        if (payload == 1) {
          throw StateError('parse failed');
        }
        delivered.add(payload);
      },
      onError: (error, _) => errors.add(error),
      schedule: scheduled.add,
    );

    queue.add(1);
    queue.add(2);
    scheduled.removeAt(0)();

    expect(delivered, <int>[2]);
    expect(errors.single, isA<StateError>());
  });

  test('drops the oldest payload when the queue is full', () {
    final scheduled = <void Function()>[];
    final delivered = <int>[];
    var overflowCalls = 0;
    final queue = OdidPayloadQueue<int>(
      maxPending: 2,
      onPayload: delivered.add,
      onOverflow: () => overflowCalls++,
      schedule: scheduled.add,
    );

    queue.add(1);
    queue.add(2);
    queue.add(3);
    queue.add(4);
    scheduled.removeAt(0)();

    expect(delivered, <int>[3, 4]);
    expect(queue.droppedPayloadCount, 2);
    expect(overflowCalls, 1);
  });

  test('default schedule drains in an event-loop task, not a microtask', () async {
    // Native interop callbacks enter the isolate outside the event loop, so a
    // microtask scheduled there may never run; the drain must be a real event.
    final delivered = <int>[];
    final queue = OdidPayloadQueue<int>(onPayload: delivered.add);

    queue.add(1);
    await Future<void>.microtask(() {});

    expect(delivered, isEmpty);

    await Future<void>.delayed(Duration.zero);

    expect(delivered, <int>[1]);
  });
}
