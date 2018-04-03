//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

package io.intheloup.geolocation.location

import android.annotation.SuppressLint
import android.content.Context
import android.location.Location
import com.google.android.gms.location.*
import kotlin.coroutines.experimental.suspendCoroutine

class LocationClient(context: Context) {

    private val locationProviderClient: FusedLocationProviderClient = LocationServices.getFusedLocationProviderClient(context)

    @SuppressLint("MissingPermission")
    suspend fun locationAvailability(): LocationAvailability = suspendCoroutine { cont ->
        locationProviderClient.locationAvailability
                .addOnSuccessListener { cont.resume(it) }
                .addOnFailureListener { cont.resumeWithException(it) }
    }

    @SuppressLint("MissingPermission")
    suspend fun lastLocation(): Location? = suspendCoroutine { cont ->
        locationProviderClient.lastLocation
                .addOnSuccessListener { location: Location? -> cont.resume(location) }
                .addOnFailureListener { cont.resumeWithException(it) }
    }

    @SuppressLint("MissingPermission")
    suspend fun singleLocationUpdate(priority: Int): Location? = suspendCoroutine { cont ->
        val request = LocationRequest.create()
        request.priority = priority
        request.numUpdates = 1
        request.setExpirationDuration(30000)

        locationProviderClient.requestLocationUpdates(request, object : LocationCallback() {
            override fun onLocationResult(result: LocationResult) {
                cont.resume(result.lastLocation)
            }
        }, null)
    }
}