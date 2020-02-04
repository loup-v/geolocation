//
//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0
//

import Foundation
import CoreLocation
import streams_channel

class Handler {

  private let locationClient: LocationClient
  public let locationUpdatesHandler: LocationUpdatesHandler
  
  init(locationClient: LocationClient) {
    self.locationClient = locationClient
    self.locationUpdatesHandler = LocationUpdatesHandler(locationClient: locationClient)
  }
  
  public func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isLocationOperational":
      isLocationOperational(permission: Codec.decodePermission(from: call.arguments), on: result)
    case "requestLocationPermission":
      requestLocationPermission(permission: Codec.decodePermissionRequest(from: call.arguments), on: result)
    case "lastKnownLocation":
      lastKnownLocation(permission: Codec.decodePermission(from: call.arguments), on: result)
    case "addLocationUpdatesRequest":
      addLocationUpdatesRequest(Codec.decodeLocationUpdatesRequest(from: call.arguments))
    case "removeLocationUpdatesRequest":
      removeLocationUpdatesRequest(Codec.decodeInt(from: call.arguments))
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func isLocationOperational(permission: Permission, on flutterResult: @escaping FlutterResult) {
    flutterResult(Codec.encode(result: locationClient.isLocationOperational(with: permission)))
  }
  
  private func requestLocationPermission(permission: PermissionRequest, on flutterResult: @escaping FlutterResult) {
    locationClient.requestLocationPermission(with: permission) { result in
      flutterResult(Codec.encode(result: result))
    }
  }
  
  private func lastKnownLocation(permission: Permission, on flutterResult: @escaping FlutterResult) {
    locationClient.lastKnownLocation(with: permission) { result in
      flutterResult(Codec.encode(result: result))
    }
  }

  private func addLocationUpdatesRequest(_ request: LocationUpdatesRequest) {
    locationClient.addLocationUpdates(request: request)
  }
  
  private func removeLocationUpdatesRequest(_ id: Int) {
    locationClient.removeLocationUpdates(requestId: id)
  }
  
  
  class LocationUpdatesHandler: NSObject, FlutterStreamHandler {
    private let locationClient: LocationClient
    
    init(locationClient: LocationClient) {
      self.locationClient = locationClient
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
      locationClient.registerLocationUpdates { result in
        events(Codec.encode(result: result))
      }
      return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
      locationClient.deregisterLocationUpdatesCallback()
      return nil
    }
  }
}
