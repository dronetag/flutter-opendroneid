import Flutter
import Foundation

/// Receives scanner events and forwards them to the Dart
/// `OdidScannerFlutterApi`.
protocol OdidSink: AnyObject {
  func onPayload(_ payload: ODIDPayload)
  func onBluetoothScanActive(_ isActive: Bool)
  func onWifiScanActive(_ isActive: Bool)
}

/// Marshals scanner callbacks to the main queue and resolves the Dart API for
/// each event.
///
/// `CBCentralManager` delivers on the scanner's private queue, while Pigeon
/// callbacks must run on the isolate that registered them. The registrar is
/// queried per callback so a hot restart picks up the new registration, and
/// failures from a stale registration are logged rather than crashing.
final class FlutterApiSink: OdidSink {
  private let registrar: FlutterPluginRegistrar
  private let log = "FlutterOpenDroneId"

  init(registrar: FlutterPluginRegistrar) {
    self.registrar = registrar
  }

  private func onMain(_ block: @escaping () -> Void) {
    if Thread.isMainThread {
      block()
    } else {
      DispatchQueue.main.async(execute: block)
    }
  }

  private func withApi(_ block: @escaping (OdidScannerFlutterApi) throws -> Void) {
    onMain {
      // Resolve per callback: a hot restart replaces the Dart registration.
      guard let api = OdidScannerFlutterApiRegistrar.getInstance(registrar: self.registrar)
      else {
        NSLog("[\(self.log)] Dropping native callback: no Dart API registered")
        return
      }
      do {
        try block(api)
      } catch {
        NSLog("[\(self.log)] Dropping native callback: \(error)")
      }
    }
  }

  func onPayload(_ payload: ODIDPayload) {
    withApi { try $0.onOdidPayload(payload: payload) }
  }

  func onBluetoothScanActive(_ isActive: Bool) {
    withApi { try $0.onBluetoothScanActive(isActive: isActive) }
  }

  func onWifiScanActive(_ isActive: Bool) {
    withApi { try $0.onWifiScanActive(isActive: isActive) }
  }
}
