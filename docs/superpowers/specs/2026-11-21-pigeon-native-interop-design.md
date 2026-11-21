# Design: Migrate flutter_opendroneid to Pigeon native interop (Flutter 3.50)

Date: 2026-11-21
Status: proposed (awaiting approval)

## 1. Intent and why

`flutter_opendroneid` is a Flutter plugin that receives Bluetooth and Wi-Fi Remote ID
advertisements. Today all native↔Dart traffic goes through platform channels: a Pigeon
`@HostApi` for control calls and four hand-written `EventChannel`s for payload and adapter
state. Flutter 3.50/Dart 3.14 makes FFIgen (C/Objective-C) and JNIgen (Java/Kotlin) stable
and adds a preview "native interop" mode to Pigeon 30 that generates direct FFI/JNI bindings
from the same schema.

The goal is to remove platform-channel serialization and mandatory async latency from this
plugin: host calls become direct function calls, and native→Dart payload delivery becomes a
direct `@FlutterApi` callback. The public Dart API of the plugin must not change.

Chosen approach: **A — full direct interop** (user decision, 2026-11-21).

Reviewer findings folded into this revision:

- `bluetoothState()` keeps `@async`: iOS currently waits for CoreBluetooth to resolve its
  state, and a synchronous call would silently change the first `btTurnedOn` result.
- The two public "state" streams actually carry **scan-active**, not adapter power. The new
  callbacks are named for what they carry; behavior is a 1:1 port.
- Hot restart must work: Flutter API registration moves to `dartPluginClass.registerWith()`,
  native lookups resolve the Dart instance per callback, and native calls are guarded.
- `lib/pigeon.dart` stays as a deprecated re-export; the removed `Api`/`PayloadApi` and
  event-channel constants are a **major version bump**.
- The payload queue gets a bound and a per-payload error policy.

## 2. Goals

1. `pigeon/messages.dart` compiles through Pigeon 30 native interop mode:
   `useJni` on Android, `useFfi` on iOS.
2. Control calls are direct calls (no `MethodChannel`/`BasicMessageChannel`), except
   `bluetoothState()`, which stays async to preserve the iOS wait-for-state behavior.
3. Payload and scan-state delivery uses `@FlutterApi` callbacks (no `EventChannel`).
4. `FlutterOpenDroneId` keeps every public member, signature, and stream semantics. The
   `lib/pigeon.dart` import path survives as a deprecated re-export of the generated data
   types and enums.
5. Hot restart re-registers the Dart `@FlutterApi` implementation without a full app restart.
6. The plugin builds and the example app runs on Android and iOS with Flutter 3.50.
7. Generated artifacts are committed and reproducible from one script.

## 3. Non-goals

- macOS, Windows, Linux, web support.
- Adding new scanning features, changing scanner logic, or altering the ODID parser.
- Changing the meaning of the public `bluetoothState`/`wifiState` streams. They currently
  report **scan-active**, not adapter power, despite their names. This change preserves that
  (a known naming debt), and names the new callbacks `onBluetoothScanActive` /
  `onWifiScanActive` so the native contract is honest.
- Keeping the `PayloadApi` host method or the `bluetoothOdidPayloadEventChannel` /
  `wifiOdidPayloadEventChannel` constants. They are removed as part of a major version bump.
- Migrating the iOS plugin to a SwiftPM-only layout. CocoaPods remains the supported path in
  this change; a `Package.swift` can be added later. Flutter 3.50's CocoaPods warning is
  accepted for now.
- Migrating the whole example UI to `package:material_ui` beyond the mechanical
  `dart fix --code=migrate_design_widgets` pass. The plugin library itself imports no
  Material/Cupertino widgets.
- Keeping the unused `PayloadApi.buildPayload` host method.

## 4. Constraints and facts

- Pigeon native interop is **preview** in Flutter 3.50. Risk accepted; pin Pigeon and verify
  both platform builds before release.
- `@EventChannelApi` and `@ProxyApi` are unsupported in native interop files. The existing
  event channels are hand-written, so they are legal, but approach A removes them entirely.
- Native interop does not support `@TaskQueue`. The plugin does not use it.
- Swift FFI requires `SwiftOptions(includeErrorClass: true)`.
- `ffiModuleName` must equal the iOS module name. The pod is `flutter_opendroneid`, so the
  value is `flutter_opendroneid` (not `Runner`, which is for app targets).
