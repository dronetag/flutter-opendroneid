# Pigeon Native Interop Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace all platform-channel traffic in `flutter_opendroneid` with Pigeon 30 native interop (FFI on iOS, JNI on Android) while keeping the public Dart API unchanged.

**Architecture:** A synchronous `@HostApi` (`OdidScannerHostApi`) is generated into direct FFI/JNI bindings. The four hand-written `EventChannel`s are replaced by one `@FlutterApi` (`OdidScannerFlutterApi`) that native scanners call directly. Dart callbacks only enqueue payloads; parsing runs in a microtask drain so the native thread is never blocked.

**Tech Stack:** Flutter 3.50 / Dart 3.14, Pigeon 30.0.4 (native interop preview), FFIgen, JNIgen, Kotlin (AGP 9 built-in Kotlin), Swift + Objective-C bridge, CocoaPods.

**Spec:** `docs/superpowers/specs/2026-11-21-pigeon-native-interop-design.md`

## Global Constraints

- `pubspec.yaml`: `sdk: ^3.14.0`, `flutter: ">=3.50.0"`.
- Pigeon `^30.0.4`; `jni: ^1.1.1`; `jnigen: ^1.0.0` (dev); `objective_c: ">=9.6.2 <9.6.3"`.
- Pigeon config: `appDirectory: 'example'`, `kotlinOptions: KotlinOptions(useJni: true)`,
  `swiftOptions: SwiftOptions(useFfi: true, ffiModuleName: 'flutter_opendroneid', includeErrorClass: true)`.
- No `@async`, `@TaskQueue`, `@EventChannelApi`, or `@ProxyApi` in `pigeon/messages.dart`.
- Android: `compileSdk 36`, `targetSdk 36`, `minSdk 24`, Java 17, AGP 9.3.1, Gradle 9.5,
  `android.builtInKotlin=true`, no manual `kotlin-android` plugin.
- iOS: deployment target 13.0; podspec compiles `Classes/**/*.{swift,m,h}` and
  `Classes_objc_gen/**/*.{m,h}`; CocoaPods only (no `Package.swift`).
- Public Dart API (`FlutterOpenDroneId` members, streams, models, exception types) must not change.
- Do not reorder enums (`ScanPriority`, `MessageSource`, `BluetoothState`, `WifiState`,
  `BluetoothPhy`) — their ordinals cross the FFI/JNI boundary.
- Generated `.o` files under `*_objc_gen/` are never committed.

## Review Focus

1. **Payload arrives before Dart registers the Flutter API** — the sink must drop it without
   crashing, and later payloads must still flow after `initialize()`. Pinned by the per-callback
   null guard in Task 5/6 and manual smoke in Task 8.
2. **Malformed ODID payload** — one parse failure must not stop the queue or lose later
   payloads; the error must still surface as an uncaught error. Pinned in Task 1 tests.
3. **Payload burst while a drain is scheduled** — all payloads are delivered exactly once, in
   order, with one scheduled callback. Pinned in Task 1 tests.
4. **iOS callback from the Bluetooth queue** — direct callbacks must reach Dart on the main
   queue. Pinned by the explicit marshalling in Task 6 and manual smoke in Task 8.
5. **Enum ordinal drift** — a reordered enum silently corrupts metadata. Pinned by the ABI test
   in Task 3.

---

### Task 1: Dependencies and payload queue

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/src/odid_payload_queue.dart`
- Create: `test/odid_payload_queue_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `class OdidPayloadQueue` with `OdidPayloadQueue({required void Function(ODIDPayload) onPayload, void Function(Object, StackTrace)? onError, void Function(void Function()) schedule = _defaultSchedule, int maxPending = 1024})`, `void add(ODIDPayload payload)`, and `int get droppedPayloadCount`.
- Produces test helper `payload(int sequence) -> ODIDPayload` used again in Task 3.

- [ ] **Step 1: Add dependencies**

Run:
```bash
flutter pub add ffi objective_c:'>=9.6.2 <9.6.3' meta jni:'^1.1.1'
flutter pub add dev:pigeon:'^30.0.4' dev:ffigen dev:jnigen:'^1.0.0' dev:swift2objc dev:swiftgen dev:path dev:pub_semver
```
Then set in `pubspec.yaml`:
```yaml
environment:
  sdk: ^3.14.0
  flutter: ">=3.50.0"
```

- [ ] **Step 2: Write the failing queue tests**

