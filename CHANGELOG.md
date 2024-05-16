## 0.17.1

* Added toString method for MessageContainer objects for debugging purposes

## 0.17.0

* Allow multiple Basic ID messages in container

## 0.16.0

* Gradle & dependencies updates
* Flutter version bumped to 3.16.7
* Fixed event channels not correctly disposed when the app quits

## 0.15.2

* Updated permission_handler dependent library to v11.x.x

## [0.15.1](https://github.com/dronetag/flutter-opendroneid/compare/v0.15.0...v0.15.1) (2023-10-03)


### Bug Fixes

* Fix runtimeType incorrectly used for UASID.asString() ([#24](https://github.com/dronetag/flutter-opendroneid/issues/24)) ([e6ee8b5](https://github.com/dronetag/flutter-opendroneid/commit/e6ee8b5d30b9a945852a31bed687e51a2c1c3acf))
* uasid asString conversion ([6018e98](https://github.com/dronetag/flutter-opendroneid/commit/6018e98fa243d0ba68442a6dc5b385d2dc753ccc))

# [0.15.0](https://github.com/dronetag/flutter-opendroneid/compare/v0.14.2...v0.15.0) (2023-10-01)


### Features

* Re-export Dart ODID types ([0055df7](https://github.com/dronetag/flutter-opendroneid/commit/0055df71b1368bb9d003d12175fa40808f53850e))

## [0.14.2](https://github.com/dronetag/flutter-opendroneid/compare/v0.14.1...v0.14.2) (2023-10-01)


### Bug Fixes

* edit uasid string conversion ([c32c65c](https://github.com/dronetag/flutter-opendroneid/commit/c32c65c0cebfe94f8e164e3b1d3679871630d90b))
* Fix UAS ID string conversion ([#23](https://github.com/dronetag/flutter-opendroneid/issues/23)) ([3686963](https://github.com/dronetag/flutter-opendroneid/commit/368696300b72edd29d752c602c7a3c72e292e6aa))

## [0.14.1](https://github.com/dronetag/flutter-opendroneid/compare/v0.14.0...v0.14.1) (2023-09-21)

# [0.14.0](https://github.com/dronetag/flutter-opendroneid/compare/v0.13.0...v0.14.0) (2023-09-12)


### Bug Fixes

* update container with source of current message update ([c477388](https://github.com/dronetag/flutter-opendroneid/commit/c47738842cc2f9c115af3bbb59f8deba431b3d08))


### Features

* add conversions of message values to strings ([7b43b50](https://github.com/dronetag/flutter-opendroneid/commit/7b43b5058d013ffaa67b369662e72e39114e215b))
* put back duplicate messages filtering ([f1d1001](https://github.com/dronetag/flutter-opendroneid/commit/f1d1001fe70240d1dee954bf68ec9c9f9296669a))
* remove message parsing, use dart-odid ([c3dda27](https://github.com/dronetag/flutter-opendroneid/commit/c3dda27db63533623d8bba5c7970775b0ee19319))
* shorted BLE advertisements to max 31 bytes ([8da4ea2](https://github.com/dronetag/flutter-opendroneid/commit/8da4ea2aaff5b75845a63066e809719553a0442a))
* Use dart-opendroneid for parsing & pass raw bytes from native (DT-2604) ([#21](https://github.com/dronetag/flutter-opendroneid/issues/21)) ([87f5481](https://github.com/dronetag/flutter-opendroneid/commit/87f548145dc9bd2bdb30eb12c2636ed293e187b0))

## 0.13.0

- Streams are de-duplicated by fields comparison
- Android SDK requirement bumped to version 33

## 0.12.1

We require location permission for Bluetooth scanning on all Android versions, following the [Android official documentation](https://developer.android.com/guide/topics/connectivity/bluetooth/permissions#declare).

## 0.12.0

Changes made to ensure compatibility with new Flutter 3.10 and Dart 3.

## 0.11.3

- Use the NEARBY_WIFI_DEVICES permission for Android >=13

## 0.11.2

Fixed failure preventing listener initialization which was meant to run after starting scan.

## 0.11.1

Bumped dependencies

## 0.11.0

- Added methods for checking required Bluetooth & Wi-Fi permissions and eventually reporting when some of them are missing.
    - We've moved the responsibility to obtain necessary permissions to the target apps using this library, to avoid multiple permission requests in the target apps.

## 0.10.0

Added new options to set Bluetooth scan priority

## 0.9.8

Added methods for checking the validity of public part of UAS Operator ID

## 0.9.7

Added explicit checks for internal enum structures

## 0.9.6

- Added missing support for Bluetooth variant of MESSAGE_PACK messages
- Fixed Bluetooth adapter state handling on iOS

## 0.9.5

- Add missing support for OpenDroneId MESSAGE_PACK message type
- Fix wrong byterange when parsing UAS IDs
- Fix parsing of Wi-Fi beacons

## 0.9.4

Add methods to detect bluetooth and wifi adapter states

## 0.9.3

Updated `pigeon` library to v3

## 0.9.2

Minor fixed in speeds & area calculation formulas

## 0.9.1

Fixed technology detection logic and added implemented location validation

## 0.9.0

Initial public release
