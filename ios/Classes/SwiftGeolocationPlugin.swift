//
//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0
//

import Flutter
import UIKit
import CoreLocation

@available(iOS 9.0, *)
public class SwiftGeolocationPlugin: NSObject, FlutterPlugin, UIApplicationDelegate {
  
//  internal let registrar: FlutterPluginRegistrar
  private let locationClient = LocationClient()
  private let locationChannels: LocationChannels
  
  override init() {
//    self.registrar = registrar
    self.locationChannels = LocationChannels(locationClient: locationClient)
    super.init()

//    registrar.addApplicationDelegate(self)
//    locationChannels.register(on: self)
  }
  
  public static func register(with registrar: FlutterPluginRegistrar) {
//    let channel = FlutterMethodChannel(name: "geolocation", binaryMessenger: registrar.messenger())
    let instance = SwiftGeolocationPlugin()
    instance.locationChannels.register(with: registrar)
    registrar.addApplicationDelegate(instance)
    
//    registrar.addMethodCallDelegate(instance, channel: channel)
//    registrar.addApplicationDelegate(instance)
    
//    _ = SwiftGeolocationPlugin(registrar: registrar)
  }
  
  
  // UIApplicationDelegate
  
  public func applicationDidEnterBackground(_ application: UIApplication) {
    print("DSKJHFKJHSDJF")
  }
  
  public func applicationDidBecomeActive(_ application: UIApplication) {
    print("BLAH!")
    locationClient.resume()
  }
  
  public func applicationWillResignActive(_ application: UIApplication) {
    print("BLAH BLOG!")
    locationClient.pause()
  }
}

