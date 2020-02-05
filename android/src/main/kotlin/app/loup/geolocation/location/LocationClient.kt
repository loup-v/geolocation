//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

package app.loup.geolocation.location

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.net.Uri
import android.provider.Settings
import androidx.core.app.ActivityCompat
import app.loup.geolocation.GeolocationPlugin
import app.loup.geolocation.data.*
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.common.api.ApiException
import com.google.android.gms.common.api.ResolvableApiException
import com.google.android.gms.location.*
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine


@SuppressLint("MissingPermission")
class LocationClient(private val context: Context) {

  var activity: Activity? = null

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

  val activityResultListener: PluginRegistry.ActivityResultListener = PluginRegistry.ActivityResultListener { id, resultCode, _ ->
    when (id) {
      GeolocationPlugin.Intents.LocationPermissionSettingsRequestId -> {
        permissionSettingsCallback?.invoke()
        permissionSettingsCallback = null
        return@ActivityResultListener true
      }

      GeolocationPlugin.Intents.EnableLocationSettingsRequestId -> {
        if (resultCode == Activity.RESULT_OK) {
          locationSettingsCallbacks.forEach { it.success(Unit) }
        } else {
          locationSettingsCallbacks.forEach { it.failure(Unit) }
        }
        locationSettingsCallbacks.clear()

        return@ActivityResultListener true
      }
    }

    return@ActivityResultListener false
  }

  private val providerClient: FusedLocationProviderClient = LocationServices.getFusedLocationProviderClient(context)
  private val permissionCallbacks = ArrayList<Callback<Unit, Unit>>()
  private var permissionSettingsCallback: (() -> Unit)? = null
  private val locationSettingsCallbacks = ArrayList<Callback<Unit, Unit>>()

  private var locationUpdatesCallback: ((Result) -> Unit)? = null
  private val locationUpdatesRequests = ArrayList<LocationUpdatesRequest>()
  private var currentLocationRequest: LocationRequest? = null

  private val hasLocationRequest get() = currentLocationRequest != null
  private val hasInBackgroundLocationRequest get() = locationUpdatesRequests.any { it.inBackground }

  private var isPaused = false

  private val locationCallback: LocationCallback = object : LocationCallback() {
    override fun onLocationResult(result: LocationResult) {
      onLocationUpdatesResult(Result.success(result.locations.map { LocationData.from(it) }))
    }
  }

  suspend fun enableLocationServices(): Result {
    return if (LocationHelper.isLocationEnabled(context)) {
      Result.success(true)
    } else {
      Result(requestEnablingLocation())
    }
  }

  // One shot API

  fun isLocationOperational(permission: Permission): Result {
    val status = currentServiceStatus(permission)
    return if (status.isReady) {
      Result.success(true)
    } else {
      status.failure!!
    }
  }

  suspend fun requestLocationPermission(permission: PermissionRequest): Result {
    val validity = validateServiceStatus(permission)
    return if (validity.isValid) {
      Result.success(true)
    } else {
      validity.failure!!
    }
  }

  suspend fun lastKnownLocation(permission: Permission): Result {
    val validity = validateServiceStatus(permission)
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
    val validity = validateServiceStatus(request.permission)
    if (!validity.isValid) {
      onLocationUpdatesResult(validity.failure!!)
      return
    }

    locationUpdatesRequests.add(request)
    updateLocationRequest()
  }

  fun removeLocationUpdatesRequest(id: Int) {
    locationUpdatesRequests.removeAll { it.id == id }
    updateLocationRequest()
  }

  fun registerLocationUpdatesCallback(callback: (Result) -> Unit) {
    check(locationUpdatesCallback == null) { "trying to register a 2nd location updates callback" }
    locationUpdatesCallback = callback
  }

  fun deregisterLocationUpdatesCallback() {
    check(locationUpdatesCallback != null) { "trying to deregister a non-existent location updates callback" }
    locationUpdatesCallback = null
  }


  // Lifecycle API

  fun resume() {
    if (!hasLocationRequest || !isPaused) {
      return
    }

    isPaused = false
    updateLocationRequest()
  }

  fun pause() {
    if (!hasLocationRequest || isPaused || hasInBackgroundLocationRequest) {
      return
    }

    isPaused = true
    updateLocationRequest()
    providerClient.removeLocationUpdates(locationCallback)
  }


