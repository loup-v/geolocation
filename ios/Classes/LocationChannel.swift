//
//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0
//

import Foundation
import CoreLocation

class LocationChannel {
  
  private let locationClient: LocationClient
  private let locationUpdatesHandler: LocationUpdatesHandler
  private let geofenceUpdatesHandler: GeofenceUpdatesHandler
  
  init(locationClient: LocationClient) {
    self.locationClient = locationClient
    self.locationUpdatesHandler = LocationUpdatesHandler(locationClient: locationClient)
    self.geofenceUpdatesHandler = GeofenceUpdatesHandler(locationClient: locationClient)
  }
  
  func register(on plugin: SwiftGeolocationPlugin) {
    let methodChannel = FlutterMethodChannel(name: "geolocation/location", binaryMessenger: plugin.registrar.messenger())
    methodChannel.setMethodCallHandler(handleMethodCall(_:result:))
    
    let locationEventChannel = FlutterEventChannel(name: "geolocation/locationUpdates", binaryMessenger: plugin.registrar.messenger())
    locationEventChannel.setStreamHandler(locationUpdatesHandler)
    
    let geofenceEventChannel = FlutterEventChannel(name: "geolocation/geofenceUpdates", binaryMessenger: plugin.registrar.messenger())
    geofenceEventChannel.setStreamHandler(geofenceUpdatesHandler)
  }
  
  private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isLocationOperational":
      isLocationOperational(permission: Codec.decodePermission(from: call.arguments), on: result)
    case "requestLocationPermission":
      requestLocationPermission(permission: Codec.decodePermission(from: call.arguments), on: result)
    case "lastKnownLocation":
      lastKnownLocation(permission: Codec.decodePermission(from: call.arguments), on: result)
    case "addLocationUpdatesRequest":
      addLocationUpdatesRequest(Codec.decodeLocationUpdatesRequest(from: call.arguments))
    case "removeLocationUpdatesRequest":
      removeLocationUpdatesRequest(Codec.decodeInt(from: call.arguments))
    case "addGeofenceRegion":
      addGeofenceRegion(Codec.decodeGeofenceRegion(from: call.arguments))
    case "removeGeofenceRegion":
      removeGeofenceRegion(Codec.decodeGeofenceRegion(from: call.arguments))
    case "geofenceRegions":
      geofenceRegions(on: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func isLocationOperational(permission: Permission, on flutterResult: @escaping FlutterResult) {
    flutterResult(Codec.encode(locationClient.isLocationOperational(with: permission)))
  }
  
  private func requestLocationPermission(permission: Permission, on flutterResult: @escaping FlutterResult) {
    locationClient.requestLocationPermission(with: permission) { result in
      flutterResult(Codec.encode(result))
    }
  }
  
  private func lastKnownLocation(permission: Permission, on flutterResult: @escaping FlutterResult) {
    locationClient.lastKnownLocation(with: permission) { result in
      flutterResult(Codec.encode(result))
    }
  }

  private func addLocationUpdatesRequest(_ request: LocationUpdatesRequest) {
    locationClient.addLocationUpdates(request: request)
  }
  
  private func removeLocationUpdatesRequest(_ id: Int) {
    locationClient.removeLocationUpdates(requestId: id)
  }
  
  private func addGeofenceRegion(_ region: GeofenceRegion) {
    locationClient.addGeofenceRegion(region)
  }
  
  private func removeGeofenceRegion(_ region: GeofenceRegion) {
    locationClient.removeGeofenceRegion(region)
  }
  
  private func geofenceRegions(on flutterResult: @escaping FlutterResult) {
    flutterResult(Codec.encode(locationClient.geofenceRegions()))
  }
  
  class LocationUpdatesHandler: NSObject, FlutterStreamHandler {
    private let locationClient: LocationClient
    
    init(locationClient: LocationClient) {
      self.locationClient = locationClient
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
      locationClient.registerLocationUpdates { result in
        events(Codec.encode(result))
      }
      return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
      locationClient.deregisterLocationUpdatesCallback()
      return nil
    }
  }
  
  class GeofenceUpdatesHandler: NSObject, FlutterStreamHandler {
    private let locationClient: LocationClient
    
    init(locationClient: LocationClient) {
      self.locationClient = locationClient
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
      locationClient.registerGeofenceUpdates { result in
        events(Codec.encode(result))
      }
      
      locationClient.runWithValidServiceStatus(with: Permission.always, success: {
      }) { (result: Result<GeofenceEvent>) in
        events(Codec.encode(result))
      }
      
      return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
      locationClient.deregisterGeofenceUpdatesCallback()
      return nil
    }
  }
}
