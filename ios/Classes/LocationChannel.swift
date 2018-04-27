//
//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0
//

import Foundation
import CoreLocation

class LocationChannel {
    
    private let locationClient: LocationClient
    private let locationUpdatesHandler: LocationUpdatesHandler
    private let geoFenceUpdateshandler: GeoFenceUpdatesHandler
    
    init(locationClient: LocationClient) {
        self.locationClient = locationClient
        self.locationUpdatesHandler = LocationUpdatesHandler(locationClient: locationClient)
        self.geoFenceUpdateshandler = GeoFenceUpdatesHandler(locationClient: locationClient)
    }
    
    func register(on plugin: SwiftGeolocationPlugin) {
        let methodChannel = FlutterMethodChannel(name: "geolocation/location", binaryMessenger: plugin.registrar.messenger())
        methodChannel.setMethodCallHandler(handleMethodCall(_:result:))
        
        let eventChannel = FlutterEventChannel(name: "geolocation/locationUpdates", binaryMessenger: plugin.registrar.messenger())
        eventChannel.setStreamHandler(locationUpdatesHandler)
        
        let fencingChannel = FlutterEventChannel(name: "geolocation/geoFenceUpdates", binaryMessenger: plugin.registrar.messenger())
        fencingChannel.setStreamHandler(geoFenceUpdateshandler)
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
            removeLocationUpdatesRequest(Codec.decodeLocationUpdatesRequest(from: call.arguments))
        case "addGeoFencingRequest":
            addGeoFencingRequest(Codec.decodeGeoFencingRequest(from: call.arguments))
        case "removeGeoFencingRequest":
            removeGeoFencingRequest(Codec.decodeGeoFencingRequest(from: call.arguments))
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func isLocationOperational(permission: Permission, on flutterResult: @escaping FlutterResult) {
        flutterResult(Codec.encode(result: locationClient.isLocationOperational(with: permission)))
    }
    
    private func requestLocationPermission(permission: Permission, on flutterResult: @escaping FlutterResult) {
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
    
    private func removeLocationUpdatesRequest(_ request: LocationUpdatesRequest) {
        locationClient.removeLocationUpdates(request: request)
    }
    
    private func addGeoFencingRequest(_ request: GeoFenceUpdatesRequest) {
        locationClient.addGeoFenceUpdates(request: request)
    }
    
    private func removeGeoFencingRequest(_ request: GeoFenceUpdatesRequest) {
        locationClient.removeGeoFenceUpdates(request: request)
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
    
    class GeoFenceUpdatesHandler: NSObject, FlutterStreamHandler {
        private let locationClient: LocationClient
        
        init(locationClient: LocationClient) {
            self.locationClient = locationClient
        }
        
        public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
            locationClient.registerGeoFenceUpdates { result in
                events(Codec.encode(result: result))
            }
            return nil
        }
        
        public func onCancel(withArguments arguments: Any?) -> FlutterError? {
            locationClient.deregisterGeoFenceUpdatesCallback()
            return nil
        }
    }
}
