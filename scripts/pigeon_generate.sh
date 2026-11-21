#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

run_pigeon() {
  dart run pigeon \
    --input pigeon/messages.dart \
    --dart_out lib/src/pigeon/messages.g.dart \
    --kotlin_out android/src/main/kotlin/cz/dronetag/flutter_opendroneid/Messages.g.kt \
    --kotlin_package cz.dronetag.flutter_opendroneid \
    --swift_out ios/Classes/Messages.g.swift
}

# First pass emits the Kotlin/Swift bridges. The JNI Dart bindings need the
# generated Kotlin compiled, so a failure here is expected on a clean tree.
if ! run_pigeon; then
  echo "First Pigeon pass incomplete; compiling Kotlin and retrying." >&2
fi

(cd example && flutter build apk --debug --config-only)
(cd example/android && ./gradlew :flutter_opendroneid:compileDebugKotlin)

# Second pass must succeed and produce the JNI/FFI companion files.
run_pigeon
