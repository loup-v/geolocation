//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

package io.alfanhui.new_geolocation.data

import android.location.Location

class LocationData(val latitude: Double,
                   val longitude: Double,
                   val altitude: Double,
                   val isMocked: Boolean
) {
    companion object {
        fun from(location: Location) = LocationData(
                latitude = location.latitude,
                longitude = location.longitude,
                altitude = location.altitude,
                isMocked = location.isFromMockProvider()
        )
    }
}