#!/usr/bin/env bash
#
# Runs the Maestro E2E flows for the example app.
#
# Usage:
#   ./scripts/run_maestro.sh android   # build, install, grant, run non-manual Android flows
#     ANDROID_SERIAL=<serial> selects a specific device (default: first emulator)
#   ./scripts/run_maestro.sh ios       # build, install on the booted simulator, run iOS flows
#
# Manual radio-off flows are excluded; see maestro/android/radio-off-errors.yaml.
set -euo pipefail
cd "$(dirname "$0")/.."

mode=${1:-android}
app_id_android=com.example.flutter_opendroneid_example

run_android() {
  command -v adb >/dev/null 2>&1 || { echo "error: adb not found" >&2; exit 1; }
  # Prefer an emulator; set ANDROID_SERIAL to target a specific device.
  device=${ANDROID_SERIAL:-}
  if [ -z "$device" ]; then
    device=$(adb devices | awk 'NR>1 && $2=="device" && $1 ~ /^emulator-/ {print $1; exit}')
  fi
  if [ -z "$device" ]; then
    device=$(adb devices | awk 'NR>1 && $2=="device" {print $1; exit}')
  fi
  [ -n "$device" ] || {
    echo "error: no Android device/emulator connected" >&2
    exit 1
  }

  flutter build apk --debug
  # A stale example build may be signed with another key; reinstall cleanly.
  adb -s "$device" uninstall "$app_id_android" >/dev/null 2>&1 || true
  adb -s "$device" install build/app/outputs/flutter-apk/app-debug.apk

  for permission in \
    android.permission.BLUETOOTH_SCAN \
    android.permission.BLUETOOTH_CONNECT \
    android.permission.ACCESS_FINE_LOCATION \
    android.permission.NEARBY_WIFI_DEVICES; do
    adb -s "$device" shell pm grant "$app_id_android" "$permission" 2>/dev/null || true
  done

  # The scan-toggle flows need working radios; only turn them on when off.
  [ "$(adb -s "$device" shell settings get global bluetooth_on 2>/dev/null | tr -d '\r')" = "1" ] || \
    adb -s "$device" shell svc bluetooth enable >/dev/null 2>&1 || true
  [ "$(adb -s "$device" shell settings get global wifi_on 2>/dev/null | tr -d '\r')" = "1" ] || \
    adb -s "$device" shell svc wifi enable >/dev/null 2>&1 || true
  sleep 2

  maestro --device "$device" test \
    maestro/smoke-android.yaml \
    maestro/android \
    --include-tags android \
    --exclude-tags manual
}

run_ios() {
  flutter build ios --simulator --no-codesign
  xcrun simctl install booted build/ios/iphonesimulator/Runner.app
  maestro test maestro --include-tags ios
}

case "$mode" in
  android) run_android ;;
  ios) run_ios ;;
  *)
    echo "usage: $0 [android|ios]" >&2
    exit 2
    ;;
esac
