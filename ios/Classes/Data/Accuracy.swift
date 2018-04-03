//
//  Accuracy.swift
//  geolocation
//
//  Created by Lukasz on 01/04/2018.
//

import Foundation
import CoreLocation

enum Accuracy: String, Codable {
  case threeKilometers = "threeKilometers"
  case kilometer = "kilometer"
  case hundredMeters = "hundredMeters"
  case nearestTenMeters = "NearestTenMeters"
  case best = "best"
  case bestForNavigation = "bestForNavigation"
  
  var clValue: CLLocationAccuracy {
    switch self {
    case .threeKilometers:
      return kCLLocationAccuracyThreeKilometers
    case .kilometer:
      return kCLLocationAccuracyKilometer
    case .hundredMeters:
      return kCLLocationAccuracyHundredMeters
    case .nearestTenMeters:
      return kCLLocationAccuracyNearestTenMeters
    case .best:
      return kCLLocationAccuracyBest
    case .bestForNavigation:
      return kCLLocationAccuracyBestForNavigation
    }
  }
}
