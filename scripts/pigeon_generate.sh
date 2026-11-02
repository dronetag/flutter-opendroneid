#!/usr/bin/env bash

# This script generates the Pigeon classes for structured data
# exchange between the native code and Dart code

flutter pub run pigeon \
    --input pigeon/schema.dart \
    --dart_out lib/pigeon.dart \
    --swift_out ios/flutter_opendroneid/Sources/flutter_opendroneid/Pigeon.swift \
    --java_out ./android/src/main/java/cz/dronetag/flutter_opendroneid/Pigeon.java \
    --java_package "cz.dronetag.flutter_opendroneid"