Create `test/odid_payload_queue_test.dart`:
```dart
import 'dart:typed_data';

import 'package:flutter_opendroneid/src/odid_payload_queue.dart';
import 'package:flutter_opendroneid/src/pigeon/messages.g.dart';
import 'package:flutter_test/flutter_test.dart';

ODIDPayload payload(int sequence) => ODIDPayload(
      rawData: Uint8List.fromList(<int>[sequence]),
      receivedTimestamp: sequence,
      metadata: ODIDMetadata(
        macAddress: 'aa:bb:cc:dd:ee:ff',
        source: MessageSource.Unknown,
      ),
    );

void main() {
  test('schedules one drain and delivers in order', () {
    final scheduled = <void Function()>[];
    final delivered = <ODIDPayload>[];
    final queue = OdidPayloadQueue(
      onPayload: delivered.add,
      schedule: scheduled.add,
    );

    queue.add(payload(1));
    queue.add(payload(2));

    expect(delivered, isEmpty);
    expect(scheduled, hasLength(1));

    scheduled.single();

    expect(delivered.map((p) => p.receivedTimestamp), <int>[1, 2]);
  });

  test('reschedules after a drain', () {
    final scheduled = <void Function()>[];
    final delivered = <ODIDPayload>[];
    final queue = OdidPayloadQueue(
      onPayload: delivered.add,
      schedule: scheduled.add,
    );

    queue.add(payload(1));
    scheduled.removeAt(0)();
    queue.add(payload(2));

    expect(scheduled, hasLength(1));
    scheduled.removeAt(0)();

    expect(delivered.map((p) => p.receivedTimestamp), <int>[1, 2]);
  });

  test('reports an error and continues with later payloads', () {
    final scheduled = <void Function()>[];
    final delivered = <int>[];
    final errors = <Object>[];
    final queue = OdidPayloadQueue(
      onPayload: (p) {
        if (p.receivedTimestamp == 1) {
          throw StateError('parse failed');
        }
        delivered.add(p.receivedTimestamp);
      },
      onError: (error, _) => errors.add(error),
      schedule: scheduled.add,
    );

    queue.add(payload(1));
    queue.add(payload(2));
    scheduled.removeAt(0)();

    expect(delivered, <int>[2]);
    expect(errors.single, isA<StateError>());
  });

  test('drops the oldest payload when the queue is full', () {
    final scheduled = <void Function()>[];
    final delivered = <int>[];
    final queue = OdidPayloadQueue(
      maxPending: 2,
      onPayload: (p) => delivered.add(p.receivedTimestamp),
      schedule: scheduled.add,
    );

    queue.add(payload(1));
    queue.add(payload(2));
    queue.add(payload(3));
    scheduled.removeAt(0)();

    expect(delivered, <int>[2, 3]);
    expect(queue.droppedPayloadCount, 1);
  });
}
```

- [ ] **Step 3: Run the tests to verify they fail**

Run: `flutter test test/odid_payload_queue_test.dart`
Expected: FAIL — `Error: Couldn't resolve the package 'flutter_opendroneid' ... messages.g.dart` and `OdidPayloadQueue` undefined.

- [ ] **Step 4: Implement the queue**