  // Location updates logic

  private fun onLocationUpdatesResult(result: Result) {
    locationUpdatesCallback?.invoke(result)
  }

  private fun updateLocationRequest() {
    GlobalScope.launch(Dispatchers.Main) {
      if (locationUpdatesRequests.isEmpty()) {
        currentLocationRequest = null
        isPaused = false
        providerClient.removeLocationUpdates(locationCallback)
        return@launch
      }

      if (currentLocationRequest != null) {
        providerClient.removeLocationUpdates(locationCallback)
      }

      if (isPaused) {
        return@launch
      }

      val hasCurrentRequest = locationUpdatesRequests.any { it.strategy == LocationUpdatesRequest.Strategy.Current }
      if (hasCurrentRequest) {
        val lastLocationResult = lastLocationIfAvailable()
        if (lastLocationResult != null) {
          onLocationUpdatesResult(lastLocationResult)

          val hasOnlyCurrentRequest = locationUpdatesRequests.all { it.strategy == LocationUpdatesRequest.Strategy.Current }
          if (hasOnlyCurrentRequest) {
            return@launch
          }
        }
      }

      val locationRequest = LocationRequest.create()

      locationRequest.priority = locationUpdatesRequests.map { it.accuracy.androidValue }
          .sortedWith(Comparator { o1, o2 ->
            when (o1) {
              o2 -> 0
              LocationHelper.getBestPriority(o1, o2) -> 1
              else -> -1
            }
          })
          .first()

      locationUpdatesRequests.map { it.displacementFilter }
          .min()!!
          .takeIf { it > 0 }
          ?.let { locationRequest.smallestDisplacement = it }

      locationUpdatesRequests
          .filter { it.options.interval != null }
          .map { it.options.interval!! }
          .min()
          ?.let { locationRequest.interval = it }

      locationUpdatesRequests
          .filter { it.options.fastestInterval != null }
          .map { it.options.fastestInterval!! }
          .min()
          ?.let { locationRequest.fastestInterval = it }

      locationUpdatesRequests
          .filter { it.options.expirationTime != null }
          .map { it.options.expirationTime!! }
          .min()
          ?.let { locationRequest.expirationTime = it }

      locationUpdatesRequests
          .filter { it.options.expirationDuration != null }
          .map { it.options.expirationDuration!! }
          .min()
          ?.let { locationRequest.setExpirationDuration(it) }

      locationUpdatesRequests
          .filter { it.options.maxWaitTime != null }
          .map { it.options.maxWaitTime!! }
          .min()
          ?.let { locationRequest.maxWaitTime = it }

      if (locationUpdatesRequests.any { it.strategy == LocationUpdatesRequest.Strategy.Continuous }) {
        locationUpdatesRequests
            .filter { it.options.numUpdates != null }
            .map { it.options.numUpdates!! }
            .max()
            ?.let { locationRequest.numUpdates = it }
      } else {
        locationRequest.numUpdates = 1
      }

      currentLocationRequest = locationRequest

      if (!isPaused) {
        providerClient.requestLocationUpdates(currentLocationRequest!!, locationCallback, null)
      }
    }
  }

