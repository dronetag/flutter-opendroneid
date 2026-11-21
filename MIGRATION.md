# Migrating from 1.x to 2.0

2.0 replaces platform channels and event channels with Pigeon native interop
(JNI on Android, FFI on iOS). The `FlutterOpenDroneId` API is source-compatible;
the changes are platform requirements, removed internal APIs, and runtime
behavior notes.

## Requirements

- Flutter 3.50+ / Dart 3.14+
- Android Gradle Plugin 9+ with built-in Kotlin
- Android `minSdk` 24 and `compileSdk` 37
- CocoaPods for iOS (Swift Package Manager support is not included yet)

Pigeon native interop is a **preview** feature in Flutter 3.50. Generated
bindings are committed, so consumers do not need FFIgen/JNIgen.

## Removed APIs

| 1.x | 2.0 |
| --- | --- |
| `pigeon.Api`, `pigeon.PayloadApi` | Internal; use `FlutterOpenDroneId` |
| `FlutterOpenDroneId.bluetoothOdidPayloadEventChannel` | Removed; listen to `rawMessages` |
| `FlutterOpenDroneId.wifiOdidPayloadEventChannel` | Removed; listen to `rawMessages` |
| `package:flutter_opendroneid/pigeon.dart` | Deprecated; still re-exports models. Import the model types from `flutter_opendroneid.dart` instead |

`FlutterOpenDroneId.receivedMessages`, `rawMessages`, `bluetoothState`, and
`wifiState` keep their names and semantics. The two state streams still report
whether a **scan is active**, not adapter power.

## Runtime notes

- Call `initialize()` from the root isolate. It initializes the Flutter binding
  if necessary and registers the native callback.
- Hot restart does not require a full app restart: the next `initialize()` call
  registers the new isolate. Payloads arriving in the short rebind window may be
  dropped.
- Parse failures are reported through `Zone.current.handleUncaughtError` in the
  root zone. Apps using `runZonedGuarded` should also observe
  `FlutterError.onError` / `PlatformDispatcher.instance.onError`.
- Queue overflow drops the oldest payloads. `FlutterOpenDroneId.droppedPayloadCount`
  exposes the total.
- Native error codes are `uninitialized` and `unimplemented` (the latter for
  Wi-Fi on iOS), matching iOS and Android.

## For plugin contributors

Regenerate bindings with:

```bash
./scripts/pigeon_generate.sh
```

The script runs Pigeon twice because JNIgen parses compiled Kotlin classes. See
the script header for prerequisites.
