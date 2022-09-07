#!/usr/bin/env bash

# This script generates the Pigeon classes for structured data
# exchange between the native code and Dart code

flutter pub run pigeon \
    --input pigeon/schema.dart \
    --dart_out lib/pigeon.dart \
    --objc_prefix DTG \
    --objc_header_out ios/Classes/pigeon.h \
    --objc_source_out ios/Classes/pigeon.m \
    --java_out ./android/src/main/java/cz/dronetag/flutter_opendroneid/Pigeon.java \
    --java_package "cz.dronetag.flutter_opendroneid"