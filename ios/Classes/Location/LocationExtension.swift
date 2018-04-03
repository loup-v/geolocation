//
//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0
//

import UIKit
import CoreLocation

extension CLLocationManager {
  
  func findRequestedPermission() -> LocationPermissionRequest {
    let isAlwaysRequested: Bool
    let isWhenInUseRequested: Bool
    
    if (UIDevice.current.systemVersion as NSString).floatValue < 11 {
      isAlwaysRequested = hasPlistValue(forKey: "NSLocationAlwaysUsageDescription") && hasPlistValue(forKey: "NSLocationAlwaysAndWhenInUseUsageDescription")
      isWhenInUseRequested = hasPlistValue(forKey: "NSLocationWhenInUseUsageDescription")
    } else {
      isAlwaysRequested = hasPlistValue(forKey: "NSLocationAlwaysAndWhenInUseUsageDescription")
      isWhenInUseRequested = hasPlistValue(forKey: "NSLocationWhenInUseUsageDescription")
    }
    
    if isAlwaysRequested {
      return .always
    } else if isWhenInUseRequested {
      return .whenInUse
    } else {
      return .undefined
    }
  }
  
  func requestAuthorization(for permission: LocationPermissionRequest) {
    switch permission {
    case .always:
      self.requestAlwaysAuthorization()
    case .whenInUse:
      self.requestWhenInUseAuthorization()
    case .undefined:
      fatalError()
    }
  }
  
  private func hasPlistValue(forKey key: String) -> Bool {
    guard let plist = Bundle.main.infoDictionary, let value = plist[key] as? String else { return false }
    return !value.isEmpty
  }
}
