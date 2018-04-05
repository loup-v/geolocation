//
//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0
//

import Flutter
import UIKit
import CoreLocation

@available(iOS 9.0, *)
public class SwiftGeolocationPlugin: NSObject, FlutterPlugin {
  
  internal let registrar: FlutterPluginRegistrar
  private let locationClient = LocationClient()
  private let locationChannel: LocationChannel
  
  init(registrar: FlutterPluginRegistrar) {
    self.registrar = registrar
    self.locationChannel = LocationChannel(locationClient: locationClient)
    super.init()
    
    locationChannel.register(on: self)
  }
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    _ = SwiftGeolocationPlugin(registrar: registrar)
  }
}

