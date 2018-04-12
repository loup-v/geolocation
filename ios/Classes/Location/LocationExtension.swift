//
//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0
//

import UIKit
import CoreLocation

extension CLLocationManager {
  
  func isPermissionDeclared(for permission: Permission) -> Bool {
    if (UIDevice.current.systemVersion as NSString).floatValue < 11 {
      let isAlwaysRequested = hasPlistValue(forKey: "NSLocationAlwaysUsageDescription") && hasPlistValue(forKey: "NSLocationAlwaysAndWhenInUseUsageDescription")
      let isWhenInUseRequested = hasPlistValue(forKey: "NSLocationWhenInUseUsageDescription")
      
      return isAlwaysRequested && permission == .always || isWhenInUseRequested
    } else {
      return hasPlistValue(forKey: "NSLocationAlwaysAndWhenInUseUsageDescription") && hasPlistValue(forKey: "NSLocationWhenInUseUsageDescription")
    }
  }
  
  func requestAuthorization(for permission: Permission) {
    switch permission {
    case .always:
      self.requestAlwaysAuthorization()
    case .whenInUse:
      self.requestWhenInUseAuthorization()
    }
  }
  
  private func hasPlistValue(forKey key: String) -> Bool {
    guard let plist = Bundle.main.infoDictionary, let value = plist[key] as? String else { return false }
    return !value.isEmpty
  }
}