- iOS `BluetoothScanner` uses a dedicated background `DispatchQueue` for `CBCentralManager`
  (`ios/Classes/Scanner/BluetoothScanner.swift`). Any native→Dart callback from it must be
  marshalled to the platform main thread.
- `@FlutterApi` methods execute synchronously on the thread that calls them. The current Dart
  handler parses ODID synchronously; running that inside the callback would block the native
  main/Bluetooth queue. The callback must only enqueue.
- Hot restart leaves stale native-side `@FlutterApi` registrations (Pigeon has no isolate
  shutdown hook). Registration must run on every isolate start, the native lookup must not
  cache a stale instance, and native calls must be guarded.
- The public `bluetoothState`/`wifiState` streams today emit scan-active booleans, not adapter
  power. This change keeps that observable behavior unchanged.
- Pigeon int maps to Kotlin `Long` and Swift `Int64`.
- Android release builds need `jni ^1.1.1` for R8 keep rules; Pigeon 30 marks JNI-reachable
  classes with `@Keep`.
- Pigeon 30 generates a web-safe main Dart file plus a conditionally imported
  `*.native_interop.g.dart` companion, so importing generated code does not break web builds.
- Environment verified: Flutter 3.50.0 stable, Dart 3.14.0, Android SDK 37, JDK 21,
  Xcode 27.2, Pigeon latest 30.0.4.

## 5. Approaches considered

- **A. Full direct (chosen).** `@HostApi` through FFI/JNI + `@FlutterApi` replacing all four
  event channels. Maximum benefit, both directions direct; largest diff and preview risk.
- **B. Control-only.** `@HostApi` through FFI/JNI, event channels kept. Smaller diff, but
  payload streaming still pays codec and engine-message-loop cost — the main hot path stays
  unchanged.
- **C. Stay on channels, modernize toolchain.** Does not meet the request.

## 6. Schema design

Input file moves to `pigeon/messages.dart` (renamed from `schema.dart`) so generated files are
named `Messages.*`.

```dart
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
```

Data types and enums (`ScanPriority`, `MessageSource`, `BluetoothState`, `WifiState`,
`BluetoothPhy`, `ODIDMetadata`, `ODIDPayload`) stay field-for-field identical so the Dart
`ReceivedODIDMessage` and the parsers keep working.

Changes:

1. Rename `Api` → `OdidScannerHostApi`. Every method becomes synchronous **except
   `bluetoothState()`**, which stays `@async`:
   `initialize`, `isInitialized`, `startScanBluetooth`, `startScanWifi`, `stopScanBluetooth`,
   `stopScanWifi`, `setBtScanPriority`, `setBtServiceUuid`, `isScanningBluetooth`,
   `isScanningWifi`, `wifiState`, `btExtendedSupported`, `btMaxAdvDataLen`,
   `wifiNaNSupported` are synchronous; `@async int bluetoothState()` remains.
   Rationale: the synchronous methods do bounded work (register receivers, read adapter state,
   start or stop a scan) and belong on the caller's platform main thread. `bluetoothState()`
   is the exception because iOS `BluetoothScanner.managerState()` awaits
   `centralManagerDidUpdateState` when CoreBluetooth is still `.unknown`; making it synchronous
   would return `Unknown` and silently break the first `btTurnedOn` read.
   Consequence: Android gets one `suspend fun bluetoothState(): Long`, iOS one
   `func bluetoothState() async throws -> Int64`, and the plugin adds a
   `kotlinx-coroutines-android` dependency.
2. Delete `PayloadApi`. It existed only to force generation of `ODIDPayload` and to let
   native scanners build payloads. `ODIDPayload` is now forced by the Flutter API, and native
   code constructs generated data classes directly.
3. Add:

```dart
@FlutterApi()
abstract class OdidScannerFlutterApi {
  void onOdidPayload(ODIDPayload payload);
  void onBluetoothScanActive(bool isActive);
  void onWifiScanActive(bool isActive);
}
```

The names describe what the current code actually sends (scan started/stopped), not adapter
power. The public Dart streams keep their existing names and semantics.

Generated artifacts (names verified against Pigeon 30 examples; confirm after first run):

