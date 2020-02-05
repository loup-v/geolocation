//
//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0
//

import Foundation
import CoreLocation

class LocationClient : NSObject, CLLocationManagerDelegate {
  
  private let locationManager = CLLocationManager()
  private var permissionCallbacks: Array<Callback<Void, Void>> = []
  private var permissionSettingsCallback: (() -> Void)? = nil
  
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
  
  func isLocationOperational(with permission: Permission) -> Result<Bool> {
    let status: ServiceStatus<Bool> = currentServiceStatus(with: permission)
    return status.isReady ? Result<Bool>.success(with: true) : status.failure!
  }
  
  func requestLocationPermission(with permission: PermissionRequest, _ callback: @escaping (Result<Bool>) -> Void) {
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
      self.locationUpdatesCallback?(result)
    })
  }
  
  func removeLocationUpdates(requestId: Int) {
    guard let index = locationUpdatesRequests.firstIndex(where: { $0.id == requestId }) else {
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
    if let callback = permissionSettingsCallback {
      callback()
      permissionSettingsCallback = nil
    }
    
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
    let permissionRequest = PermissionRequest(value: permission, openSettingsIfDenied: false)
    runWithValidServiceStatus(with: permissionRequest, success: success, failure: failure)
  }
  
  private func runWithValidServiceStatus<T>(with permission: PermissionRequest, success: @escaping () -> Void, failure: @escaping (Result<T>) -> Void) {
    let status: ServiceStatus<T> = currentServiceStatus(with: permission.value)
    
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
        if #available(iOS 10.0, *),
          status.failure!.error!.type == .permissionDenied,
          permission.openSettingsIfDenied,
          let appSettingURl = URL(string: UIApplication.openSettingsURLString),
          UIApplication.shared.canOpenURL(appSettingURl) {
          permissionSettingsCallback = {
            let refreshedStatus: ServiceStatus<T> = self.currentServiceStatus(with: permission.value)
            if refreshedStatus.isReady {
              success()
            } else {
              failure(refreshedStatus.failure!)
            }
          }
          UIApplication.shared.openURL(appSettingURl)
        } else {
          failure(status.failure!)
        }
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
      
      return ServiceStatus<T>(isReady: false, needsAuthorization: permission, failure: Result<T>.failure(of: .permissionNotGranted))
    case .denied:
      return ServiceStatus<T>(isReady: false, needsAuthorization: nil, failure: Result<T>.failure(of: .permissionDenied))
    case .restricted:
      return ServiceStatus<T>(isReady: false, needsAuthorization: nil, failure: Result<T>.failure(of: .serviceDisabled))
    case .authorizedWhenInUse, .authorizedAlways:
      return ServiceStatus<T>(isReady: true, needsAuthorization: nil, failure: nil)
    @unknown default:
      fatalError("Unknown CLLocationManager.authorizationStatus(): \(CLLocationManager.authorizationStatus())")
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
    locationUpdatesCallback?(Result<[Location]>.failure(of: .runtime, message: error.localizedDescription))
  }
  
  struct Callback<T, E> {
    let success: (T) -> Void
    let failure: (E) -> Void
  }
  
  typealias LocationUpdatesCallback = (Result<[Location]>) -> Void
  
  struct ServiceStatus<T: Codable> {
    let isReady: Bool
    let needsAuthorization: Permission?
    let failure: Result<T>?
  }
}
