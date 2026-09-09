// swift-tools-version: 5.9
// The Swift Package Manager manifest for the plugin's iOS implementation.
//
// Declared alongside the podspec rather than instead of it: Flutter resolves
// whichever the consuming app uses, so an app on CocoaPods keeps working while
// an SPM-only app (no ios/Podfile) can adopt the plugin at all. Before this
// existed, an SPM app could not depend on flutter_opendroneid.
//
// A single target with no ObjC. That is only possible because the API bridge is
// Pigeon-generated Swift (Sources/flutter_opendroneid/Pigeon.g.swift); a mixed
// ObjC/Swift target is rejected by SwiftPM, and the ObjC registration shim this
// replaced existed only to forward to the Swift class.
import PackageDescription

let package = Package(
    name: "flutter_opendroneid",
    platforms: [
        // Matches the podspec. The plugin class itself is @available(iOS 13.0)
        // and guards at runtime, which is the behaviour before this change too.
        .iOS("12.0")
    ],
    products: [
        .library(name: "flutter-opendroneid", targets: ["flutter_opendroneid"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "flutter_opendroneid",
            dependencies: [],
            resources: []
        )
    ]
)
