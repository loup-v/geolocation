//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

package app.loup.geolocation.data

import android.location.Location
import android.os.Build

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
        isMocked = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) location.isFromMockProvider else false
    )
  }
}