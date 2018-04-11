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
  
  private var hasLocationRequest: Bool {
    return !locationUpdatesRequests.isEmpty
  }
  private var hasInBackgroundLocationRequest: Bool {
    return !locationUpdatesRequests.filter { $0.inBackground == true }.isEmpty
  }
  
  private var isPaused = false
  
  override init() {
    super.init()
    locationManager.delegate = self
  }
  
  
  // One shot API
  
  func isLocationOperational() -> Result<Bool> {
    let status: ServiceStatus<Bool> = currentServiceStatus()
    return status.isReady ? Result<Bool>.success(with: true) : status.failure!
  }
  
  func requestLocationPermission(_ callback: @escaping (Result<Bool>) -> Void) {
    runWithValidServiceStatus(success: {
      callback(Result<Bool>.success(with: true))
    }, failure: { result in
      callback(result)
    })
  }
  
  func lastKnownLocation(_ callback: @escaping (Result<[Location]>) -> Void) {
    runWithValidServiceStatus(success: {
      if let location = self.locationManager.location {
        callback(Result<Location>.success(with: [Location(from: location)]))
      } else {
        callback(Result<Location>.failure(of: .locationNotFound))
      }
    }, failure: callback)
  }
  
  
  // Updates API
  
  func addLocationUpdatesRequest(_ request: LocationUpdatesRequest) {
    runWithValidServiceStatus(success: {
      self.locationUpdatesRequests.append(request)
      self.updateRunningRequest()
    }, failure: { result in
      self.locationUpdatesCallback!(result)
    })
  }
  
  func removeLocationUpdatesRequest(_ request: LocationUpdatesRequest) {
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
      let best = LocationHelper.betterAccuracy(between: $0.accuracy.ios.clValue, and: $1.accuracy.ios.clValue)
      return best == $0.accuracy.ios.clValue
    })!.accuracy.ios.clValue
    
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
  
  private func runWithValidServiceStatus<T>(success: @escaping () -> Void, failure: @escaping (Result<T>) -> Void) {
    let status: ServiceStatus<T> = currentServiceStatus()
    
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
  
  private func currentServiceStatus<T>() -> ServiceStatus<T> {
    guard CLLocationManager.locationServicesEnabled() else {
      return ServiceStatus<T>(isReady: false, needsAuthorization: nil, failure: Result<T>.failure(of: .serviceDisabled))
    }
    
    switch CLLocationManager.authorizationStatus() {
    case .notDetermined:
      let permission = locationManager.findRequestedPermission()
      guard permission != .undefined else {
        return ServiceStatus<T>(isReady: false, needsAuthorization: nil, failure: Result<T>.failure(of: .runtime, message: "Missing location usage description values in plist. See readme for details.", fatal: true))
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
  
  struct Callback<T, E> {
    let success: (T) -> Void
    let failure: (E) -> Void
  }
  
  typealias LocationUpdatesCallback = (Result<[Location]>) -> Void
  
  struct ServiceStatus<T: Codable> {
    let isReady: Bool
    let needsAuthorization: LocationPermissionRequest?
    let failure: Result<T>?
  }
}
