//
//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0
//

import Flutter
import UIKit
import CoreLocation

@available(iOS 9.0, *)
public class SwiftGeolocationPlugin: NSObject, FlutterPlugin, CLLocationManagerDelegate {
  
  private let registrar: FlutterPluginRegistrar
  private let locationManager = CLLocationManager()
  private let jsonEncoder = JSONEncoder()
  private let jsonDecoder = JSONDecoder()
  
  private var withLocationPermissionActions: Array<DelayedResultAction<Any, Any>> = []
  private var requestLocationActions: Array<DelayedResultAction<CLLocation, Error>> = []
  
  init(registrar: FlutterPluginRegistrar) {
    self.registrar = registrar
    super.init()
    locationManager.delegate = self
  }
  
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "lastKnownLocation":
      lastKnownLocation(result: result)
    case "currentLocation":
      singleLocationUpdate(param: decodeSingleLocationParam(from: call.arguments), result: result)
    case "singleLocationUpdate":
      singleLocationUpdate(param: decodeSingleLocationParam(from: call.arguments), result: result)
    default:
      fatalError()
    }
  }
  
  private func lastKnownLocation(result: @escaping FlutterResult) {
    runWithLocationPermission(result: result) {
      if let location = self.locationManager.location {
        self.sendResponse(Responses.success(with: Location(from: location)), to: result)
      } else {
        self.sendResponse(Responses.failure(of: .locationNotFound), to: result)
      }
    }
  }
  
  private func singleLocationUpdate(param: SingleLocationParam, result: @escaping FlutterResult) {
    runWithLocationPermission(result: result) {
      self.locationManager.desiredAccuracy = param.accuracy.ios.clValue
      let requestLocationAction = DelayedResultAction<CLLocation, Error>(result: result, successAction: { location in
        self.sendResponse(Responses.success(with: Location(from: location!)), to: result)
      }, failureAction: { error in
        self.sendResponse(Responses.failure(of: .runtime, message: error!.localizedDescription), to: result)
      })
      self.requestLocationActions.append(requestLocationAction)
      
      self.locationManager.requestLocation()
    }
  }
  
  private func runWithLocationPermission(result: @escaping FlutterResult, _ action: @escaping () -> Void) {
    guard CLLocationManager.locationServicesEnabled() else {
      sendResponse(Responses.failure(of: .serviceDisabled), to: result)
      return
    }
    
    switch CLLocationManager.authorizationStatus() {
    case .notDetermined:
      let permission = locationManager.findRequestedPermission()
      guard permission != .undefined else {
        sendResponse(Responses.failure(of: .runtime, message: "Missing location usage description values in plist. See readme for details.", fatal: true), to: result)
        return
      }
      
      let withLocationPermissionAction = DelayedResultAction<Any, Any>(result: result, successAction: { _ in action() }, failureAction: { _ in })
      withLocationPermissionActions.append(withLocationPermissionAction)
      
      locationManager.requestAuthorization(for: permission)
    case .denied:
      sendResponse(Responses.failure(of: .permissionDenied), to: result)
    case .restricted:
      sendResponse(Responses.failure(of: .serviceDisabled), to: result)
    case .authorizedWhenInUse, .authorizedAlways:
      action()
    }
  }
  
  private func sendResponse<T>(_ response: Response<T>, to result: FlutterResult) {
    result(String(data: try! jsonEncoder.encode(response), encoding: .utf8))
  }
  
  private func decodeSingleLocationParam(from arugments: Any?) -> SingleLocationParam {
    return try! jsonDecoder.decode(SingleLocationParam.self, from: (arugments as! String).data(using: .utf8)!)
  }
  
  
  // CLLocationManagerDelegate
  
  public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    withLocationPermissionActions.forEach { action in
      if status == .authorizedAlways || status == .authorizedWhenInUse {
        action.successAction(nil)
      } else {
        sendResponse(Responses.failure(of: .permissionDenied), to: action.result)
      }
    }
    withLocationPermissionActions.removeAll()
  }
  
  public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    requestLocationActions.forEach { action in
      action.successAction(locations.last)
    }
    requestLocationActions.removeAll()
  }
  
  public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    requestLocationActions.forEach { action in
      action.failureAction(error)
    }
    requestLocationActions.removeAll()
  }
  
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "io.intheloup.geolocation", binaryMessenger: registrar.messenger())
    let instance = SwiftGeolocationPlugin(registrar: registrar)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }
  
  struct DelayedResultAction<T, E> {
    let result: FlutterResult
    let successAction: (T?) -> Void
    let failureAction: (E?) -> Void
  }
}

