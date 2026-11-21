# Maestro E2E flows

UI-level end-to-end tests for the example app. They verify the plugin's control
surface (initialization, permissions, scan start/stop, error feedback), not real
ODID reception — that requires physical radio hardware.

## Prerequisites

- [Maestro](https://docs.maestro.dev/) 2.x on `PATH`
- Android emulator or a USB device (`adb devices`), or a booted iOS simulator
- Debug app installed (`example/scripts/run_maestro.sh` does this)
- On MIUI/HyperOS (Xiaomi), enable **Developer options → Install via USB** and
  **USB debugging (Security settings)** so Maestro can install its driver APK.
  Without those, `maestro` fails with `INSTALL_FAILED_USER_RESTRICTED`.

## Flows

| Flow | Tags | What it verifies |
| --- | --- | --- |
| `smoke-android.yaml` | `smoke`, `android` | Home screen, counters, granted permissions, scan buttons |
| `smoke-ios.yaml` | `smoke`, `ios` | iOS home screen and the absence of Wi-Fi controls |
| `android/permissions.yaml` | `android`, `permissions` | Runtime permissions are granted and buttons are disabled |
| `android/scan-bluetooth-toggle.yaml` | `android`, `scan` | Start/stop Bluetooth scan flips the button state |
| `android/scan-wifi-toggle.yaml` | `android`, `scan` | Start/stop Wi-Fi scan flips the button state |
| `android/radio-off-errors.yaml` | `android`, `manual` | Disabled radio shows `Bluetooth is disabled` / `Wi-Fi is disabled` |

## Run

```bash
# Android: build, install, grant permissions, enable radios, run non-manual flows
ANDROID_SERIAL=emulator-5554 ./example/scripts/run_maestro.sh android
ANDROID_SERIAL=<usb-serial> ./example/scripts/run_maestro.sh android

# iOS simulator: build, install, run iOS flows
./example/scripts/run_maestro.sh ios

# Or run directly against an already installed app
cd example
maestro test maestro --include-tags android --exclude-tags manual
```

## Manual radio-off checks

```bash
adb shell svc bluetooth disable
adb shell svc wifi disable
cd example
maestro test maestro/android/radio-off-errors.yaml --include-tags manual
adb shell svc bluetooth enable
adb shell svc wifi enable
```

On devices where `WifiManager.isScanAlwaysAvailable()` is true, Wi-Fi scanning
works with Wi-Fi off, so the Wi-Fi half of the manual flow is skipped by the
native scanner (no error is shown).

## Notes

- The scripts pre-grant runtime permissions with `adb shell pm grant`. When adb
  cannot grant them (MIUI/HyperOS), `flows/grant-permissions.yaml` taps the
  system dialogs instead.
- `launchApp` does not clear app state, so pre-granted permissions survive.
- The tests use visible text selectors; the example app is single-language.
- `scan-bluetooth-toggle` requires Bluetooth to be enabled; `scan-wifi-toggle`
  requires Wi-Fi to be enabled.
- Real payload assertions need a physical Android device or iPhone and a nearby
  Remote ID transmitter.
