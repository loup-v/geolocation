import Flutter
import UIKit
import CoreLocation

@available(iOS 9.0, *)
public class SwiftGeolocationPlugin: NSObject, FlutterPlugin, UIApplicationDelegate {
  
  private let locationClient = LocationClient()
  private let handler: Handler
  
  override init() {
    self.handler = Handler(locationClient: locationClient)
    super.init()
  }
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let methodChannel = FlutterMethodChannel(name: "geolocation/location", binaryMessenger: registrar.messenger())
    let eventChannel = FlutterEventChannel(name: "geolocation/locationUpdates", binaryMessenger: registrar.messenger())
    
    let instance = SwiftGeolocationPlugin()
    
    registrar.addApplicationDelegate(instance)
    registrar.addMethodCallDelegate(instance, channel: methodChannel)
    eventChannel.setStreamHandler(instance.handler.locationUpdatesHandler)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    handler.handleMethodCall(call, result: result)
  }
  
  public func applicationDidBecomeActive(_ application: UIApplication) {
    locationClient.resume()
  }
  
  public func applicationWillResignActive(_ application: UIApplication) {
    locationClient.pause()
  }
}
