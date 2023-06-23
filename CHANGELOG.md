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