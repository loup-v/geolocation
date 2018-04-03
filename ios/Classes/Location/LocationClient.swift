//
//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0
//

import Foundation
import CoreLocation

class LocationClient : NSObject, CLLocationManagerDelegate {
  
  private let locationManager = CLLocationManager()
  private var withLocationPermissionActions: Array<DelayedAction<Void, Void>> = []
  private var requestLocationActions: Array<DelayedAction<CLLocation, Error>> = []
  
  override init() {
    super.init()
    locationManager.delegate = self
  }
  
  func isLocationOperational() -> Result<Bool> {
    let status: ServiceStatus<Bool> = checkServiceStatus()
    return status.isReady ? Result<Bool>.success(with: true) : status.failure!
  }
  
  func requestLocationPermission(_ callback: @escaping (Result<Bool>) -> Void) {
    runWithLocationPermission(callback: callback) {
      callback(Result<Bool>.success(with: true))
    }
  }
  
  func lastKnownLocation(_ callback: @escaping (Result<Location>) -> Void) {
    runWithLocationPermission(callback: callback) {
      if let location = self.locationManager.location {
        callback(Result<Location>.success(with: Location(from: location)))
      } else {
        callback(Result<Location>.failure(of: .locationNotFound))
      }
    }
  }
  
  func locationUpdates(param: LocationUpdateParam, on callback: @escaping (Result<Location>) -> Void) {
    runWithLocationPermission(callback: callback) {
      let requestLocationAction = DelayedAction<CLLocation, Error>(
        success: { location in
          callback(Result<Location>.success(with: Location(from: location)))
      },
        failure: { error in
        callback(Result<Location>.failure(of: .runtime, message: error.localizedDescription))
      })
      self.requestLocationActions.append(requestLocationAction)
      
      self.locationManager.desiredAccuracy = param.accuracy.ios.clValue
      
      if param.strategy == .continuous {
        self.locationManager.startUpdatingLocation()
      } else {
        self.locationManager.requestLocation()
      }
    }
  }
  
  func stopLocationUpdates() {
    self.locationManager.stopUpdatingLocation()
  }
  
  private func runWithLocationPermission<T>(callback: @escaping (Result<T>) -> Void, _ action: @escaping () -> Void) {
    let status: ServiceStatus<T> = checkServiceStatus()
    
    if status.isReady {
      action()
    } else {
      if let permission = status.needsAuthorization {
        let withLocationPermissionAction = DelayedAction<Void, Void>(
          success: { _ in action() },
          failure: { _ in callback(Result<T>.failure(of: .permissionDenied)) }
        )
        withLocationPermissionActions.append(withLocationPermissionAction)
        locationManager.requestAuthorization(for: permission)
      } else {
        callback(status.failure!)
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
    withLocationPermissionActions.forEach { action in
      if status == .authorizedAlways || status == .authorizedWhenInUse {
        action.success(())
      } else {
        action.failure(())
      }
    }
    withLocationPermissionActions.removeAll()
  }
  
  public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    requestLocationActions.forEach { action in
      action.success(locations.last!)
    }
    requestLocationActions.removeAll()
  }
  
  public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    requestLocationActions.forEach { action in
      action.failure(error)
    }
    requestLocationActions.removeAll()
  }
  
  struct DelayedAction<T, E> {
    let success: (T) -> Void
    let failure: (E) -> Void
  }
  
  struct ServiceStatus<T: Codable> {
    let isReady: Bool
    let needsAuthorization: LocationPermissionRequest?
    let failure: Result<T>?
  }
}
