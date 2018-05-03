//
//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0
//

import Foundation
import CoreLocation

class LocationClient : NSObject, CLLocationManagerDelegate {
    
    private let locationManager = CLLocationManager()
    private var permissionCallbacks: Array<Callback<Void, Void>> = []
    
    private var locationUpdatesCallback: LocationUpdatesCallback? = nil
    private var locationUpdatesRequests: Array<LocationUpdatesRequest> = []
    
    private var geoFenceUpdatesCallback: GeoFenceUpdatesCallback? = nil
    private var geoFenceUpdatesRequests: Array<GeoFenceUpdatesRequest> = []
    
    private var hasLocationRequest: Bool {
        return !locationUpdatesRequests.isEmpty
    }
    private var hasInBackgroundLocationRequest: Bool {
        return !locationUpdatesRequests.filter { $0.inBackground == true }.isEmpty
    }
    
    private var monitoredRegions: [MonitoredRegion] = [MonitoredRegion]()
    
    private var isPaused = false
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    
    // One shot API
    
    func addGeoFenceUpdates(request: GeoFenceUpdatesRequest) {
        self.geoFenceUpdatesRequests.append(request)
        register(request: request) { (result) in
            self.geoFenceUpdatesCallback?(result)
        }
    }
    
    func removeGeoFenceUpdates(request: GeoFenceUpdatesRequest) {
        guard let index = geoFenceUpdatesRequests.index(where: { $0.id == request.id }) else {
            return
        }
        
        geoFenceUpdatesRequests.remove(at: index)
    }
    
    func registerGeoFenceUpdates(callback: @escaping GeoFenceUpdatesCallback) {
        precondition(geoFenceUpdatesCallback == nil, "trying to register a 2nd geofence callback")
        geoFenceUpdatesCallback = callback
    }
    
    func deregisterGeoFenceUpdatesCallback() {
        precondition(geoFenceUpdatesCallback != nil, "trying to deregister a non-existent geofence updates callback")
        geoFenceUpdatesCallback = nil
    }
    
    
    func register(request: GeoFenceUpdatesRequest, callback: @escaping (Result<GeoFenceResult>) -> Void) {
        if !(CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways){
            print("app doesn't have permission for location updates")
            callback(Result<GeoFenceResult>.failure(of: .permissionDenied))
        }
        if monitoredRegions.count > 19 {
            print("max amount of regions reached, remove one or more regions using unregister(request:) before proceeding")
            callback(Result<GeoFenceResult>.failure(of: .tooManyRegionsMonitored))
        }
        
        let monitoredRegion = MonitoredRegion(with: request.id, region: request.region, onEnter: {
            callback(Result<GeoFenceResult>.success(with: GeoFenceResult(id: request.id, region: request.region, result: true)))
        }, onExit: {
            callback(Result<GeoFenceResult>.success(with: GeoFenceResult(id: request.id, region: request.region, result: false)))
        })
        if !monitoredRegions.contains(monitoredRegion) {
            monitoredRegions.append(monitoredRegion)
            geoFenceUpdatesRequests.append(request)
            let geofenceRegionCenter = CLLocationCoordinate2DMake(monitoredRegion.region.centerLatitude, monitoredRegion.region.centerLongitude)
            let geofenceRegion = CLCircularRegion(center: geofenceRegionCenter,
                                                  radius: monitoredRegion.region.radius,
                                                  identifier: monitoredRegion.region.identifier)
            geofenceRegion.notifyOnEntry = true
            geofenceRegion.notifyOnExit = true
            locationManager.startMonitoring(for: geofenceRegion)
        }
    }
    
    func unregister(request: GeoFenceUpdatesRequest) {
        monitoredRegions = monitoredRegions.filter { return $0.region.identifier != request.region.identifier }
        geoFenceUpdatesRequests = geoFenceUpdatesRequests.filter { return $0.region.identifier != request.region.identifier }
        let geofenceRegionCenter = CLLocationCoordinate2DMake(request.region.centerLatitude, request.region.centerLongitude)
        let geofenceRegion = CLCircularRegion(center: geofenceRegionCenter,
                                              radius: request.region.radius,
                                              identifier: request.region.identifier)
        locationManager.stopMonitoring(for: geofenceRegion)
    }
    
    func isLocationOperational(with permission: Permission) -> Result<Bool> {
        let status: ServiceStatus<Bool> = currentServiceStatus(with: permission)
        return status.isReady ? Result<Bool>.success(with: true) : status.failure!
    }
    
    func requestLocationPermission(with permission: Permission, _ callback: @escaping (Result<Bool>) -> Void) {
        runWithValidServiceStatus(with: permission, success: {
            callback(Result<Bool>.success(with: true))
        }, failure: { result in
            callback(result)
        })
    }
    
    func lastKnownLocation(with permission: Permission, _ callback: @escaping (Result<[Location]>) -> Void) {
        runWithValidServiceStatus(with: permission, success: {
            if let location = self.locationManager.location {
                callback(Result<Location>.success(with: [Location(from: location)]))
            } else {
                callback(Result<Location>.failure(of: .locationNotFound))
            }
        }, failure: callback)
    }
    
    
    // Updates API
    
    func addLocationUpdates(request: LocationUpdatesRequest) {
        runWithValidServiceStatus(with: request.permission, success: {
            self.locationUpdatesRequests.append(request)
            self.updateRunningRequest()
        }, failure: { result in
            self.locationUpdatesCallback!(result)
        })
    }
    
