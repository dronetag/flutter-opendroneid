<img src="./flutter_opendroneid_logo.png" />

# flutter_opendroneid

A flutter plugin for reading Wi-Fi and Bluetooth Remote ID advertisements using native Android and iOS platform-specific implementation. The format of data is defined in the [ASTM F3411](https://www.astm.org/f3411-22a.html) Remote ID and the [ASD-STAN prEN 4709-002](http://asd-stan.org/downloads/asd-stan-pren-4709-002-p1/) Direct Remote ID specifications.

The platform-specific implementation reads raw message bytes from Wi-Fi and Bluetooth Remote ID advertisements. Payloads and scan state are delivered to Dart through a direct Pigeon `@FlutterApi` callback (FFI on iOS, JNI on Android), without platform channels. Raw data are parsed to Remote ID messages using [Dart-opendroneid library](https://github.com/dronetag/dart-opendroneid).

[The pigeon library](https://pub.dev/packages/pigeon) defines the messaging protocol between the platform host and the Flutter client. The protocol is defined in [messages.dart](pigeon/messages.dart) and uses Pigeon's native interop mode (`useFfi` / `useJni`).

The architecture of native code is inspired by [OpenDroneID Android receiver application](https://github.com/opendroneid/receiver-android).

## Migrating from 1.x

See [MIGRATION.md](MIGRATION.md) for the 2.0 breaking changes and runtime notes.

## Pre-requisities

- Flutter 3.50 or newer (Dart 3.14)
- Android Gradle Plugin 9+ with built-in Kotlin; `minSdk` 24 and `compileSdk` 37 for Android builds
- For code generation: Android SDK + JDK 17-21 and Xcode command line tools

## Getting Started

This project is a Flutter [plug-in package](https://flutter.dev/developing-packages/), a specialized package that includes platform-specific implementation code for Android and/or iOS.

For help getting started with Flutter, view
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Work in progress

> ⚠️ While we made this library public to allow [Drone Scanner](https://github.com/dronetag/drone-scanner) to be published as open-source, we're still not satisfied with the state of this repository, missing documentation and contribution guidelines. Stay tuned, we're working on it.

## Installing

1. Install the project using `flutter pub get`
2. Generate Pigeon bindings with `./scripts/pigeon_generate.sh`. The script runs Pigeon twice: the first pass emits the Kotlin/Swift bridges, the example plugin is compiled, and the second pass generates the JNI/FFI Dart bindings.

> Pigeon native interop is a preview feature in Flutter 3.50. Generated files are committed, so consumers do not need the generator toolchain.

### Runtime notes

- Call `FlutterOpenDroneId.initialize()` from the root isolate, after the Flutter binding is available (it is initialized by this method if needed). Background isolates may call stateless getters, but not `initialize()`.
- The plugin assumes a single attached `Activity`; multi-engine `ActivityAware` state is not isolated per engine.
- Parse failures are reported through `Zone.current.handleUncaughtError` at drain time (the isolate's root zone). Apps that use `runZonedGuarded` should also observe `FlutterError.onError` / `PlatformDispatcher.instance.onError`.
- `FlutterOpenDroneId.droppedPayloadCount` reports payloads dropped by the bounded queue under burst load.

## Usage & Setting up permissions

Plugin needs to be initialized before first use by calling `FlutterOpenDroneId.initialize()`. Moreover, enabling scanning the surroundings for Wi-Fi and Bluetooth Remote ID advertisements requires setting up permissions. App has to request required permissions, the plugin only checks that permissions are granted. If some permissions are missing, the plugin throws `PermissionsMissingException` when attempting to start the scan. Use for example the [permission handler package](https://pub.dev/packages/permission_handler) to request permissions.


### Android Setup
Android allows both Wi-Fi and Bluetooth scanning. Bluetooth scanning requires Bluetooth and Bluetooth Scan permission. Location permission is required for Bluetooth scanning since Android 12 (API level 31).
Check the [documentation on Bluetooth permissions](https://developer.android.com/develop/connectivity/bluetooth/bt-permissions).

Wi-Fi scanning requires location permission up to version 12 (API level 31), since version 13, the Nearby Wifi Devices permission is required.
Check the [documentation on Wi-Fi permissions](https://developer.android.com/develop/connectivity/wifi/wifi-permissions).

Permissions need to be added to `AndroidManifest.xml` file:

```
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.dronescanner_prototype">
    <uses-permission android:name="android.permission.BLUETOOTH"/>
    <uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission
      android:name="android.permission.NEARBY_WIFI_DEVICES"
      android:usesPermissionFlags="neverForLocation" />
</manifest>
```

### iOS Setup

iOS does not allow Wi-Fi scanning, only Bluetooth scanning is possible. Bluetooth permission is required. Apart from requesting permission, it also needs to be added to `Info.plist`.

- add `NSBluetoothAlwaysUsageDescription key` to `Info.plist` with the `string` type. Use any description, for example the one in code snippet. It will be shown in dialog when requesting permission.
```
<dict>
    ...
    <key>NSBluetoothAlwaysUsageDescription</key>
    <string>The application needs Bluetooth permission to acquire data from nearby aircraft.</string>
    ...
```

- The plugin supports Swift Package Manager (primary) and CocoaPods. To use Swift Package Manager, enable it for your app (`flutter config --enable-swift-package-manager`, or `enable-swift-package-manager: true` under `flutter: config:` in your app's `pubspec.yaml`).

- With Swift Package Manager, `permission_handler` turns on `PERMISSION_BLUETOOTH` automatically when `NSBluetoothAlwaysUsageDescription` is present in `Info.plist`; nothing else is needed.

- With CocoaPods, permission handler requires setting macros in `Podfile`. Set `PERMISSION_BLUETOOTH` to 1.
```
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',

        ## dart: PermissionGroup.bluetooth
        'PERMISSION_BLUETOOTH=1',
      ]
    end
  end
end
```

---

&copy; [Dronetag 2026](https://www.dronetag.com)
<a href="https://www.dronetag.com"><img src="http://dronetag-media.s3.eu-north-1.amazonaws.com/d69bc916-7137-469c-88c4-22b7ad0cdf33.png" width="100" /></a>