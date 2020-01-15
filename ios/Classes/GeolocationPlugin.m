//
//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0
//

#import "GeolocationPlugin.h"
#import <geolocation/geolocation-Swift.h>

@implementation GeolocationPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftGeolocationPlugin registerWithRegistrar:registrar];
}
@end
