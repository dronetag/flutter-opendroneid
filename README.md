<img src="./flutter_opendroneid_logo.png" />

# flutter_opendroneid

A flutter plugin for reading Wi-Fi and Bluetooth Remote ID advertisements using native Android and iOS platform-specific implementation. The format of data is defined in the [ASTM F3411](https://www.astm.org/f3411-22a.html) Remote ID and the [ASD-STAN prEN 4709-002](http://asd-stan.org/downloads/asd-stan-pren-4709-002-p1/) Direct Remote ID specifications.

The platform-specific implementation reads raw message bytes from Wi-Fi and Bluetooth Remote ID advertisements. Then the raw payload with metadata is passed using event channels to the Dart side. Raw data are parsed to Remote ID messages using [Dart-opendroneid library](https://github.com/dronetag/dart-opendroneid).

[The pigeon library](https://pub.dev/packages/pigeon) is used to define the messaging protocol between the platform host and Flutter client. The messaging protocol is defined in [schema.dart](pigeon/schema.dart).

The architecture of native code is inspired by [OpenDroneID Android receiver application](https://github.com/opendroneid/receiver-android).

## Pre-requisities

- Flutter 3.10.0 or newer

## Getting Started

This project is a starting point for a Flutter
[plug-in package](https://flutter.dev/developing-packages/),
a specialized package that includes platform-specific implementation code for
Android and/or iOS.

For help getting started with Flutter, view
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Work in progress

> ⚠️ While we made this library public to allow [Drone Scanner](https://github.com/dronetag/drone-scanner) to be published as open-source, we're still not satisfied with the state of this repository, missing documentation and contribution guidelines. Stay tuned, we're working on it.

## Installing

1. Install the project using `flutter pub get`
2. Generate Pigeon classes by running shell script in `scripts/pigeon_generate.sh`

---

&copy; [Dronetag 2022](https://www.dronetag.cz)  
<a href="https://www.dronetag.cz"><img src="http://dronetag-media.s3.eu-north-1.amazonaws.com/d69bc916-7137-469c-88c4-22b7ad0cdf33.png" width="100" /></a>