    func removeLocationUpdates(request: LocationUpdatesRequest) {
        guard let index = locationUpdatesRequests.index(where: { $0.id == request.id }) else {
            return
        }
        
        locationUpdatesRequests.remove(at: index)
        updateRunningRequest()
    }
    
    func registerLocationUpdates(callback: @escaping LocationUpdatesCallback) {
        precondition(locationUpdatesCallback == nil, "trying to register a 2nd location updates callback")
        locationUpdatesCallback = callback
    }
    
    func deregisterLocationUpdatesCallback() {
        precondition(locationUpdatesCallback != nil, "trying to deregister a non-existent location updates callback")
        locationUpdatesCallback = nil
    }
    
    
    // Lifecycle API
    
    func resume() {
        guard hasLocationRequest && isPaused else {
            return
        }
        
        isPaused = false
        startLocation()
    }
    
    func pause() {
        guard hasLocationRequest && !isPaused && !hasInBackgroundLocationRequest else {
            return
        }
        
        isPaused = true
        locationManager.stopUpdatingLocation()
    }
    
    
    // Location updates logic
    
    private func updateRunningRequest() {
        guard !locationUpdatesRequests.isEmpty else {
            isPaused = false
            locationManager.stopUpdatingLocation()
            return
        }
        
        locationManager.desiredAccuracy = locationUpdatesRequests.max(by: {
            let best = LocationHelper.betterAccuracy(between: $0.accuracy.clValue, and: $1.accuracy.clValue)
            return best == $0.accuracy.clValue
        })!.accuracy.clValue
        
        let distanceFilter = locationUpdatesRequests.map { $0.displacementFilter }.min()!
        locationManager.distanceFilter = distanceFilter > 0 ? distanceFilter : kCLDistanceFilterNone
        
        locationManager.stopUpdatingLocation()
        
        if !isPaused {
            startLocation()
        }
    }
    
    private func startLocation() {
        let isContinuousUpdatesRequested = !self.locationUpdatesRequests.filter { $0.strategy == .continuous }.isEmpty
        
        if isContinuousUpdatesRequested {
            locationManager.startUpdatingLocation()
        } else {
            locationManager.requestLocation()
        }
    }
    
    
    // Service status
    
    private func runWithValidServiceStatus<T>(with permission: Permission, success: @escaping () -> Void, failure: @escaping (Result<T>) -> Void) {
        let status: ServiceStatus<T> = currentServiceStatus(with: permission)
        
        if status.isReady {
            success()
        } else {
            if let permission = status.needsAuthorization {
                let callback = Callback<Void, Void>(
                    success: { _ in success() },
                    failure: { _ in failure(Result<T>.failure(of: .permissionDenied)) }
                )
                permissionCallbacks.append(callback)
                locationManager.requestAuthorization(for: permission)
            } else {
                failure(status.failure!)
            }
        }
    }
    
    private func currentServiceStatus<T>(with permission: Permission) -> ServiceStatus<T> {
        guard CLLocationManager.locationServicesEnabled() else {
            return ServiceStatus<T>(isReady: false, needsAuthorization: nil, failure: Result<T>.failure(of: .serviceDisabled))
        }
        
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            guard locationManager.isPermissionDeclared(for: permission) else {
                return ServiceStatus<T>(isReady: false, needsAuthorization: nil, failure: Result<T>.failure(of: .runtime, message: "Missing location usage description values in Info.plist. See readme for details.", fatal: true))
            }
            
            return ServiceStatus<T>(isReady: false, needsAuthorization: permission, failure: Result<T>.failure(of: .permissionDenied))
        case .denied:
            return ServiceStatus<T>(isReady: false, needsAuthorization: nil, failure: Result<T>.failure(of: .permissionDenied))
        case .restricted:
            return ServiceStatus<T>(isReady: false, needsAuthorization: nil, failure: Result<T>.failure(of: .serviceDisabled))
        case .authorizedWhenInUse, .authorizedAlways:
            return ServiceStatus<T>(isReady: true, needsAuthorization: nil, failure: nil)
        }
    }
    
    
    // CLLocationManagerDelegate
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        permissionCallbacks.forEach { action in
            if status == .authorizedAlways || status == .authorizedWhenInUse {
                action.success(())
            } else {
                action.failure(())
            }
        }
        permissionCallbacks.removeAll()
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationUpdatesCallback?(Result<[Location]>.success(with: locations.map { Location(from: $0) }))
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationUpdatesCallback!(Result<[Location]>.failure(of: .runtime, message: error.localizedDescription))
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if let circularRegion = region as? CLCircularRegion {
            for monitoredRegion in monitoredRegions {
                if monitoredRegion.represents(circularRegion: circularRegion) {
                    monitoredRegion.didExit?()
                }
            }
        }

    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if let circularRegion = region as? CLCircularRegion {
            
            for monitoredRegion in monitoredRegions {
                if monitoredRegion.represents(circularRegion: circularRegion) {
                    monitoredRegion.didEnter?()
                }
            }
        }
    }

    struct Callback<T, E> {
        let success: (T) -> Void
        let failure: (E) -> Void
    }
    
    typealias LocationUpdatesCallback = (Result<[Location]>) -> Void
    typealias GeoFenceUpdatesCallback = (Result<GeoFenceResult>) -> Void

    struct ServiceStatus<T: Codable> {
        let isReady: Bool
        let needsAuthorization: Permission?
        let failure: Result<T>?
    }
}
