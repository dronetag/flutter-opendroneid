import Flutter

public class PluginNotInitializedException : FlutterError {
    override convenience init() {
        self.init(code: "uninitialized", message: "Plugin was not initialized", details: "Call the initialize method before using the plugin")
    }
}

// Pigeon's Swift API reports failures as `Error`; FlutterError is the one it unwraps.
extension FlutterError: Error {}
