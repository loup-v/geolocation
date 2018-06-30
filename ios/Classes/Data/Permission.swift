//
//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0
//

import Foundation
import CoreLocation

enum Permission: String, Codable {
  case whenInUse = "whenInUse"
  case always = "always"
}

extension Permission {
  func statusIsSufficient(_ status: CLAuthorizationStatus) -> Bool {
    switch status {
    case .authorizedAlways:
      return true
    case .authorizedWhenInUse:
        switch self {
        case .always:
          return false
        case .whenInUse:
          return true
      }
    default:
      return false
    }
  }
}
