#import "GeolocationPlugin.h"
#if __has_include(<geolocation/geolocation-Swift.h>)
#import <geolocation/geolocation-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "geolocation-Swift.h"
#endif

@implementation GeolocationPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftGeolocationPlugin registerWithRegistrar:registrar];
}
@end