  private suspend fun lastLocationIfAvailable(): Result? {
    return try {
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
//
//        if (result != null) {
//            onLocationUpdatesResult(result)
//        }
//
//        return result != null
  }


  // Service status

  private suspend fun validateServiceStatus(permission: Permission): ValidateServiceStatus {
    return validateServiceStatus(PermissionRequest(permission, openSettingsIfDenied = false))
  }

  private suspend fun validateServiceStatus(permission: PermissionRequest): ValidateServiceStatus {
    val status = currentServiceStatus(permission.value)
    if (status.isReady) return ValidateServiceStatus(true)

    return if (status.needsAuthorization) {
      if (requestPermission(permission.value)) {
        ValidateServiceStatus(true)
      } else {
        ValidateServiceStatus(false, Result.failure(Result.Error.Type.PermissionDenied))
      }
    } else if (status.failure!!.error!!.type == Result.Error.Type.PermissionDenied && permission.openSettingsIfDenied && tryShowSettings()) {
      val refreshedStatus = currentServiceStatus(permission.value)
      return if (refreshedStatus.isReady) {
        ValidateServiceStatus(true)
      } else {
        ValidateServiceStatus(false, refreshedStatus.failure)
      }
    } else {
      ValidateServiceStatus(false, status.failure!!)
    }
  }


  private fun currentServiceStatus(permission: Permission): ServiceStatus {
    val connectionResult = GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable(context)
    if (connectionResult != ConnectionResult.SUCCESS) {
      return ServiceStatus(isReady = false, needsAuthorization = false,
          failure = Result.failure(Result.Error.Type.PlayServicesUnavailable,
              playServices = Result.Error.PlayServices.fromConnectionResult(connectionResult)))
    }

    if (!LocationHelper.isLocationEnabled(context)) {
      return ServiceStatus(isReady = false, needsAuthorization = false, failure = Result.failure(Result.Error.Type.ServiceDisabled))
    }

    if (!LocationHelper.isPermissionDeclared(context, permission)) {
      return ServiceStatus(isReady = false, needsAuthorization = false, failure = Result.failure(Result.Error.Type.Runtime, message = "Missing location permission in AndroidManifest.xml. You need to add one of ACCESS_FINE_LOCATION or ACCESS_COARSE_LOCATION. See readme for details.", fatal = true))
    }

    if (activity != null && LocationHelper.isPermissionDeclined(activity!!, permission)) {
      return ServiceStatus(isReady = false, needsAuthorization = false, failure = Result.failure(Result.Error.Type.PermissionDenied))
    }

    if (!LocationHelper.isPermissionGranted(context)) {
      return ServiceStatus(isReady = false, needsAuthorization = true, failure = Result.failure(Result.Error.Type.PermissionNotGranted))
    }

    return ServiceStatus(true)
  }


  // Permission

  private suspend fun tryShowSettings(): Boolean = suspendCoroutine { cont ->
    if (activity == null) {
      cont.resume(false)
      return@suspendCoroutine
    }

    permissionSettingsCallback = {
      cont.resume(true)
    }

    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", context.packageName, null))
    activity!!.startActivityForResult(intent, GeolocationPlugin.Intents.LocationPermissionSettingsRequestId)
  }

  private suspend fun requestPermission(permission: Permission): Boolean = suspendCoroutine { cont ->
    if (activity == null) {
      cont.resume(false)
      return@suspendCoroutine
    }

    val callback = Callback<Unit, Unit>(
        success = { cont.resume(true) },
        failure = { cont.resume(false) }
    )
    permissionCallbacks.add(callback)

    ActivityCompat.requestPermissions(activity!!, arrayOf(permission.manifestValue), GeolocationPlugin.Intents.LocationPermissionRequestId)
  }

  private suspend fun requestEnablingLocation(): Boolean = suspendCoroutine { cont ->
    val callback = Callback<Unit, Unit>(
        success = { cont.resume(true) },
        failure = { cont.resume(false) }
    )

    val request = LocationRequest()
    request.priority = LocationRequest.PRIORITY_HIGH_ACCURACY

    LocationServices
        .getSettingsClient(context)
        .checkLocationSettings(
            LocationSettingsRequest
                .Builder()
                .addLocationRequest(request)
                .setAlwaysShow(true)
                .build()
        ).addOnSuccessListener {
          callback.success(Unit)
        }.addOnFailureListener { exception ->
          when (exception) {
            is ApiException -> when (exception.statusCode) {
              LocationSettingsStatusCodes.RESOLUTION_REQUIRED -> {
                if (activity == null) {
                  callback.failure(Unit)
                  return@addOnFailureListener
                }

                try {
                  val resolvable = exception as ResolvableApiException
                  resolvable.startResolutionForResult(activity, GeolocationPlugin.Intents.EnableLocationSettingsRequestId)
                  locationSettingsCallbacks.add(callback)
                } catch (ignore: java.lang.Exception) {
                  callback.failure(Unit)
                }
              }

              else -> {
                callback.failure(Unit)
              }
            }

            else -> {
              callback.failure(Unit)
            }
          }
        }
  }

  // Location helpers

  private suspend fun locationAvailability(): LocationAvailability = suspendCoroutine { cont ->
    providerClient.locationAvailability
        .addOnSuccessListener { cont.resume(it) }
        .addOnFailureListener { cont.resumeWithException(it) }
  }

  private suspend fun lastLocation(): Location? = suspendCoroutine { cont ->
    providerClient.lastLocation
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