- Dart: `lib/src/pigeon/messages.g.dart`, `messages.native_interop.g.dart`,
  `messages.g.ffi.dart`, `messages.g.jni.dart`.
- Android: `android/src/main/kotlin/cz/dronetag/flutter_opendroneid/Messages.g.kt`.
- iOS: `ios/Classes/Messages.g.swift` plus `ios/Classes_objc_gen/**` (generated `.h`,
  and `.m` only if callbacks need trampolines — they do, because of `@FlutterApi`).

## 7. Dart layer

`FlutterOpenDroneId` keeps every public member and signature. `lib/pigeon.dart` stays as a
deprecated re-export of the generated data types/enums (`export 'src/pigeon/messages.g.dart';`),
so existing imports of `package:flutter_opendroneid/pigeon.dart` keep compiling for models.
`Api`, `PayloadApi`, and the two event-channel constants are removed (major version bump).

- Host API handle is lazy and injectable:
  `static pigeon.OdidScannerHostApi? _apiOverride;`
  `static pigeon.OdidScannerHostApi get _api => _apiOverride ??=
  pigeon.OdidScannerHostApi.createWithNativeInteropApi();`
  Lazy to avoid calling JNI before `JniPlugin` is initialized.
- Replace the four `EventChannel` fields with two broadcast controllers
  (`_bluetoothScanActiveController`, `_wifiScanActiveController`) plus the existing
  raw/received controllers. The public getters keep the names `bluetoothState` / `wifiState`.
- One `_OdidScannerFlutterApiImpl implements pigeon.OdidScannerFlutterApi`, registered via
  `pigeon.OdidScannerFlutterApi.setUp(impl)`.
- Registration runs from `FlutterOpenDroneIdPlugin.registerWith()` (declared as
  `dartPluginClass` in `pubspec.yaml`) on **every** isolate start, including hot restart, and
  again idempotently from `initialize()`.
- `onOdidPayload` appends to a bounded `OdidPayloadQueue` (capacity 1024). The queue schedules
  one microtask drain, catches parse errors per payload (routing them to
  `Zone.current.handleUncaughtError`), continues with later payloads, and drops the oldest
  payload on overflow while counting drops for diagnostics.
- `onBluetoothScanActive` / `onWifiScanActive` add to their broadcast controllers synchronously.
- All existing `Future`-returning statics become `async` wrappers around direct calls, e.g.
  `static Future<void> initialize() async { _registerFlutterApi(); _api.initialize(); }`.
  `bluetoothState()` is still awaited. Behavior and error types stay the same.
- `_api` is exposed for tests through a `@visibleForTesting` setter so a fake host API can be
  injected without a running engine.
- Delete `ODIDPayload.decode` usage; callbacks deliver typed objects.

## 8. Android implementation

`FlutterOpendroneidPlugin` keeps `FlutterPlugin` + `ActivityAware` and implements the generated
`OdidScannerHostApi` (synchronous methods plus `suspend fun bluetoothState()`).

- `onAttachedToEngine`: `OdidScannerHostApiRegistrar().register(this, binding)`; remove
  `Pigeon.Api.setup(binaryMessenger, this)`.
- `onDetachedFromEngine`: `OdidScannerHostApiRegistrar().unregister(this, binding)`, stop
  scanners, drop event-channel teardown.
- Replace all four `StreamHandler`s with one `OdidSink` implementation
  (`FlutterApiSink(binding)`). It resolves
  `OdidScannerFlutterApiRegistrar().getInstance(binding)` **per callback** (no cached instance,
  so hot restart picks up the new registration), marshals to the main looper when needed, and
  wraps each call in `try/catch (Throwable)` so a stale Dart registration cannot crash the
  scanner.
- `BluetoothScanner`, `WifiScanner`, `WifiNaNScanner`, `ODIDScanner` change their constructor
  dependency from `StreamHandler` to `OdidSink` and call `sink.onPayload(payload)` /
  `sink.onBluetoothScanActive(...)` / `sink.onWifiScanActive(...)`.
- Callbacks originate on the main looper (scan callbacks, broadcast receivers, NAN callbacks),
  so no extra dispatch is required in practice; the sink still guards.
- `bluetoothState` is `suspend fun bluetoothState(): Long = getAdapterState().toLong()`. Add
  `implementation 'org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2'` for the generated
  async dispatch.
