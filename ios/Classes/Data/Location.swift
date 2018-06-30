//
//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0
//

import Foundation
import CoreLocation

struct Location : Codable {
  let latitude: Double
  let longitude: Double
  let altitude: Double

  init(from location: CLLocation) {
    self.latitude = location.coordinate.latitude
    self.longitude = location.coordinate.longitude
    self.altitude = location.altitude as Double
  }
  
  init(from coordinate: CLLocationCoordinate2D) {
    self.latitude = coordinate.latitude
    self.longitude = coordinate.longitude
    self.altitude = 0
  }
  
  var coordinate2D: CLLocationCoordinate2D {
    return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
  }
}


