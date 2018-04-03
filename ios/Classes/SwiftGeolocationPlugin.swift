//
//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0
//

import Flutter
import UIKit
import CoreLocation

@available(iOS 9.0, *)
public class SwiftGeolocationPlugin: NSObject, FlutterPlugin {
  
  private let registrar: FlutterPluginRegistrar
  private let locationClient = LocationClient()
  private let locationUpdatesHandler: LocationUpdatesHandler
  
  init(registrar: FlutterPluginRegistrar) {
    self.registrar = registrar
    self.locationUpdatesHandler = LocationUpdatesHandler(locationClient: locationClient)
    super.init()
    
    locationUpdatesHandler.register(with: registrar)
  }
  
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isLocationOperational":
      isLocationOperational(on: result)
    case "requestLocationPermission":
      requestLocationPermission(on: result)
    case "lastKnownLocation":
      lastKnownLocation(on: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func isLocationOperational(on flutterResult: @escaping FlutterResult) {
    flutterResult(Codec.encode(result: locationClient.isLocationOperational()))
  }
  
  private func requestLocationPermission(on flutterResult: @escaping FlutterResult) {
    locationClient.requestLocationPermission { result in
      flutterResult(Codec.encode(result: result))
    }
  }
  
  private func lastKnownLocation(on flutterResult: @escaping FlutterResult) {
    locationClient.lastKnownLocation { result in
      flutterResult(Codec.encode(result: result))
    }
  }
  
  private func singleLocationUpdate(param: LocationUpdateParam, result: @escaping FlutterResult) {
//    runWithLocationPermission(result: result) {
//      self.locationManager.desiredAccuracy = param.accuracy.ios.clValue
//      let requestLocationAction = DelayedResultAction<CLLocation, Error>(result: result, successAction: { location in
//        self.sendResponse(Responses.success(with: Location(from: location!)), to: result)
//      }, failureAction: { error in
//        self.sendResponse(Responses.failure(of: .runtime, message: error!.localizedDescription), to: result)
//      })
//      self.requestLocationActions.append(requestLocationAction)
//
//      self.locationManager.requestLocation()
//    }
  }
  
  private func startLocationUpdates(param: LocationUpdateParam, result: @escaping FlutterResult) {
//    runWithLocationPermission(result: result) {
//      self.locationManager.desiredAccuracy = param.accuracy.ios.clValue
//      let requestLocationAction = DelayedResultAction<CLLocation, Error>(result: result, successAction: { location in
//        self.sendResponse(Responses.success(with: Location(from: location!)), to: result)
//      }, failureAction: { error in
//        self.sendResponse(Responses.failure(of: .runtime, message: error!.localizedDescription), to: result)
//      })
//      self.requestLocationActions.append(requestLocationAction)
//
//      self.locationManager.startUpdatingLocation()
//    }
  }
  
  private func stopLocationUpdates() {
//    locationManager.stopUpdatingLocation()
  }
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "io.intheloup.geolocation", binaryMessenger: registrar.messenger())
    let instance = SwiftGeolocationPlugin(registrar: registrar)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }
}

