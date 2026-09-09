import Foundation
import Flutter

protocol OdidPayloadSink {
    func send(_ payload: ODIDPayload)
}

protocol BooleanStateSink {
    func send(_ state: Bool)
}

class BluetoothOdidPayloadStreamHandler: StreamOdidPayloadBtStreamHandler, OdidPayloadSink {
    private var sink: PigeonEventSink<ODIDPayload>?

    override func onListen(withArguments arguments: Any?, sink: PigeonEventSink<ODIDPayload>) {
        self.sink = sink
    }

    override func onCancel(withArguments arguments: Any?) {
        self.sink = nil
    }

    func send(_ payload: ODIDPayload) {
        sink?.success(payload)
    }
}

class WifiOdidPayloadStreamHandler: StreamOdidPayloadWifiStreamHandler, OdidPayloadSink {
    private var sink: PigeonEventSink<ODIDPayload>?

    override func onListen(withArguments arguments: Any?, sink: PigeonEventSink<ODIDPayload>) {
        self.sink = sink
    }

    override func onCancel(withArguments arguments: Any?) {
        self.sink = nil
    }

    func send(_ payload: ODIDPayload) {
        sink?.success(payload)
    }
}

class BluetoothStateStreamHandler: StreamBluetoothStateStreamHandler, BooleanStateSink {
    private var sink: PigeonEventSink<Bool>?

    override func onListen(withArguments arguments: Any?, sink: PigeonEventSink<Bool>) {
        self.sink = sink
    }

    override func onCancel(withArguments arguments: Any?) {
        self.sink = nil
    }

    func send(_ state: Bool) {
        sink?.success(state)
    }
}

class WifiStateStreamHandler: StreamWifiStateStreamHandler, BooleanStateSink {
    private var sink: PigeonEventSink<Bool>?

    override func onListen(withArguments arguments: Any?, sink: PigeonEventSink<Bool>) {
        self.sink = sink
    }

    override func onCancel(withArguments arguments: Any?) {
        self.sink = nil
    }

    func send(_ state: Bool) {
        sink?.success(state)
    }
}
