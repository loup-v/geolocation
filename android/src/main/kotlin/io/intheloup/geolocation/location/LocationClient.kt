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
import kotlinx.coroutines.experimental.android.UI
import kotlinx.coroutines.experimental.launch
import kotlin.coroutines.experimental.suspendCoroutine

@SuppressLint("MissingPermission")
class LocationClient(private val activity: Activity) {

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


    private val locationProviderClient: FusedLocationProviderClient = LocationServices.getFusedLocationProviderClient(activity)
    private val permissionCallbacks = ArrayList<Callback<Unit, Unit>>()
    private val locationUpdatesRequests = ArrayList<LocationUpdatesRequest>()
    private var locationUpdatesCallback: ((Result) -> Unit)? = null
    private var locationRequest: LocationRequest? = null

    private val locationCallback: LocationCallback = object : LocationCallback() {
        override fun onLocationResult(result: LocationResult) {
            onLocationUpdatesResult(Result.success(LocationData.from(result.lastLocation)))
        }
    }


    // One shot API

    suspend fun isLocationOperational(): Result {
        val status = currentServiceStatus()
        return if (status.isReady) {
            Result.success(true)
        } else {
            status.failure!!
        }
    }

    suspend fun requestLocationPermission(): Result {
        val validity = validateServiceStatus()
        return if (validity.isValid) {
            Result.success(true)
        } else {
            validity.failure!!
        }
    }

    suspend fun lastKnownLocation(): Result {
        val validity = validateServiceStatus()
        if (!validity.isValid) {
            return validity.failure!!
        }

        val location = try {
            lastLocation()
        } catch (e: Exception) {
            return Result.failure(Result.Error.Type.Runtime, message = e.message)
        }

        return if (location != null) {
            Result.success(LocationData.from(location))
        } else {
            Result.failure(Result.Error.Type.LocationNotFound)
        }
    }


    // Updates API

    fun addLocationUpdatesRequest(request: LocationUpdatesRequest) {
        launch(UI) {
            val validity = validateServiceStatus()
            if (!validity.isValid) {
                onLocationUpdatesResult(validity.failure!!)
                return@launch
            }

            val isAnyRequestRunning = locationUpdatesRequests.isNotEmpty()
            val isContinuousRequestRunning = locationUpdatesRequests.any { it.strategy == LocationUpdatesRequest.Strategy.Continuous }

            val locationRequest = LocationRequest.create()
            locationRequest.setExpirationDuration(30000)

            if (isAnyRequestRunning) {
                locationProviderClient.removeLocationUpdates(locationCallback)
                locationRequest.priority = LocationHelper.getBestPriority(request.accuracy.android.androidValue, getBestRequestedPriority())
            } else {
                locationRequest.priority = request.accuracy.android.androidValue
            }

            if (isContinuousRequestRunning || request.strategy == LocationUpdatesRequest.Strategy.Continuous) {
                locationRequest.interval = 10000
                locationRequest.fastestInterval = 5000
            } else {
                locationRequest.numUpdates = 1
            }

            locationProviderClient.requestLocationUpdates(locationRequest, locationCallback, null)
        }
    }

    fun removeLocationUpdatesRequest(request: LocationUpdatesRequest) {
        locationUpdatesRequests.removeAll { it.id == request.id }

        if (locationUpdatesRequests.isEmpty()) {
            locationRequest = null
        } else {
            val newPriority = LocationHelper.getBestPriority(locationRequest!!.priority, getBestRequestedPriority())
            if (newPriority != locationRequest!!.priority) {
                locationRequest!!.priority = newPriority
                locationProviderClient.removeLocationUpdates(locationCallback)
                locationProviderClient.requestLocationUpdates(locationRequest!!, locationCallback, null)
            }
        }
    }

    fun registerForLocationUpdates(callback: (Result) -> Unit) {
        check(locationUpdatesCallback == null, { "trying to register a 2nd location updates callback" })
        locationUpdatesCallback = callback
    }

    fun stopLocationUpdates() {
        check(locationUpdatesCallback != null, { "trying to unregister a non-existent location updates callback" })
        locationUpdatesCallback = null
        locationProviderClient.removeLocationUpdates(locationCallback)
    }


    // Location updates

    private fun onLocationUpdatesResult(result: Result) {
        locationUpdatesCallback!!(result)
    }


    // Service status

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


    // Permission

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


    // Location helpers

    private fun getBestRequestedPriority(): Int {
        check(locationUpdatesRequests.isNotEmpty(), { "no requests to getBestRequestedPriority()" })

        return locationUpdatesRequests.map { it.accuracy.android.androidValue }
                .sortedWith(Comparator { o1, o2 ->
                    when (o1) {
                        o2 -> 0
                        LocationHelper.getBestPriority(o1, o2) -> 1
                        else -> -1
                    }
                })
                .first()
    }

    private suspend fun locationAvailability(): LocationAvailability = suspendCoroutine { cont ->
        locationProviderClient.locationAvailability
                .addOnSuccessListener { cont.resume(it) }
                .addOnFailureListener { cont.resumeWithException(it) }
    }

    private suspend fun lastLocation(): Location? = suspendCoroutine { cont ->
        locationProviderClient.lastLocation
                .addOnSuccessListener { location: Location? -> cont.resume(location) }
                .addOnFailureListener { cont.resumeWithException(it) }
    }


    // Structures

    private class Callback<in T, in E>(val success: (T) -> Unit, val failure: (E) -> Unit)

    private class ServiceStatus(val isReady: Boolean,
                                val needsAuthorization: Boolean = false,
                                val failure: Result? = null)

    private class ValidateServiceStatus(val isValid: Boolean, val failure: Result? = null)
}