- Errors: throw the generated `MessagesError(code, message, details)` instead of calling
  `result.error(...)`. Use `code: "uninitialized"` and the existing messages so Dart still
  receives a `PlatformException` with the old text.
- Build migration (required by Flutter 3.50 toolchain):
  - Built-in Kotlin: drop `apply plugin: 'kotlin-android'`, drop the KGP classpath and
    `kotlinVersion`, add `kotlin { compilerOptions { jvmTarget = JVM_17 } }`.
  - `compileSdk 36`, `targetSdk 36`, `minSdk 24`, Java 17.
  - Remove `android.enableJetifier`.
  - `pubspec.yaml` requires `flutter: ">=3.50.0"` and `sdk: ^3.14.0`.

## 9. iOS implementation

`SwiftFlutterOpendroneidPlugin` keeps the Objective-C facade (`FlutterOpendroneidPlugin.h/.m`)
for CocoaPods registration and implements the generated `OdidScannerHostApi` protocol.

- `register(with:)`: create the instance with the registrar, `registrar.publish(instance)`,
  `OdidScannerHostApiSetup.register(api: instance, registrar: registrar)`.
- `detachFromEngine(for:)`: `OdidScannerHostApiSetup.unregister(api: self, registrar: registrar)`.
- Remove the two `FlutterEventChannel`s and `StreamHandler.swift`.
- The sink resolves `OdidScannerFlutterApiRegistrar.getInstance(registrar: registrar)` **per
  callback** (no cached instance, so hot restart picks up the new registration). Because
  `BluetoothScanner` runs on a private `DispatchQueue`, every callback does
  `DispatchQueue.main.async { ... onOdidPayload(...) }` (and the same for scan state). Drop
  payloads with a log if no Dart implementation is registered yet.
- `bluetoothState()` stays async and delegates to `await scanner.managerState()`.
- `BluetoothScanner` stops conforming to `DTGPayloadApi`; build `ODIDPayload` directly with the
  generated initializer. Replace `StreamHandler` dependencies with `OdidSink`.
- Errors: throw `PigeonError(code:message:details:)` in place of `FlutterError`.
- Podspec: `s.source_files = 'Classes/**/*.{swift,m,h}'`,
  add `'Classes_objc_gen/**/*.{m,h}'`, `s.ios.deployment_target = '13.0'`.
  Generated `.o` files are ignored and never committed.
- Keep the Objective-C prefix removal in mind: dropping `--objc_prefix DTG` changes generated
  and implemented type names (`DTGApi` → `OdidScannerHostApi`). All references are updated in
  the same change.

## 10. Toolchain and repository changes

- `pubspec.yaml`: version `2.0.0`; Pigeon dev dep `^30.0.4`; runtime `ffi`, `objective_c`,
  `meta`, `jni ^1.1.1`; dev `ffigen`, `jnigen ^1.0.0`, `swift2objc`, `swiftgen`, `path`,
  `pub_semver`.
  Follow the Pigeon example's `objective_c` constraint if the iOS simulator needs it.
  Add `dartPluginClass: FlutterOpenDroneIdPlugin` under both `android` and `ios` platform
  entries so the Flutter API is registered on every isolate start.
- `lib/pigeon.dart` becomes a deprecated re-export:
  `export 'src/pigeon/messages.g.dart';`.
- `scripts/pigeon_generate.sh` becomes the documented bootstrap:
  1. `dart run pigeon --input pigeon/messages.dart` (Kotlin/Swift bridges + config scripts;
     JNI step may fail until the plugin compiles).
  2. `(cd example/android && ./gradlew :flutter_opendroneid:compileDebugKotlin)`.
  3. Re-run `dart run pigeon --input pigeon/messages.dart` so JNIgen sees compiled classes.
  The script fails loudly with actionable output if `ANDROID_HOME`/`JAVA_HOME` or Xcode
  command-line tools are missing.
- Example app: update to Flutter 3.50 defaults — AGP 9.3.1, Gradle 9.5, built-in Kotlin,
  `compileSdk`/`targetSdk` 36, `minSdk` 24, Java 17. Run
  `dart fix --apply --code=migrate_design_widgets` and add `material_ui` if the fix requires it.
