//
//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0
//

import Foundation
import CoreLocation

struct LocationHelper {
  
  // Accuracies ordered from lowest to highest
  // Might not be needed if double values are already ordered in linear manner
  private static let accuracies = [kCLLocationAccuracyThreeKilometers,
                                       kCLLocationAccuracyKilometer,
                                       kCLLocationAccuracyHundredMeters,
                                       kCLLocationAccuracyNearestTenMeters,
                                       kCLLocationAccuracyBest,
                                       kCLLocationAccuracyBestForNavigation
  ]
  
  static func betterAccuracy(between a1: CLLocationAccuracy, and a2: CLLocationAccuracy) -> CLLocationAccuracy {
    return accuracies.index(of: a1)! > accuracies.index(of: a2)! ? a1 : a2
  }
}
