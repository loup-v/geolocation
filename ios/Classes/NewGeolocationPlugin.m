//
//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0
//

#import "NewGeolocationPlugin.h"
#import <new_geolocation/new_geolocation-Swift.h>

@implementation NewGeolocationPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftNewGeolocationPlugin registerWithRegistrar:registrar];
}
@end
