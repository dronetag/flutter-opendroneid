#import "FlutterOpendroneidPlugin.h"
#if __has_include(<flutter_opendroneid/flutter_opendroneid-Swift.h>)
#import <flutter_opendroneid/flutter_opendroneid-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_opendroneid-Swift.h"
#endif

@implementation FlutterOpendroneidPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterOpendroneidPlugin registerWithRegistrar:registrar];
}
@end
