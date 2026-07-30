#!/usr/bin/env bash

# This script generates the Pigeon classes for structured data
# exchange between the native code and Dart code

dart run pigeon \
    --input pigeon/schema.dart \
    --dart_out lib/pigeon.dart \
    --swift_out ios/Classes/Pigeon.g.swift \
    --kotlin_out android/src/main/kotlin/cz/dronetag/flutter_opendroneid/Pigeon.g.kt \
    --kotlin_package "cz.dronetag.flutter_opendroneid"
