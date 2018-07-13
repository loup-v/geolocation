//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

package io.intheloup.geolocation.data

import com.google.android.gms.location.Geofence

class GeofenceData(val id: String,
//                   val region: Region,
                   val notifyOnEntry: Boolean,
                   val notifyOnExit: Boolean
) {
    companion object {
        fun from(geofence: Geofence) = GeofenceData(
                id = geofence.requestId,

                notifyOnEntry = false,
                notifyOnExit = false
        )
    }
}


//class Region(
//        val center: Location,
//        val radius: Double) {
//    companion object {
//        fun from(location: Location) = LocationData(
//                latitude = location.latitude,
//                longitude = location.longitude,
//                altitude = location.altitude
//        )
//    }
//    init(from region: CLCircularRegion)
//    {
//        self.center = Location(from: region. center)
//        self.radius = region.radius
//    }
//}

//class GeofenceRegion(
//    val region: Region,
//    val id: String,
//    val notifyOnEntry: Bool,
//    val notifyOnExit: Bool){
//    {
//    companion object {
//        fun from(geofence: Geofence) = Geofence(
//                latitude = location.latitude,
//                longitude = location.longitude,
//                altitude = location.altitude
//                        self.region = Region(from: region)
//        self.id = region.identifier
//        self.notifyOnEntry = region.notifyOnEntry
//        self.notifyOnExit = region.notifyOnExit
//        )
//    }
//
//    var clRegion: CLCircularRegion {
//        val result = CLCircularRegion(center: self. region . center . coordinate2D, radius: self.region.radius, identifier: self.id)
//        result.notifyOnExit = self.notifyOnExit
//        result.notifyOnEntry = self.notifyOnEntry
//        return result
//    }
//}
//
//enum GeofenceEventType: String, Codable {
//    case entered, exited
//}
//
//data class GeofenceEvent (
//    val type: GeofenceEventType
//    val geofenceRegion: GeofenceRegion
//){
//    init(region: CLCircularRegion, type: GeofenceEventType) {
//        self.type = type
//        self.geofenceRegion = GeofenceRegion(from: region)
//    }
//}
