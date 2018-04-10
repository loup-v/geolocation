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
  
  override init() {
    super.init()
    locationManager.delegate = self
  }
  
  
  // One shot API
  
  func isLocationOperational() -> Result<Bool> {
    let status: ServiceStatus<Bool> = checkServiceStatus()
    return status.isReady ? Result<Bool>.success(with: true) : status.failure!
  }
  
  func requestLocationPermission(_ callback: @escaping (Result<Bool>) -> Void) {
    runWithLocationService(success: {
      callback(Result<Bool>.success(with: true))
    }, failure: { result in
      callback(result)
    })
  }
  
  func lastKnownLocation(_ callback: @escaping (Result<[Location]>) -> Void) {
    runWithLocationService(success: {
      if let location = self.locationManager.location {
        callback(Result<Location>.success(with: [Location(from: location)]))
      } else {
        callback(Result<Location>.failure(of: .locationNotFound))
      }
    }, failure: callback)
  }
  
  
  // Location Updates API
  
  func addLocationUpdatesRequest(_ request: LocationUpdatesRequest) {
    runWithLocationService(success: {
      let isAnyRequestRunning = !self.locationUpdatesRequests.isEmpty
      let isContinuousRequestRunning = !self.locationUpdatesRequests.filter { $0.strategy == .continuous }.isEmpty
      
      self.locationUpdatesRequests.append(request)
      
      if isAnyRequestRunning {
        self.updateLocationRequestsAccuracy()
        self.locationManager.stopUpdatingLocation()
      } else {
        self.locationManager.desiredAccuracy = request.accuracy.ios.clValue
      }
      
      if isContinuousRequestRunning || request.strategy == .continuous {
        self.locationManager.startUpdatingLocation()
      } else {
        self.locationManager.requestLocation()
      }
    }, failure: { result in
      self.locationUpdatesCallback!(result)
    })
  }
  
  func removeLocationUpdatesRequest(_ request: LocationUpdatesRequest) {
    let index = self.locationUpdatesRequests.index(where: { $0.id == request.id })
    if let index = index {
      self.locationUpdatesRequests.remove(at: index)
    }
    
    self.updateLocationRequestsAccuracy()
  }
  
  func registerLocationUpdates(callback: @escaping LocationUpdatesCallback) {
    precondition(locationUpdatesCallback == nil, "trying to register a 2nd location updates callback")
    locationUpdatesCallback = callback
  }
  
  func deregisterLocationUpdatesCallback() {
    precondition(locationUpdatesCallback != nil, "trying to deregister a non-existent location updates callback")
    locationUpdatesCallback = nil
  }
  
  
  // Helpers
  
  private func updateLocationRequestsAccuracy() {
    guard !locationUpdatesRequests.isEmpty else {
      return
    }
    
    let bestRequestedAccuracy = locationUpdatesRequests.max(by: {
      let best = LocationHelper.betterAccuracy(between: $0.accuracy.ios.clValue, and: $1.accuracy.ios.clValue)
      return best == $0.accuracy.ios.clValue
    })!.accuracy.ios.clValue
    
    locationManager.desiredAccuracy = bestRequestedAccuracy
  }
  
  private func runWithLocationService<T>(success: @escaping () -> Void, failure: @escaping (Result<T>) -> Void) {
    let status: ServiceStatus<T> = checkServiceStatus()
    
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
  
  private func checkServiceStatus<T>() -> ServiceStatus<T> {
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
