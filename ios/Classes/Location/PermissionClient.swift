//
//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0
//

import Foundation
import CoreLocation

class PermissionClient : NSObject, CLLocationManagerDelegate {
  
  private let locationManager = CLLocationManager()
  private var permissionCallbacks: Array<Callback<Void, Void>> = []
  
  override init() {
    super.init()
    locationManager.delegate = self
  }
  
  
  // API
  
  func check(permission: Permission) -> Result {
    let status: ServiceStatus = currentServiceStatus(with: permission)
    return status.isReady ? Result.success(with: true) : status.failure!
  }
  
  func request(permission: Permission, _ callback: @escaping (Result) -> Void) {
    runWithValidServiceStatus(with: permission, success: {
      callback(Result.success(with: true))
    }, failure: { result in
      callback(result)
    })
  }
  
  
  
  
  // Service status
  
  private func runWithValidServiceStatus(with permission: Permission, success: @escaping () -> Void, failure: @escaping (Result) -> Void) {
    let status: ServiceStatus = currentServiceStatus(with: permission)
    
    if status.isReady {
      success()
    } else {
      if let permission = status.needsAuthorization {
        let callback = Callback<Void, Void>(
          success: { _ in success() },
          failure: { _ in failure(Result.failure(of: .permissionDenied)) }
        )
        permissionCallbacks.append(callback)
        locationManager.requestAuthorization(for: permission)
      } else {
        failure(status.failure!)
      }
    }
  }
  
  private func currentServiceStatus(with permission: Permission) -> ServiceStatus {
    guard CLLocationManager.locationServicesEnabled() else {
      return ServiceStatus(isReady: false, needsAuthorization: nil, failure: Result.failure(of: .serviceDisabled))
    }
    
    switch CLLocationManager.authorizationStatus() {
    case .notDetermined:
      guard locationManager.isPermissionDeclared(for: permission) else {
        return ServiceStatus(isReady: false, needsAuthorization: nil, failure: Result.failure(of: .runtime, message: "Missing location usage description values in Info.plist. See readme for details.", fatal: true))
      }
      
      return ServiceStatus(isReady: false, needsAuthorization: permission, failure: Result.failure(of: .permissionDenied))
    case .denied:
      return ServiceStatus(isReady: false, needsAuthorization: nil, failure: Result.failure(of: .permissionDenied))
    case .restricted:
      return ServiceStatus(isReady: false, needsAuthorization: nil, failure: Result.failure(of: .serviceDisabled))
    case .authorizedWhenInUse, .authorizedAlways:
      return ServiceStatus(isReady: true, needsAuthorization: nil, failure: nil)
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
  
  
  
  struct Callback<T, E> {
    let permission: Permission
    let success: (T) -> Void
    let failure: (E) -> Void
  }
  
  struct PermissionResult {
    
  }
  
  struct ServiceStatus {
    let isReady: Bool
    let needsAuthorization: Permission?
    let failure: Result?
  }
}
