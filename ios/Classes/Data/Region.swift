//
//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0
//

import Foundation
import CoreLocation

struct Region: Codable {
  let center: Location
  let radius: Double
  
  init(from region: CLCircularRegion) {
    self.center = Location(from: region.center)
    self.radius = region.radius
  }
}

struct GeofenceRegion: Codable {
  let region: Region
  let id: String
  let notifyOnEntry: Bool
  let notifyOnExit: Bool
  
  init(from region: CLCircularRegion) {
    self.region = Region(from: region)
    self.id = region.identifier
    self.notifyOnEntry = region.notifyOnEntry
    self.notifyOnExit = region.notifyOnExit
  }
  
  var clRegion: CLCircularRegion {
    let result = CLCircularRegion(center: self.region.center.coordinate2D, radius: self.region.radius, identifier: self.id)
    result.notifyOnExit = self.notifyOnExit
    result.notifyOnEntry = self.notifyOnEntry
    return result
  }
}

enum GeofenceEventType: String, Codable {
  case entered, exited
}

struct GeofenceEvent: Codable {
  let type: GeofenceEventType
  let geofenceRegion: GeofenceRegion
  
  init(region: CLCircularRegion, type: GeofenceEventType) {
    self.type = type
    self.geofenceRegion = GeofenceRegion(from: region)
  }
}
