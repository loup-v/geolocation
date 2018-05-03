//
//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0
//

import Foundation
import CoreLocation

struct GeoFence : Codable {
    
    let centerLatitude: Double
    let centerLongitude: Double
    let centerAltitude: Double = 0.0
    let radius: Double
    let identifier: String
    
    init(from location: CLLocation, radius: Double, identifier: String) {
        self.centerLatitude = location.coordinate.latitude
        self.centerLongitude = location.coordinate.longitude
        self.radius = radius
        self.identifier = identifier
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        radius = try values.decode(Double.self, forKey: .radius)
        identifier = try values.decode(String.self, forKey: .identifier)
        centerLatitude = try values.decode(Double.self, forKey: .centerLatitude)
        centerLongitude = try values.decode(Double.self, forKey: .centerLongitude)
    }
    
    private enum CodingKeys: String, CodingKey {
        case centerLatitude
        case centerLongitude
        case centerAltitude
        case radius
        case identifier
    }
    
    static func ==(lhs: GeoFence, rhs: GeoFence) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

struct GeoFenceResult: Codable{
    let id: Int
    let region: GeoFence
    let result: Bool
}

struct GeoFenceUpdatesRequest {
    let id: Int
    let region: GeoFence
    
    enum CodingKeys: String, CodingKey
    {
        case id
        case region
    }
}

extension GeoFenceUpdatesRequest: Decodable {
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int.self, forKey: .id)
        region = try values.decode(GeoFence.self, forKey: .region)
    }
    
}

class MonitoredRegion: NSObject {
    let id: Int
    let region: GeoFence
    var didEnter: (() -> ())?
    var didExit: (() -> ())?
    
    init(with id: Int, region: GeoFence, onEnter: (() -> ())?, onExit: (() -> ())?) {
        self.id = id
        self.region = region
        self.didEnter = onEnter
        self.didExit = onExit
    }
    
    func represents(circularRegion: CLCircularRegion) -> Bool {
        return self.region.identifier == circularRegion.identifier && self.region.radius == circularRegion.radius && self.region.centerLatitude == circularRegion.center.latitude && self.region.centerLongitude == circularRegion.center.longitude
    }
    
    static func ==(lhs: MonitoredRegion, rhs: MonitoredRegion) -> Bool {
        return lhs.region.identifier == rhs.region.identifier
    }
}
