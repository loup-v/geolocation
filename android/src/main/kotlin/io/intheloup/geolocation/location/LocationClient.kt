//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

package io.intheloup.geolocation.location

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.content.pm.PackageManager
import android.location.Location
import android.support.v4.app.ActivityCompat
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.location.*
import io.flutter.plugin.common.PluginRegistry
import io.intheloup.geolocation.GeolocationPlugin
import io.intheloup.geolocation.data.LocationData
import io.intheloup.geolocation.data.LocationUpdatesRequest
import io.intheloup.geolocation.data.Result
import kotlin.coroutines.experimental.suspendCoroutine

class LocationClient(private val activity: Activity) {

    private val locationProviderClient: FusedLocationProviderClient = LocationServices.getFusedLocationProviderClient(activity)
    private val permissionCallbacks = ArrayList<Callback<Unit, Unit>>()

    val permissionResultListener: PluginRegistry.RequestPermissionsResultListener = PluginRegistry.RequestPermissionsResultListener { id, _, grantResults ->
        if (id == GeolocationPlugin.Intents.LocationPermissionRequestId) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                permissionCallbacks.forEach { it.success(Unit) }
            } else {
                permissionCallbacks.forEach { it.failure(Unit) }
            }
            permissionCallbacks.clear()
            return@RequestPermissionsResultListener true
        }

        return@RequestPermissionsResultListener false
    }

    suspend fun lastKnownLocation(): Result {
        val validity = validateServiceStatus()
        if (!validity.isValid) {
            return validity.failure!!
        }

        val location = lastLocation()
        return if (location != null) {
            Result.success(LocationData.from(location))
        } else {
            Result.failure(Result.Error.Type.LocationNotFound)
        }
    }

    @SuppressLint("MissingPermission")
    private suspend fun locationAvailability(): LocationAvailability = suspendCoroutine { cont ->
        locationProviderClient.locationAvailability
                .addOnSuccessListener { cont.resume(it) }
                .addOnFailureListener { cont.resumeWithException(it) }
    }

    @SuppressLint("MissingPermission")
    private suspend fun lastLocation(): Location? = suspendCoroutine { cont ->
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

    fun addLocationUpdatesRequest(request: LocationUpdatesRequest) {

    }

    fun removeLocationUpdatesRequest(request: LocationUpdatesRequest) {

    }

    private suspend fun requestPermission(): Boolean = suspendCoroutine { cont ->
        val callback = Callback<Unit, Unit>(
                success = { _ -> cont.resume(true) },
                failure = { _ -> cont.resume(false) }
        )
        permissionCallbacks.add(callback)

        val permission = if (LocationHelper.getLocationPermissionRequest(activity) == LocationHelper.LocationPermissionRequest.Fine) {
            Manifest.permission.ACCESS_FINE_LOCATION
        } else {
            Manifest.permission.ACCESS_COARSE_LOCATION
        }
        ActivityCompat.requestPermissions(activity, arrayOf(permission), GeolocationPlugin.Intents.LocationPermissionRequestId)
    }

    private suspend fun validateServiceStatus(): ValidateServiceStatus {
        val status = currentServiceStatus()
        if (status.isReady) return ValidateServiceStatus(true)

        return if (status.needsAuthorization) {
            if (requestPermission()) {
                ValidateServiceStatus(true)
            } else {
                ValidateServiceStatus(false, Result.failure(Result.Error.Type.PermissionDenied))
            }
        } else {
            ValidateServiceStatus(false, status.failure!!)
        }
    }

    private fun currentServiceStatus(): ServiceStatus {
        val connectionResult = GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable(activity)
        if (connectionResult != ConnectionResult.SUCCESS) {
            return ServiceStatus(false, false,
                    Result.failure(Result.Error.Type.PlayServicesUnavailable,
                            playServices = Result.Error.PlayServices.fromConnectionResult(connectionResult)))
        }

        if (!LocationHelper.isLocationEnabled(activity)) {
            return ServiceStatus(false, false, Result.failure(Result.Error.Type.ServiceDisabled))
        }

        if (LocationHelper.getLocationPermissionRequest(activity) == LocationHelper.LocationPermissionRequest.Undefined) {
            return ServiceStatus(false, false, Result.failure(Result.Error.Type.Runtime, message = "Missing location permission in AndroidManifest.xml. You need to add one of ACCESS_FINE_LOCATION or ACCESS_COARSE_LOCATION. See readme for details.", fatal = true))
        }

        if (!LocationHelper.hasLocationPermission(activity)) {
            return ServiceStatus(false, true, Result.failure(Result.Error.Type.PermissionDenied))
        }

        return ServiceStatus(true)
    }

    private class Callback<in T, in E>(val success: (T) -> Unit, val failure: (E) -> Unit)

    private inner class LocationUpdatesCallback : LocationCallback() {
        override fun onLocationResult(result: LocationResult) {

        }
    }

    private data class ServiceStatus(val isReady: Boolean,
                                     val needsAuthorization: Boolean = false,
                                     val failure: Result? = null)

    private data class ValidateServiceStatus(val isValid: Boolean, val failure: Result? = null)
}