Create `lib/src/odid_payload_queue.dart`:
```dart
import 'dart:async';
import 'dart:collection';

import 'package:flutter_opendroneid/src/pigeon/messages.g.dart';

typedef PayloadHandler = void Function(ODIDPayload payload);
typedef PayloadErrorHandler = void Function(Object error, StackTrace stack);
typedef ScheduleCallback = void Function(void Function() callback);

void _defaultSchedule(void Function() callback) => scheduleMicrotask(callback);

/// Buffers payloads delivered by a synchronous native callback and processes
/// them in a later microtask, so the native caller never runs Dart parsing.
class OdidPayloadQueue {
  OdidPayloadQueue({
    required this.onPayload,
    ScheduleCallback schedule = _defaultSchedule,
    PayloadErrorHandler? onError,
    this.maxPending = 1024,
  })  : _schedule = schedule,
        _onError = onError ?? _rethrow;

  final PayloadHandler onPayload;
  final ScheduleCallback _schedule;
  final PayloadErrorHandler _onError;
  final int maxPending;
  final Queue<ODIDPayload> _pending = Queue<ODIDPayload>();
  bool _drainScheduled = false;
  int _droppedPayloadCount = 0;

  int get droppedPayloadCount => _droppedPayloadCount;

  void add(ODIDPayload payload) {
    if (_pending.length >= maxPending) {
      _pending.removeFirst();
      _droppedPayloadCount++;
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
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test test/odid_payload_queue_test.dart`
Expected: `All tests passed!` (4 tests).

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/src/odid_payload_queue.dart test/odid_payload_queue_test.dart
git commit -m "feat: add direct-interop payload queue and dependencies"
```

---

### Task 2: Pigeon schema and first generation

**Files:**
- Create: `pigeon/messages.dart`
- Delete: `pigeon/schema.dart`
- Modify: `scripts/pigeon_generate.sh`
- Generated: `lib/src/pigeon/messages.g.dart`, `messages.native_interop.g.dart`, `messages.g.ffi.dart`, `messages.g.jni.dart`, `tool/pigeon/messages_{ffigen,jnigen}_config.dart`, `android/src/main/kotlin/cz/dronetag/flutter_opendroneid/Messages.g.kt`, `ios/Classes/Messages.g.swift`, `ios/Classes_objc_gen/**`.

**Interfaces:**
- Consumes: nothing.
- Produces: Dart `OdidScannerHostApi` (with `static OdidScannerHostApi createWithNativeInteropApi({String? messageChannelSuffix})`, synchronous methods except `Future<int> bluetoothState()`), `OdidScannerFlutterApi` (with `static void setUp(OdidScannerFlutterApi? api)` and `onOdidPayload`/`onBluetoothScanActive`/`onWifiScanActive`), `ODIDPayload`, `ODIDMetadata`, `MessageSource`, `ScanPriority`, `BluetoothState`, `WifiState`, `BluetoothPhy`.
- Produces native: Kotlin `OdidScannerHostApi`, `OdidScannerHostApiRegistrar`, `OdidScannerFlutterApi`, `OdidScannerFlutterApiRegistrar`, `MessagesError`; Swift `OdidScannerHostApi`, `OdidScannerHostApiSetup`, `OdidScannerFlutterApi`, `OdidScannerFlutterApiRegistrar`, `PigeonError`.

- [ ] **Step 1: Write the schema**

Create `pigeon/messages.dart`:
```dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    appDirectory: 'example',
    dartOptions: DartOptions(),
    kotlinOptions: KotlinOptions(useJni: true),
    swiftOptions: SwiftOptions(
      useFfi: true,
      ffiModuleName: 'flutter_opendroneid',
      includeErrorClass: true,
    ),
  ),
)
enum ScanPriority { High, Low }

enum MessageSource {
  BluetoothLegacy,
  BluetoothLongRange,
  WifiNan,
  WifiBeacon,
  Unknown,
}

enum BluetoothState { Unknown, Resetting, Unsupported, Unauthorized, PoweredOff, PoweredOn }

enum WifiState { Disabling, Disabled, Enabling, Enabled }

enum BluetoothPhy { None, Phy1M, Phy2M, PhyLECoded, Unknown }

class ODIDMetadata {
  ODIDMetadata({
    required this.macAddress,
    required this.source,
    this.rssi,
    this.btName,
    this.frequency,
    this.centerFreq0,
    this.centerFreq1,
    this.channelWidthMhz,
    this.primaryPhy,
    this.secondaryPhy,
  });

  final String macAddress;
  final MessageSource source;
  final int? rssi;
  final String? btName;
  final int? frequency;
  final int? centerFreq0;
  final int? centerFreq1;
  final int? channelWidthMhz;
  final BluetoothPhy? primaryPhy;
  final BluetoothPhy? secondaryPhy;
}

class ODIDPayload {
  ODIDPayload(this.rawData, this.receivedTimestamp, this.metadata);

  final Uint8List rawData;
  final int receivedTimestamp;
  final ODIDMetadata metadata;
}

@HostApi()
abstract class OdidScannerHostApi {
  void initialize();
  bool isInitialized();
  void startScanBluetooth(String? serviceUuid);
  void startScanWifi();
  void stopScanBluetooth();
  void stopScanWifi();
  void setBtScanPriority(ScanPriority priority);
  void setBtServiceUuid(String? serviceUuid);
  bool isScanningBluetooth();
  bool isScanningWifi();
  @async
  int bluetoothState();
  int wifiState();
  bool btExtendedSupported();
  int btMaxAdvDataLen();
  bool wifiNaNSupported();
}

@FlutterApi()
abstract class OdidScannerFlutterApi {
  void onOdidPayload(ODIDPayload payload);
  void onBluetoothScanActive(bool isActive);
  void onWifiScanActive(bool isActive);
}
```
Delete `pigeon/schema.dart`.

- [ ] **Step 2: Rewrite the generation script**

Replace `scripts/pigeon_generate.sh` with:
```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

run_pigeon() {
  dart run pigeon \
    --input pigeon/messages.dart \
    --dart_out lib/src/pigeon \
    --kotlin_out android/src/main/kotlin/cz/dronetag/flutter_opendroneid \
    --kotlin_package cz.dronetag.flutter_opendroneid \
    --swift_out ios/Classes
}

# First pass emits the Kotlin/Swift bridges. The JNI Dart bindings need the
# generated Kotlin compiled, so a failure here is expected on a clean tree.
if ! run_pigeon; then
  echo "First Pigeon pass incomplete; compiling Kotlin and retrying." >&2
fi

(cd example/android && ./gradlew :flutter_opendroneid:compileDebugKotlin)

# Second pass must succeed and produce the JNI/FFI companion files.
run_pigeon
```

- [ ] **Step 3: Run the generator**

Run: `chmod +x scripts/pigeon_generate.sh && ./scripts/pigeon_generate.sh`
Expected on a clean tree: the first pass may print a JNIgen error; the Gradle compile and the
second pass succeed. If Gradle fails because the old Kotlin implementation no longer matches,
stop here and resume generation at the end of Task 5 (native implementation); the generated
`Messages.g.kt` from the first pass is the interface to implement against.

- [ ] **Step 4: Verify the generated surface**

Run:
```bash
ls lib/src/pigeon
grep -n "class OdidScannerHostApi\|createWithNativeInteropApi" lib/src/pigeon/messages.g.dart
grep -n "class OdidScannerFlutterApi\|void setUp" lib/src/pigeon/messages.g.dart
grep -n "class OdidScannerHostApiRegistrar\|interface OdidScannerHostApi" android/src/main/kotlin/cz/dronetag/flutter_opendroneid/Messages.g.kt
grep -n "protocol OdidScannerHostApi\|class OdidScannerHostApiSetup" ios/Classes/Messages.g.swift
grep -rn "EventChannel" lib/src/pigeon || true
```
Expected: `messages.g.dart`, `messages.native_interop.g.dart`, `messages.g.ffi.dart`,
`messages.g.jni.dart` exist; the grep lines are found; the `EventChannel` grep prints nothing.

- [ ] **Step 5: Commit**

```bash
git add pigeon scripts lib/src/pigeon tool/pigeon android/src/main/kotlin/cz/dronetag/flutter_opendroneid/Messages.g.kt ios/Classes/Messages.g.swift ios/Classes_objc_gen
git add -u pigeon/schema.dart
git commit -m "feat: add Pigeon native interop schema and generated bindings"
```

---

### Task 3: Dart client rewrite

**Files:**
- Modify: `lib/flutter_opendroneid.dart`
- Modify: `lib/pigeon.dart` (becomes a deprecated re-export)
- Modify: `lib/models/received_odid_message.dart`, `lib/exceptions/odid_message_parsing_exception.dart`
- Create: `test/pigeon_abi_test.dart`

**Interfaces:**
- Consumes: `OdidScannerHostApi`, `OdidScannerFlutterApi`, `ODIDPayload` from Task 2; `OdidPayloadQueue` from Task 1.
- Produces: unchanged public `FlutterOpenDroneId` API; `Stream<ReceivedODIDMessage> get receivedMessages`; `Stream<pigeon.ODIDPayload> get rawMessages`; `Stream<bool> get bluetoothState`; `Stream<bool> get wifiState`; `class FlutterOpenDroneIdPlugin { static void registerWith(); }` for `dartPluginClass`.

- [ ] **Step 1: Write the ABI test**

Create `test/pigeon_abi_test.dart`:
```dart
import 'package:flutter_opendroneid/src/pigeon/messages.g.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('enum ordinals are a stable ABI', () {
    expect(ScanPriority.values, <ScanPriority>[ScanPriority.High, ScanPriority.Low]);
    expect(MessageSource.values, <MessageSource>[
      MessageSource.BluetoothLegacy,
      MessageSource.BluetoothLongRange,
      MessageSource.WifiNan,
      MessageSource.WifiBeacon,
      MessageSource.Unknown,
    ]);
    expect(BluetoothState.values, <BluetoothState>[
      BluetoothState.Unknown,
      BluetoothState.Resetting,
      BluetoothState.Unsupported,
      BluetoothState.Unauthorized,
      BluetoothState.PoweredOff,
      BluetoothState.PoweredOn,
    ]);
    expect(WifiState.values, <WifiState>[
      WifiState.Disabling,
      WifiState.Disabled,
      WifiState.Enabling,
      WifiState.Enabled,
    ]);
    expect(BluetoothPhy.values, <BluetoothPhy>[
      BluetoothPhy.None,
      BluetoothPhy.Phy1M,
      BluetoothPhy.Phy2M,
      BluetoothPhy.PhyLECoded,
      BluetoothPhy.Unknown,
    ]);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/pigeon_abi_test.dart`
Expected: FAIL — generated `messages.g.dart` exists but the public enum names/order do not
match when the schema is wrong; after Task 2 with the exact schema above it may already pass.
If it passes immediately, keep it as the regression guard.

- [ ] **Step 3: Rewrite the client**

Modify `lib/flutter_opendroneid.dart`:
```dart
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_opendroneid/src/odid_payload_queue.dart';
import 'package:flutter_opendroneid/src/pigeon/messages.g.dart' as pigeon;
```
Remove the four `EventChannel` fields and both event subscriptions. Add:
```dart
static pigeon.OdidScannerHostApi? _apiOverride;

static pigeon.OdidScannerHostApi get _api =>
    _apiOverride ??= pigeon.OdidScannerHostApi.createWithNativeInteropApi();

@visibleForTesting
static set debugApi(pigeon.OdidScannerHostApi api) => _apiOverride = api;

static final _bluetoothScanActiveController = StreamController<bool>.broadcast();
static final _wifiScanActiveController = StreamController<bool>.broadcast();

static final OdidPayloadQueue _payloadQueue = OdidPayloadQueue(
  onPayload: _handlePayload,
  onError: (Object error, StackTrace stack) =>
      Zone.current.handleUncaughtError(error, stack),
);

static bool _flutterApiRegistered = false;

static void _registerFlutterApi() {
  if (_flutterApiRegistered) return;
  _flutterApiRegistered = true;
  pigeon.OdidScannerFlutterApi.setUp(_FlutterApiImpl());
}

static Stream<bool> get bluetoothState => _bluetoothScanActiveController.stream;
static Stream<bool> get wifiState => _wifiScanActiveController.stream;

static Future<void> initialize() async {
  _registerFlutterApi();
  _api.initialize();
}
```
Add the implementation class at the bottom of the file:
```dart
class _FlutterApiImpl implements pigeon.OdidScannerFlutterApi {
  @override
  void onOdidPayload(pigeon.ODIDPayload payload) =>
      FlutterOpenDroneId._payloadQueue.add(payload);

  @override
  void onBluetoothScanActive(bool isActive) =>
      FlutterOpenDroneId._bluetoothScanActiveController.add(isActive);

  @override
  void onWifiScanActive(bool isActive) =>
      FlutterOpenDroneId._wifiScanActiveController.add(isActive);
}

/// Registered by Flutter as the plugin's `dartPluginClass`, including on hot restart.
class FlutterOpenDroneIdPlugin {
  static void registerWith() => FlutterOpenDroneId._registerFlutterApi();
}
```
Update every host call to the new names and remove `await` from direct calls, keeping the
`Future` signatures:
```dart
static Future<bool> get btTurnedOn async =>
    await _api.bluetoothState() ==
    pigeon.BluetoothState.values.indexOf(pigeon.BluetoothState.PoweredOn);

static Future<void> startScan(DriSourceType sourceType,
    {String? bluetoothServiceUuid = 'fffa'}) async {
  if (sourceType == DriSourceType.Bluetooth) {
    await _assertBluetoothPermissions();
    _api.startScanBluetooth(bluetoothServiceUuid);
  } else if (sourceType == DriSourceType.Wifi) {
    await _assertWifiPermissions();
    _api.startScanWifi();
  }
}

static Future<void> stopScan(DriSourceType sourceType) async {
  if (sourceType == DriSourceType.Bluetooth && _api.isScanningBluetooth()) {
    _api.stopScanBluetooth();
  }
  if (sourceType == DriSourceType.Wifi && _api.isScanningWifi()) {
    _api.stopScanWifi();
  }
}
```
Apply the same mechanical change to `setBtScanPriority`, `setBtServiceUuid`,
`isScanningBluetooth`, `isBluetoothExtendedSupported`, `isWifiNanSupported`,
`btMaxAdvDataLen`, `isScanningWifi`, `isInitialized`, `wifiTurnedOn`.

Replace `lib/pigeon.dart` with a deprecated re-export so the existing import path keeps
working for models:
```dart
@Deprecated(
  'Import package:flutter_opendroneid/src/pigeon/messages.g.dart instead. '
  'This path only re-exports generated models and will be removed in 3.0.0.',
)
library;

export 'src/pigeon/messages.g.dart';
```
Change imports in `received_odid_message.dart`, `odid_message_parsing_exception.dart`, and
`flutter_opendroneid.dart` to `package:flutter_opendroneid/src/pigeon/messages.g.dart`.

- [ ] **Step 4: Verify analysis and tests**

Run: `flutter analyze && flutter test`
Expected: no errors; all tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib test
git add -u lib/pigeon.dart
git commit -m "feat: call native scanners through Pigeon native interop"
```

---

### Task 4: Android Gradle modernization

**Files:**
- Modify: `android/build.gradle`, `android/gradle.properties`
- Modify: `example/android/settings.gradle.kts`, `example/android/app/build.gradle.kts`, `example/android/gradle/wrapper/gradle-wrapper.properties`, `example/android/gradle.properties`

**Interfaces:**
- Consumes: nothing.
- Produces: AGP 9 project with built-in Kotlin so `Messages.g.kt` compiles.

- [ ] **Step 1: Update the example app**

`example/android/settings.gradle.kts`: change the AGP version to `9.3.1` and remove
`id("org.jetbrains.kotlin.android") version "1.8.22" apply false`.

`example/android/gradle/wrapper/gradle-wrapper.properties`: set
`distributionUrl=https\://services.gradle.org/distributions/gradle-9.5.0-bin.zip`.

`example/android/gradle.properties`: add `android.builtInKotlin=true` and
`android.newDsl=false`.

`example/android/app/build.gradle.kts`: remove `id("kotlin-android")`, remove the
`kotlinOptions { ... }` block, set `sourceCompatibility`/`targetCompatibility` to
`JavaVersion.VERSION_17`.

- [ ] **Step 2: Update the plugin Gradle file**

Replace `android/build.gradle` with:
```groovy
group 'cz.dronetag.flutter_opendroneid'
version '1.0-SNAPSHOT'

plugins {
    id 'com.android.library'
}

android {
    namespace = "cz.dronetag.flutter_opendroneid"

    compileSdk 36

    defaultConfig {
        minSdk 24
        targetSdk 36
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    implementation 'org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2'
}
```
Replace `android/gradle.properties` with:
```properties
org.gradle.jvmargs=-Xmx1536M
android.useAndroidX=true
```

- [ ] **Step 3: Verify Gradle configuration**

Run: `cd example && flutter build apk --debug --config-only`
Expected: build completes without Gradle/AGP/Kotlin configuration errors. (Kotlin compilation
is not expected to pass yet; that is Task 5.)

- [ ] **Step 4: Commit**

```bash
git add android example/android
git commit -m "build(android): move example and plugin to AGP 9 built-in Kotlin"
```

---

### Task 5: Android native implementation

**Files:**
- Delete: `android/src/main/java/cz/dronetag/flutter_opendroneid/Pigeon.java`, `android/src/main/kotlin/cz/dronetag/flutter_opendroneid/StreamHandler.kt`
- Create: `android/src/main/kotlin/cz/dronetag/flutter_opendroneid/OdidSink.kt`
- Modify: `FlutterOpendroneidPlugin.kt`, `scanner/ODIDScanner.kt`, `scanner/BluetoothScanner.kt`, `scanner/WifiScanner.kt`, `scanner/WifiNaNScanner.kt`

**Interfaces:**
- Consumes: `OdidScannerHostApi`, `OdidScannerFlutterApi`, `OdidScannerFlutterApiRegistrar`, `MessagesError`, `ODIDPayload`, `ODIDMetadata` from Task 2.
- Produces: `internal interface OdidSink { fun onPayload(payload: ODIDPayload); fun onBluetoothScanActive(isActive: Boolean); fun onWifiScanActive(isActive: Boolean) }`.

- [ ] **Step 1: Add the sink**

Create `android/src/main/kotlin/cz/dronetag/flutter_opendroneid/OdidSink.kt`:
```kotlin
package cz.dronetag.flutter_opendroneid

import android.os.Handler
import android.os.Looper
import io.flutter.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin

internal interface OdidSink {
    fun onPayload(payload: ODIDPayload)
    fun onBluetoothScanActive(isActive: Boolean)
    fun onWifiScanActive(isActive: Boolean)
}

internal class FlutterApiSink(
    private val binding: FlutterPlugin.FlutterPluginBinding,
) : OdidSink {
    private val mainHandler = Handler(Looper.getMainLooper())

    private fun onMain(block: () -> Unit) {
        if (Looper.myLooper() == Looper.getMainLooper()) block() else mainHandler.post(block)
    }

    private fun withApi(block: (OdidScannerFlutterApi) -> Unit) {
        onMain {
            val api = OdidScannerFlutterApiRegistrar().getInstance(binding) ?: return@onMain
            try {
                block(api)
            } catch (error: Throwable) {
                // A stale registration can survive a hot restart; never crash the scanner.
                Log.w("FlutterOpenDroneId", "Dropping native callback", error)
            }
        }
    }

    override fun onPayload(payload: ODIDPayload) = withApi { it.onOdidPayload(payload) }

    override fun onBluetoothScanActive(isActive: Boolean) =
        withApi { it.onBluetoothScanActive(isActive) }

    override fun onWifiScanActive(isActive: Boolean) =
        withApi { it.onWifiScanActive(isActive) }
}
```

- [ ] **Step 2: Update the scanners**

In `ODIDScanner.kt`: change the constructor parameter to `private val sink: OdidSink`, and in
`receiveData` replace `odidPayloadStreamHandler.send(payload)` with `sink.onPayload(payload)`.

In `BluetoothScanner.kt`: constructor becomes `BluetoothScanner(private val sink: OdidSink)`;
replace `bluetoothStateHandler.send(...)` with `sink.onBluetoothScanActive(...)`; replace
`Pigeon.ODIDMetadata.Builder()` with `ODIDMetadata(...)` and
`Pigeon.MessageSource.BLUETOOTH_LEGACY` with `MessageSource.BLUETOOTH_LEGACY` (verify exact
generated casing).

In `WifiScanner.kt` and `WifiNaNScanner.kt`: take `sink: OdidSink` instead of
`wifiStateHandler`, and replace `.send(...)` with `sink.onWifiScanActive(...)`; replace
`Pigeon.ODIDMetadata.Builder()`/`Pigeon.ODIDPayload.Builder()` with direct constructors.

- [ ] **Step 3: Update the plugin**

In `FlutterOpendroneidPlugin.kt`:
- Change `class FlutterOpendroneidPlugin : FlutterPlugin, ActivityAware, Pigeon.Api` to
  `..., OdidScannerHostApi`.
- Remove all four `StreamHandler` fields. Add `private lateinit var sink: FlutterApiSink`.
- `onAttachedToEngine`: `sink = FlutterApiSink(flutterPluginBinding)` and
  `OdidScannerHostApiRegistrar().register(this, flutterPluginBinding)`; remove `Pigeon.Api.setup`
  and `StreamHandler.bindMultipleHandlers`.
- `onDetachedFromEngine`: `OdidScannerHostApiRegistrar().unregister(this, binding)`; remove
  `Pigeon.Api.setup` and `StreamHandler.clearMultipleHandlers`.
- Pass `sink` to all three scanners.
- Remove every `result: Pigeon.Result<T>` parameter and `result.success/error` pair; return the
  value directly or throw. `bluetoothState` is the one async method:
  `override suspend fun bluetoothState(): Long { val scanner = bluetoothScanner ?: notInitialized(); return scanner.getAdapterState().toLong() }`.
  Error helper:
```kotlin
private fun notInitialized(): Nothing =
    throw MessagesError(
        "uninitialized",
        "Plugin was not initialized",
        "Call the initialize method before using the plugin",
    )
```
Use `throw MessagesError("uninitialized", ...)` wherever `PluginNotInitializedException` was
thrown and for `PluginNotAttachedException`.
Then delete `Exceptions.kt`.

- [ ] **Step 4: Delete the old channel artifacts**

```bash
rm android/src/main/java/cz/dronetag/flutter_opendroneid/Pigeon.java
rm android/src/main/kotlin/cz/dronetag/flutter_opendroneid/StreamHandler.kt
rm android/src/main/kotlin/cz/dronetag/flutter_opendroneid/Exceptions.kt
```
Also remove the now-empty `android/src/main/java` tree if nothing else lives there.

- [ ] **Step 5: Regenerate and build**

Run:
```bash
./scripts/pigeon_generate.sh
cd example && flutter build apk --debug
```
Expected: generation succeeds; `BUILD SUCCESSFUL`. If Kotlin names differ from the expected
generated names, read `Messages.g.kt` and adjust mechanically.

- [ ] **Step 6: Commit**

```bash
git add android example
git commit -m "feat(android): replace event channels with Pigeon native interop"
```

---

### Task 6: iOS native implementation

**Files:**
- Modify: `ios/flutter_opendroneid.podspec`
- Delete: `ios/Classes/pigeon.h`, `ios/Classes/pigeon.m`, `ios/Classes/utils/StreamHandler.swift`, `ios/Classes/PluginNotInitializedException.swift`
- Create: `ios/Classes/OdidSink.swift`
- Modify: `ios/Classes/SwiftFlutterOpendroneidPlugin.swift`, `ios/Classes/Scanner/BluetoothScanner.swift`

**Interfaces:**
- Consumes: `OdidScannerHostApi`, `OdidScannerHostApiSetup`, `OdidScannerFlutterApi`, `OdidScannerFlutterApiRegistrar`, `PigeonError`, `ODIDPayload` from Task 2.
- Produces: Swift `protocol OdidSink: AnyObject` with `onPayload(_:)`, `onBluetoothScanActive(_:)`, `onWifiScanActive(_:)`.

- [ ] **Step 1: Update the podspec**

```ruby
s.source_files     = 'Classes/**/*.{swift,m,h}',
                     'Classes_objc_gen/**/*.{m,h}'
