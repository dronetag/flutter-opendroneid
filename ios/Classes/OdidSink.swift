import Foundation

protocol OdidSink: AnyObject {
  func onPayload(_ payload: ODIDPayload)
  func onBluetoothScanActive(_ isActive: Bool)
  func onWifiScanActive(_ isActive: Bool)
}

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
