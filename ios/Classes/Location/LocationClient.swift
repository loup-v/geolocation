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
  
  func lastKnownLocation(_ callback: @escaping (Result<Location>) -> Void) {
    runWithLocationService(success: {
      if let location = self.locationManager.location {
        callback(Result<Location>.success(with: Location(from: location)))
      } else {
        callback(Result<Location>.failure(of: .locationNotFound))
      }
    }, failure: callback)
  }
  
  func startLocationUpdates(for request: LocationUpdatesRequest) {
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
  
  func stopLocationUpdates(for request: LocationUpdatesRequest) {
    
  }
  
  func registerForLocationUpdates(_ callback: @escaping LocationUpdatesCallback) {
    precondition(locationUpdatesCallback == nil, "trying to register a 2nd location updates callback")
    locationUpdatesCallback = callback
  }
  
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
  
//  func locationUpdates(param: LocationUpdateParam, on callback: @escaping (Result<Location>) -> Void) {
//    runWithLocationPermission(callback: callback) {
//      let callback = UpdateLocationCallback<CLLocation, Error>(
//        param: param,
//        success: { location in
//          callback(Result<Location>.success(with: Location(from: location)))
//      },
//        failure: { error in
//        callback(Result<Location>.failure(of: .runtime, message: error.localizedDescription))
//      })
//
//      let isAnyUpdateRunning = !self.updateLocationCallbacks.isEmpty
//      let isContinuousUpdateRunning = !self.updateLocationCallbacks.filter { $0.param.strategy == .continuous }.isEmpty
//
//      self.updateLocationCallbacks.append(callback)
//
////      if isAnyUpdateRunning {
////        self.locationManager.stopUpdatingLocation()
////      }
//
//      if isAnyUpdateRunning {
//        return
//      }
//
//      if param.strategy == .continuous {
//        self.locationManager.startUpdatingLocation()
//      } else {
//        self.locationManager.requestLocation()
//      }
//    }
//  }
  
  func stopLocationUpdates() {
    precondition(locationUpdatesCallback != nil, "trying to unregister a non-existent location updates callback")
    locationUpdatesCallback = nil
    
    locationManager.stopUpdatingLocation()
  }

  private func cleanupUpdateLocationCallbacks() {
//    updateLocationCallbacks = updateLocationCallbacks.filter { $0.param.strategy == .continuous }
//
//    if !updateLocationCallbacks.isEmpty {
//      let highestAccuracyCallback = updateLocationCallbacks.max(by: {
//        let best = LocationHelper.betterAccuracy(between: $0.param.accuracy.ios.clValue, and: $1.param.accuracy.ios.clValue)
//        return best == $0.param.accuracy.ios.clValue
//      })!
//      locationManager.desiredAccuracy = highestAccuracyCallback.param.accuracy.ios.clValue
//    }
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
    locationUpdatesCallback!(Result<Location>.success(with: Location(from: locations.last!)))
//    cleanupUpdateLocationCallbacks()
  }
  
  public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    locationUpdatesCallback!(Result<Location>.failure(of: .runtime, message: error.localizedDescription))
//    cleanupUpdateLocationCallbacks()
  }
  
  struct Callback<T, E> {
    let success: (T) -> Void
    let failure: (E) -> Void
  }
  
  typealias LocationUpdatesCallback = (Result<Location>) -> Void
  
  struct ServiceStatus<T: Codable> {
    let isReady: Bool
    let needsAuthorization: LocationPermissionRequest?
    let failure: Result<T>?
  }
  
  
}