s.platform         = :ios, '13.0'
```
Keep `s.dependency 'Flutter'` and `s.swift_version = '5.0'`.

- [ ] **Step 2: Add the iOS sink**

Create `ios/Classes/OdidSink.swift`:
```swift
import Foundation

protocol OdidSink: AnyObject {
  func onPayload(_ payload: ODIDPayload)
  func onBluetoothScanActive(_ isActive: Bool)
  func onWifiScanActive(_ isActive: Bool)
}

final class FlutterApiSink: OdidSink {
  private let registrar: FlutterPluginRegistrar
  private let log = "FlutterOpenDroneId"

  init(registrar: FlutterPluginRegistrar) {
    self.registrar = registrar
  }

  private func onMain(_ block: @escaping () -> Void) {
    if Thread.isMainThread {
      block()
    } else {
      DispatchQueue.main.async(execute: block)
    }
  }

  private func withApi(_ block: (OdidScannerFlutterApi) -> Void) {
    onMain {
      // Resolve per callback: a hot restart replaces the Dart registration.
      guard let api = OdidScannerFlutterApiRegistrar.getInstance(registrar: self.registrar)
      else {
        NSLog("[\(self.log)] Dropping native callback: no Dart API registered")
        return
      }
      block(api)
    }
  }

  func onPayload(_ payload: ODIDPayload) {
    withApi { $0.onOdidPayload(payload) }
  }

