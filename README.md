<img src="./flutter_opendroneid_logo.png" />

# flutter_opendroneid

A flutter plugin for reading Wi-Fi and Bluetooth Remote ID advertisements using native Android and iOS platform-specific implementation. The format of data is defined in the [ASTM F3411](https://www.astm.org/f3411-22a.html) Remote ID and the [ASD-STAN prEN 4709-002](http://asd-stan.org/downloads/asd-stan-pren-4709-002-p1/) Direct Remote ID specifications.

The platform-specific implementation reads raw message bytes from Wi-Fi and Bluetooth Remote ID advertisements. Then the raw payload with metadata is passed using event channels to the Dart side. Raw data are parsed to Remote ID messages using [Dart-opendroneid library](https://github.com/dronetag/dart-opendroneid).

[The pigeon library](https://pub.dev/packages/pigeon) is used to define the messaging protocol between the platform host and the Flutter client. The messaging protocol is defined in [schema.dart](pigeon/schema.dart).

The architecture of native code is inspired by [OpenDroneID Android receiver application](https://github.com/opendroneid/receiver-android).

## Pre-requisities

- Flutter 3.16.7 or newer

## Getting Started

This project is a Flutter [plug-in package](https://flutter.dev/developing-packages/), a specialized package that includes platform-specific implementation code for Android and/or iOS.

For help getting started with Flutter, view
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Work in progress

> ⚠️ While we made this library public to allow [Drone Scanner](https://github.com/dronetag/drone-scanner) to be published as open-source, we're still not satisfied with the state of this repository, missing documentation and contribution guidelines. Stay tuned, we're working on it.

## Installing

1. Install the project using `flutter pub get`
2. Generate Pigeon classes by running shell script in `scripts/pigeon_generate.sh`

## Setting up permissions

Enabling scanning the surroundings for Wi-Fi and Bluetooth Remote ID advertisements requires setting up permissions. App has to request required permissions, the plugin only checks that permissions are granted. If some permissions are missing, the plugin throws `PermissionsMissingException` when attempting to start the scan. Use for example the [permission handler package](https://pub.dev/packages/permission_handler) to request permissions.


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

- permission handler requires setting macros in `Podfile`. Set `PERMISSION_BLUETOOTH` to 1.
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

&copy; [Dronetag 2022](https://www.dronetag.cz)  
<a href="https://www.dronetag.cz"><img src="http://dronetag-media.s3.eu-north-1.amazonaws.com/d69bc916-7137-469c-88c4-22b7ad0cdf33.png" width="100" /></a>