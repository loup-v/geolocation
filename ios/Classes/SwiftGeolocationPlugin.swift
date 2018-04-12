//
//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0
//

import Flutter
import UIKit
import CoreLocation

@available(iOS 9.0, *)
public class SwiftGeolocationPlugin: NSObject, FlutterPlugin, UIApplicationDelegate {
  
  internal let registrar: FlutterPluginRegistrar
  private let locationClient = LocationClient()
  private let locationChannel: LocationChannel
  
  init(registrar: FlutterPluginRegistrar) {
    self.registrar = registrar
    self.locationChannel = LocationChannel(locationClient: locationClient)
    super.init()
    
    registrar.addApplicationDelegate(self)
    locationChannel.register(on: self)
  }
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    _ = SwiftGeolocationPlugin(registrar: registrar)
  }
  
  
  // UIApplicationDelegate
  
  public func applicationDidBecomeActive(_ application: UIApplication) {
    locationClient.resume()
  }
  
  public func applicationWillResignActive(_ application: UIApplication) {
    locationClient.pause()
  }
}