  func onBluetoothScanActive(_ isActive: Bool) {
    withApi { $0.onBluetoothScanActive(isActive) }
  }

  func onWifiScanActive(_ isActive: Bool) {
    withApi { $0.onWifiScanActive(isActive) }
  }
}
```

- [ ] **Step 3: Update the plugin**

Rewrite `SwiftFlutterOpendroneidPlugin.swift` to:
- `public class SwiftFlutterOpendroneidPlugin: NSObject, FlutterPlugin, OdidScannerHostApi`
- Store `private let registrar: FlutterPluginRegistrar` and `private let sink: FlutterApiSink`.
- `register(with:)`: create the instance, `registrar.publish(instance)`,
  `OdidScannerHostApiSetup.register(api: instance, registrar: registrar)`.
- `detachFromEngine(for:)`: `OdidScannerHostApiSetup.unregister(api: self, registrar: registrar)`.
- Remove `eventChannels`, `streamHandlers`, and the `applicationWillTerminate` teardown.
- Convert every method to the generated synchronous signature (no completion handler), return
  the value directly, and throw `PigeonError(code: "uninitialized", message: "Plugin was not initialized", details: "Call the initialize method before using the plugin")`.
- `bluetoothState()` is the one async method:
  `public func bluetoothState() async throws -> Int64 { Int64(await scanner.managerState()) }`.
- Keep the Wi-Fi methods throwing `PigeonError(code: "unimplemented", message: "Wi-Fi is not available on iOS", details: nil)`.
- `initialize()` creates `BluetoothScanner(sink: sink)`.

- [ ] **Step 4: Update the scanner**

In `BluetoothScanner.swift`:
- `class BluetoothScanner: NSObject, CBCentralManagerDelegate` (drop `DTGPayloadApi`).
- Constructor `init(sink: OdidSink)`; store `sink` and remove the two stream handlers.
- Replace `scanStateHandler.send(centralManager.isScanning)` with
  `sink.onBluetoothScanActive(centralManager.isScanning)`.
- In `handleOdidMessage`, build `ODIDMetadata(...)` and
  `ODIDPayload(rawData: ..., receivedTimestamp: ..., metadata: ...)` directly, then call
  `sink.onPayload(payload)`.
- Keep `managerState()` and the restart timer unchanged.

- [ ] **Step 5: Delete old files and regenerate**

```bash
rm ios/Classes/pigeon.h ios/Classes/pigeon.m
rm ios/Classes/utils/StreamHandler.swift ios/Classes/PluginNotInitializedException.swift
./scripts/pigeon_generate.sh
cd example && flutter build ios --simulator --no-codesign
```
Expected: generation succeeds and the simulator build completes.

- [ ] **Step 6: Commit**

```bash
git add ios example
git commit -m "feat(ios): replace event channels with Pigeon native interop"
```

---

### Task 7: Documentation and repository hygiene

**Files:**
- Modify: `README.md`, `CHANGELOG.md`, `.gitignore`
- Modify: `pubspec.yaml`, `example/pubspec.yaml`

**Interfaces:**
- Consumes: everything above.
- Produces: no code surface.

- [ ] **Step 1: Update `.gitignore`**

Add:
```
# Pigeon FFIgen temporary object files
*_objc_gen/**/*.o
```

- [ ] **Step 2: Update plugin metadata**

In `pubspec.yaml`:
- Set `version: 2.0.0`.
- Add `dartPluginClass: FlutterOpenDroneIdPlugin` under both platform entries:
```yaml
  plugin:
    platforms:
      android:
        package: cz.dronetag.flutter_opendroneid
        pluginClass: FlutterOpendroneidPlugin
        dartPluginClass: FlutterOpenDroneIdPlugin
      ios:
        pluginClass: FlutterOpendroneidPlugin
        dartPluginClass: FlutterOpenDroneIdPlugin
