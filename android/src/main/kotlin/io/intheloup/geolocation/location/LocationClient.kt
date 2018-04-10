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
    private var currentLocationRequest: LocationRequest? = null
    private var isPaused = false

    private val locationCallback: LocationCallback = object : LocationCallback() {
        override fun onLocationResult(result: LocationResult) {
            onLocationUpdatesResult(Result.success(result.locations.map { LocationData.from(it) }))
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
            Result.success(arrayOf(LocationData.from(location)))
        } else {
            Result.failure(Result.Error.Type.LocationNotFound)
        }
    }


    // Updates API

    suspend fun addLocationUpdatesRequest(request: LocationUpdatesRequest) {
        val validity = validateServiceStatus()
        if (!validity.isValid) {
            onLocationUpdatesResult(validity.failure!!)
            return
        }

        locationUpdatesRequests.add(request)
        updateRunningRequest()
    }

    suspend fun removeLocationUpdatesRequest(request: LocationUpdatesRequest) {
        locationUpdatesRequests.removeAll { it.id == request.id }
        updateRunningRequest()
    }

    fun registerLocationUpdatesCallback(callback: (Result) -> Unit) {
        check(locationUpdatesCallback == null, { "trying to register a 2nd location updates callback" })
        locationUpdatesCallback = callback
    }

    fun deregisterLocationUpdatesCallback() {
        check(locationUpdatesCallback != null, { "trying to deregister a non-existent location updates callback" })
        locationUpdatesCallback = null
    }


    // Lifecycle API

    fun resume() {
        if (currentLocationRequest == null || !isPaused) {
            return
        }

        isPaused = false
        locationProviderClient.requestLocationUpdates(currentLocationRequest!!, locationCallback, null)
    }

    fun pause() {
        if (currentLocationRequest == null || isPaused || locationUpdatesRequests.any { it.inBackground }) {
            return
        }

        isPaused = true
        locationProviderClient.removeLocationUpdates(locationCallback)
    }


    // Location updates

    private fun onLocationUpdatesResult(result: Result) {
        locationUpdatesCallback?.invoke(result)
    }

    private suspend fun updateRunningRequest() {
        if (locationUpdatesRequests.isEmpty()) {
            currentLocationRequest = null
            isPaused = false
            locationProviderClient.removeLocationUpdates(locationCallback)
            return
        }

        if (locationUpdatesRequests.all { it.strategy == LocationUpdatesRequest.Strategy.Current }) {
            val lastKnownSuccessful = currentLocation()
            if (lastKnownSuccessful) {
                return
            }
        }

        val locationRequest = LocationRequest.create()
        locationRequest.setExpirationDuration(30000)

        locationRequest.priority = locationUpdatesRequests.map { it.accuracy.android.androidValue }
                .sortedWith(Comparator { o1, o2 ->
                    when (o1) {
                        o2 -> 0
                        LocationHelper.getBestPriority(o1, o2) -> 1
                        else -> -1
                    }
                })
                .first()

        locationRequest.smallestDisplacement = locationUpdatesRequests.map { it.displacementFilter }.min()!!

        if (locationUpdatesRequests.any { it.strategy == LocationUpdatesRequest.Strategy.Continuous }) {
            locationRequest.interval = 10000
            locationRequest.fastestInterval = 5000
        } else {
            locationRequest.numUpdates = 1
        }

        if (currentLocationRequest != null &&
                (currentLocationRequest!!.priority != locationRequest.priority ||
                        currentLocationRequest!!.numUpdates != locationRequest.numUpdates ||
                        currentLocationRequest!!.interval != locationRequest.interval ||
                        currentLocationRequest!!.fastestInterval != locationRequest.fastestInterval)) {
            locationProviderClient.removeLocationUpdates(locationCallback)
        }

        currentLocationRequest = locationRequest

        if (!isPaused) {
            locationProviderClient.requestLocationUpdates(locationRequest!!, locationCallback, null)
        }
    }

    private suspend fun currentLocation(): Boolean {
        val result = try {
            val availability = locationAvailability()
            if (availability.isLocationAvailable) {
                val location = lastLocation()
                if (location != null) {
                    Result.success(arrayOf(LocationData.from(location)))
                } else {
                    null
                }
            } else {
                null
            }
        } catch (e: Exception) {
            Result.failure(Result.Error.Type.Runtime, message = e.message)
        }

        if (result != null) {
            onLocationUpdatesResult(result)
        }

        return result != null
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