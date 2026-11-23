#!/usr/bin/env bash
#
# Generates the Pigeon native interop bindings.
#
# Outputs:
#   lib/src/pigeon/messages.g.dart              (web-safe entry point)
#   lib/src/pigeon/messages.native_interop.g.dart
#   lib/src/pigeon/messages.g.ffi.dart          (iOS/macOS FFI)
#   lib/src/pigeon/messages.g.jni.dart          (Android JNI)
#   android/src/main/kotlin/.../Messages.g.kt
#   ios/flutter_opendroneid/Sources/flutter_opendroneid/Messages.g.swift
#   ios/flutter_opendroneid/Sources/flutter_opendroneid_objc_gen/
#                                               (Objective-C bridge for FFIgen,
#                                                its own SwiftPM target)
#   example/tool/pigeon/                        (FFIgen/JNIgen config scripts)
#
# Prerequisites:
#   * Flutter 3.50+ / Dart 3.14+
#   * Android SDK configured for Flutter (ANDROID_HOME or flutter config)
#   * JDK 17-21
#   * Xcode command line tools (macOS)
#
# The first pass emits the Kotlin and Swift bridges. JNIgen parses compiled
# Kotlin classes, so the example is compiled and Pigeon runs a second time.
# All generated files are committed; consumers do not need this toolchain.
#
set -euo pipefail
cd "$(dirname "$0")/.."

command -v dart >/dev/null 2>&1 || {
  echo "error: dart was not found on PATH" >&2
  exit 1
}
if [[ -z "${ANDROID_HOME:-}${ANDROID_SDK_ROOT:-}" ]]; then
  echo "warning: ANDROID_HOME/ANDROID_SDK_ROOT is not set; JNIgen may fail." >&2
  echo "         Set it or run 'flutter config --android-sdk <path>'." >&2
fi
if [[ "$(uname -s)" == "Darwin" ]] && ! xcode-select -p >/dev/null 2>&1; then
  echo "warning: Xcode command line tools not found; FFIgen may fail." >&2
fi

run_pigeon() {
  dart run pigeon \
    --input pigeon/messages.dart \
    --dart_out lib/src/pigeon/messages.g.dart \
    --kotlin_out android/src/main/kotlin/cz/dronetag/flutter_opendroneid/Messages.g.kt \
    --kotlin_package cz.dronetag.flutter_opendroneid \
    --swift_out ios/flutter_opendroneid/Sources/flutter_opendroneid/Messages.g.swift
}

# First pass: bridges + config scripts. JNI Dart bindings need compiled Kotlin,
# so a failure here is expected on a clean tree.
if ! run_pigeon; then
  echo "First Pigeon pass incomplete; compiling Kotlin and retrying." >&2
fi

(cd example && flutter build apk --debug --config-only)
(cd example/android && ./gradlew :flutter_opendroneid:compileDebugKotlin)

# Second pass must succeed and produce the JNI/FFI companion files.
run_pigeon