```
In `example/pubspec.yaml`, set `environment: sdk: ^3.14.0` and `flutter: ">=3.50.0"`.
Run `cd example && dart fix --apply --code=migrate_design_widgets`, then add
`material_ui:` if the fix reports a missing dependency.

- [ ] **Step 3: Update the README**

Replace the event-channel paragraph with:
- Pigeon 30 native interop (FFI on iOS, JNI on Android), preview status.
- Minimum Flutter 3.50 / Dart 3.14 and AGP 9 with built-in Kotlin.
- Codegen prerequisites: `ANDROID_HOME`, JDK 17–21, Xcode command line tools.
- Codegen command: `./scripts/pigeon_generate.sh` (two-pass note).

- [ ] **Step 4: Update the CHANGELOG**

Add a `## 2.0.0` entry at the top:
- minimum Flutter 3.50 / Dart 3.14 and AGP 9 with built-in Kotlin;
- Pigeon native interop (preview) — event channels replaced by `@FlutterApi`;
- breaking: `Api`, `PayloadApi`, `bluetoothOdidPayloadEventChannel`, and
  `wifiOdidPayloadEventChannel` removed; `pigeon.dart` retained as a deprecated model re-export;
- `bluetoothState`/`wifiState` streams keep their existing scan-active semantics.