- `.gitignore`: add `*_objc_gen/**/*.o`.
- `README`: replace the Pigeon/event-channel description with native interop, list the new
  codegen prerequisites, and note the preview status and minimum Flutter version.
- `CHANGELOG`: 2.0.0 — breaking: Flutter 3.50, AGP 9; removed `Api`, `PayloadApi`, and the
  event-channel constants; `flutter_opendroneid/pigeon.dart` retained as a deprecated model
  re-export; `bluetoothState`/`wifiState` stream semantics intentionally unchanged.

## 11. Threading and lifecycle rules

- Root isolate: `initialize()` and all scan control calls run on the platform main thread.
  Document that `initialize()` must be called from the root isolate; background isolates may
  call stateless getters, but not `initialize()`.
- Android scanners emit on the main looper; iOS scanner emits on its private queue and is
  marshalled to main before touching Dart.
- Dart callback does O(1) work (enqueue) and never parses inline.
- `@FlutterApi` registration runs on every isolate start via `dartPluginClass.registerWith()`
  (and idempotently from `initialize()`). Native resolves the Dart instance per callback, so a
  hot restart rebinds without a full app restart. Native calls are guarded; payloads emitted
  during the rebind window are dropped.
- No `dispose()`/`setUp(null)` is added.

## 12. Verification

1. `dart run pigeon --input pigeon/messages.dart` completes; generated files contain no
   `EventChannel` and include `createWithNativeInteropApi` / `OdidScannerHostApiRegistrar`.
2. `flutter analyze` and `dart format --output=none --set-exit-if-changed` are clean.
3. `cd example && flutter build apk --debug` succeeds.
4. `cd example && flutter build ios --simulator --no-codesign` succeeds.
5. Unit tests (no device) for: payload queue ordering, single-schedule behavior, bounded
   overflow, parse-error continuation, enum ABI, and state stream emission via a fake host API.
6. Manual smoke on a physical Android device and iPhone: initialize, start BT scan, receive at
   least one ODID payload, start/stop Wi-Fi scan on Android, confirm `isScanning*`, confirm the
   `bluetoothState`/`wifiState` streams still mean scan-active, and hot restart while scanning
   (new isolate must keep receiving payloads within a second).
7. Release build (`flutter build apk --release`) to confirm R8/JNI keep rules.

## 13. Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| Native interop is preview; behavior may change in a later Flutter/Pigeon release | Pin Pigeon, keep generated code committed, gate on both platform builds, document preview status |
| `ffiModuleName` mismatch causes `FailedToLoadClassException` | Use the pod module name `flutter_opendroneid`; verify at startup |
| iOS callbacks off the main thread | Explicit `DispatchQueue.main.async` marshalling in the plugin |
| Dart parsing blocks the native thread | Callback only enqueues; parsing happens in a microtask drain |
| Hot restart leaves a stale native registration | `dartPluginClass.registerWith()`, per-callback instance lookup, guarded native calls |
| JNIgen needs compiled classes (bootstrap loop) | Documented 3-step generate/build/regenerate script |
| Generated ObjC `.m` missing or header-only SwiftPM target | CocoaPods path only; podspec includes `Classes_objc_gen`; no SwiftPM target declared |
| Enum ordinal changes break wire compatibility with older native builds | Treat enum order as ABI; never reorder, only append; ABI test |
| Multi-engine `ActivityAware` state | Flutter 3.50 gives exact engine routing via binding `engineId`; keep one `boundActivity` as today and document the single-activity assumption |
| Public `Api`/`PayloadApi`/event-channel removal breaks a consumer | Major version bump, deprecated `pigeon.dart` model re-export, CHANGELOG migration note |

## 14. Work order

1. pubspec + Pigeon config + schema; first generation pass.
2. Dart layer rewrite (host API + Flutter API sink + queue).
3. Android: build migration, plugin registration, sink plumbing, errors.
4. iOS: podspec, plugin registration, sink plumbing, main-thread marshalling, errors.
5. Regenerate after native signatures exist; fix naming drift.
6. Example app toolchain + docs.
7. Verification matrix and release build.

## 15. Left to the builder

- Exact generated file names/type names after the first Pigeon run (the design lists expected
  names; adjust mechanically).
- Whether `objective_c` needs the example's `<9.6.3` upper bound for the simulator.
- Whether the example app needs `material_ui` in `pubspec.yaml` after the automated fix.
