# [1.1.0](https://github.com/dronetag/flutter-opendroneid/compare/v1.0.1...v1.1.0) (2025-12-05)


### Features

* Add raw ODID payload output ([0f00181](https://github.com/dronetag/flutter-opendroneid/commit/0f0018107824729f46a1ebfe45df25f520bd5b50))

## [1.0.1](https://github.com/dronetag/flutter-opendroneid/compare/v1.0.0...v1.0.1) (2025-10-08)


### Bug Fixes

* check whether bluetoothAdapter.bluetoothLeScanner is null before using it ([f88e8d2](https://github.com/dronetag/flutter-opendroneid/commit/f88e8d21f4c34c733820b8344fe9c5e59b8b1545))
* crashing BluetoothScanner.cancel (DT-4418) ([#53](https://github.com/dronetag/flutter-opendroneid/issues/53)) ([462eddd](https://github.com/dronetag/flutter-opendroneid/commit/462eddd3416c7903c5a0857018c899875743a5bd))

# [0.23.0](https://github.com/dronetag/flutter-opendroneid/compare/v0.22.1...v0.23.0) (2025-04-30)


### Features

* add example add for ios and android ([db28336](https://github.com/dronetag/flutter-opendroneid/commit/db283362a5142f6a999285dd322ab617e31de056))
* add view of last received message container ([b75db75](https://github.com/dronetag/flutter-opendroneid/commit/b75db75a98fb653b2762b60ab038683dfa859088))
* implement demo app ui ([5f34b64](https://github.com/dronetag/flutter-opendroneid/commit/5f34b6411045da4584865a98b2924d70b594c37e))
* wrap app body in SafeArea ([0a4dbcb](https://github.com/dronetag/flutter-opendroneid/commit/0a4dbcbbbaa7479c43551a1df401a0a4dd007302))

## [0.22.1](https://github.com/dronetag/flutter-opendroneid/compare/v0.22.0...v0.22.1) (2025-03-26)

# [0.22.0](https://github.com/dronetag/flutter-opendroneid/compare/v0.21.1...v0.22.0) (2025-03-25)


### Features

* add extended ODIDMetadata ([#42](https://github.com/dronetag/flutter-opendroneid/issues/42)) ([db2be75](https://github.com/dronetag/flutter-opendroneid/commit/db2be754e47167e880b47be0d5f7b653b926550e))
* add ODIDMetadata to pigeon schema, regenerate files ([cdfe41c](https://github.com/dronetag/flutter-opendroneid/commit/cdfe41cd0c3b95f8ea8a04dd70658f3704abd13d))
* use ODIDMetadata in main dart file ([c143f26](https://github.com/dronetag/flutter-opendroneid/commit/c143f26de4559d6b41ef9df7783c1d34c4a1b761))
* use ODIDMetadata in message container ([b76a743](https://github.com/dronetag/flutter-opendroneid/commit/b76a7437cc93deaaa1452259817fef5df28e280e))
* use ODIDMetadata in native ([41c83e1](https://github.com/dronetag/flutter-opendroneid/commit/41c83e1d6217a9ee8cb8cb8310ac1dc28d2f48bd))

## [0.21.1](https://github.com/dronetag/flutter-opendroneid/compare/v0.21.0...v0.21.1) (2025-03-16)


### Bug Fixes

* cancel scan when bt is turned off ([18ca59c](https://github.com/dronetag/flutter-opendroneid/commit/18ca59c1abe13de9efc8d2ef94ea49d129dd103b))

## [0.19.5](https://github.com/dronetag/flutter-opendroneid/compare/v0.19.4...v0.19.5) (2025-01-05)


### Bug Fixes

* **and:** stop scans only if they are active in onDetachedFromEngine ([d00de4e](https://github.com/dronetag/flutter-opendroneid/commit/d00de4e41741189ae0dc2d7067a75a9ec6937528))
* **and:** unregisterReceiver on onDetachedFromActivity ([c737347](https://github.com/dronetag/flutter-opendroneid/commit/c737347aa0ba9d81491bfc50f9764f2945a170e1))

## [0.19.4](https://github.com/dronetag/flutter-opendroneid/compare/v0.19.3...v0.19.4) (2024-11-27)


### Bug Fixes

* setting up wifi event channel ([71c8d8c](https://github.com/dronetag/flutter-opendroneid/commit/71c8d8cacfb3a5f8bc3e62ad3616e583788ca39c))

## [0.19.3](https://github.com/dronetag/flutter-opendroneid/compare/v0.19.2...v0.19.3) (2024-11-26)

## [0.19.2](https://github.com/dronetag/flutter-opendroneid/compare/v0.19.1...v0.19.2) (2024-11-26)

## [0.19.1](https://github.com/dronetag/flutter-opendroneid/compare/v0.19.0...v0.19.1) (2024-10-02)


### Bug Fixes

* return from scan method if wifiAwareSupported is false ([f000816](https://github.com/dronetag/flutter-opendroneid/commit/f000816342e61a4a4f5c07c2416092466eb80733))
* solve exception when stopping Wi-Fi scans ([#37](https://github.com/dronetag/flutter-opendroneid/issues/37)) ([3d3ff20](https://github.com/dronetag/flutter-opendroneid/commit/3d3ff20ae29aff5709898570f01854ae4fb82e8c))

# [0.19.0](https://github.com/dronetag/flutter-opendroneid/compare/v0.18.1...v0.19.0) (2024-07-19)


### Features

* add bt name to ODIDPayload ([4683e23](https://github.com/dronetag/flutter-opendroneid/commit/4683e23a6c665b8fff1842697ed8ef8b9a46ebbd))
* add ODIDMessageParsingException ([715e231](https://github.com/dronetag/flutter-opendroneid/commit/715e231bb92aaba93fcc13b6bcdc1fb032e9ba4e))
* include Bluetooth metadata to parsing exceptions ([#36](https://github.com/dronetag/flutter-opendroneid/issues/36)) ([89a29b6](https://github.com/dronetag/flutter-opendroneid/commit/89a29b6dcff676cc6598bf047ce37721438c51cc))

## [0.18.1](https://github.com/dronetag/flutter-opendroneid/compare/v0.18.0...v0.18.1) (2024-06-20)

# [0.18.0](https://github.com/dronetag/flutter-opendroneid/compare/v0.17.0...v0.18.0) (2024-06-11)


### Bug Fixes

* pass rssi to update method when receiving message pack ([5af8a37](https://github.com/dronetag/flutter-opendroneid/commit/5af8a37bd99ed2af053c64ee585a6a738af5d4ad))
* rssi of messages in message pack ([#33](https://github.com/dronetag/flutter-opendroneid/issues/33)) ([845cac2](https://github.com/dronetag/flutter-opendroneid/commit/845cac28e205ac348b7ac05cefd8e8aba36d1fc4))
* Unregister receiver on cancellation ([11bbc04](https://github.com/dronetag/flutter-opendroneid/commit/11bbc04d71a8bc0685528cba650fc49b16dfa7eb))


### Features

* Add missing wifi state receiver unregistration on cancel ([#32](https://github.com/dronetag/flutter-opendroneid/issues/32)) ([0e3c7db](https://github.com/dronetag/flutter-opendroneid/commit/0e3c7db7c7c25fbfffe17b2b0a01071e42c39859))
* Add toString method for MessageContainer ([0174cfb](https://github.com/dronetag/flutter-opendroneid/commit/0174cfb475ee5857398dfe9acd86a8464cc300e5))

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