- [ ] **Step 5: Verify formatting and commit**

Run: `dart format --output=none --set-exit-if-changed lib test pigeon`
Expected: no output (clean).

```bash
git add README.md CHANGELOG.md .gitignore pubspec.yaml example/pubspec.yaml
git commit -m "docs: document Pigeon native interop setup"
```

---

### Task 8: Full verification matrix

**Files:** none (verification only).

- [ ] **Step 1: Static checks**

Run:
```bash
flutter analyze
flutter test
dart format --output=none --set-exit-if-changed lib test pigeon
```
Expected: no analyzer issues; all tests pass; formatting clean.

- [ ] **Step 2: Android debug and release builds**

Run:
```bash
cd example
flutter build apk --debug
flutter build apk --release
```
Expected: both `BUILD SUCCESSFUL`, no `ClassNotFoundException`/`NoSuchMethodError` in R8 output.

- [ ] **Step 3: iOS simulator build**

Run: `cd example && flutter build ios --simulator --no-codesign`
Expected: build completes.

- [ ] **Step 4: Device smoke**

On an Android device and an iPhone:
1. `FlutterOpenDroneId.initialize()`; `isInitialized()` returns true.
2. Start Bluetooth scan; receive at least one `receivedMessages` event and one `rawMessages` event.
3. Start/stop Bluetooth scan; `isScanningBluetooth` tracks state and the `bluetoothState`
   stream emits scan-active booleans.
4. Android only: start/stop Wi-Fi scan; the `wifiState` stream emits scan-active booleans.
5. Hot restart while scanning: the new isolate keeps receiving payloads within one second, with
   no crash in native logs.
6. Put the app in the background and back; no crash and scanning state is intact.
7. Feed a malformed advertisement (or a unit-level fake) and confirm later payloads still arrive.

Record the results in the PR description.

- [ ] **Step 5: Commit any fixes**

```bash
git add -A
git commit -m "test: verify native interop on device"
```
