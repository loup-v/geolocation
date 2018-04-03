//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

package io.intheloup.geolocation

import android.Manifest
import android.annotation.SuppressLint
import android.content.pm.PackageManager
import android.location.Location
import android.support.v4.app.ActivityCompat
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationServices
import com.google.android.gms.tasks.Task
import com.squareup.moshi.Moshi
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import io.intheloup.geolocation.data.LocationData
import io.intheloup.geolocation.data.Param
import io.intheloup.geolocation.data.Priority
import io.intheloup.geolocation.data.Response
import io.intheloup.geolocation.helper.AndroidHelper
import io.intheloup.geolocation.location.LocationClient
import kotlinx.coroutines.experimental.android.UI
import kotlinx.coroutines.experimental.launch

class GeolocationPlugin(private val registrar: Registrar) : MethodCallHandler {

    private val locationProviderClient: FusedLocationProviderClient = LocationServices.getFusedLocationProviderClient(registrar.activity())
    private val locationClient = LocationClient(registrar.context())
    private val moshi = Moshi.Builder().build()
    private val withLocationPermissionActions: ArrayList<DelayedResultAction<Unit, Unit>> = ArrayList()

    init {
        registrar.addRequestPermissionsResultListener { id, _, grantResults ->
            if (id == LocationPermissionRequestId) {
                if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    withLocationPermissionActions.forEach { it.successAction(Unit) }
                } else {
                    withLocationPermissionActions.forEach { it.failureAction(Unit) }
                }
                withLocationPermissionActions.clear()
                return@addRequestPermissionsResultListener true
            }

            return@addRequestPermissionsResultListener false
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "lastKnownLocation" -> lastKnownLocation(result)
            "currentLocation" -> currentLocation(decodeSingleLocationParam(call.arguments), result)
            "singleLocationUpdate" -> singleLocationUpdate(decodeSingleLocationParam(call.arguments), result)
            else -> result.notImplemented()
        }
    }

    private fun lastKnownLocation(result: Result) {
        runWithLocationContext(result) {
            val location = locationClient.lastLocation()
            if (location != null) {
                result.sendResponse(Response.success(LocationData.from(location)))
            } else {
                result.sendResponse(Response.failure(Response.Error.Type.LocationNotFound))
            }
        }
    }

    private fun currentLocation(param: Param.SingleLocationParam, result: Result) {
        runWithLocationContext(result) {
            val locationAvailability = locationClient.locationAvailability()

            val location = if (locationAvailability.isLocationAvailable) {
                locationClient.lastLocation()
            } else {
                null
            }

            if (location != null) {
                result.sendResponse(Response.success(LocationData.from(location)))
            } else {
                val locationFromUpdate = locationClient.singleLocationUpdate(Priority.toAndroidValue(param.accuracy.android))
                if (locationFromUpdate != null) {
                    result.sendResponse(Response.success(LocationData.from(locationFromUpdate)))
                } else {
                    result.sendResponse(Response.failure(Response.Error.Type.LocationNotFound))
                }
            }
        }
    }

    private fun singleLocationUpdate(param: Param.SingleLocationParam, result: Result) {
        runWithLocationContext(result) {
            val location = locationClient.singleLocationUpdate(Priority.toAndroidValue(param.accuracy.android))
            if (location != null) {
                result.sendResponse(Response.success(LocationData.from(location)))
            } else {
                result.sendResponse(Response.failure(Response.Error.Type.LocationNotFound))
            }
        }
    }

    private fun runWithLocationContext(result: Result, isRecursive: Boolean = false, action: suspend () -> Unit) {
        val connectionResult = GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable(registrar.context())
        if (connectionResult != ConnectionResult.SUCCESS) {
            result.sendResponse(Response.failure(Response.Error.Type.PlayServicesUnavailable, playServices = Response.Error.PlayServices.fromConnectionResult(connectionResult)))
            return
        }

        if (!AndroidHelper.isLocationEnabled(registrar.context())) {
            result.sendResponse(Response.failure(Response.Error.Type.ServiceDisabled))
            return
        }

        if (!AndroidHelper.isLocationPermissionDefinedInManifest(registrar.context())) {
            result.sendResponse(Response.failure(Response.Error.Type.Runtime, message = "Missing location permission in AndroidManifest.xml. You need one of ACCESS_FINE_LOCATION or ACCESS_COARSE_LOCATION. See readme for details.", fatal = true))
            return
        }

        if (!AndroidHelper.hasLocationPermission(registrar.context())) {
            // avoid request permission loop
            if (isRecursive) {
                return
            }

            val delayedAction = DelayedResultAction<Unit, Unit>(result, { _ ->
                // run with location context again, in case some location settings changed
                // however avoid restarting permission request, just in case
                runWithLocationContext(result, isRecursive = true, action = action)
            }, { _ ->
                result.sendResponse(Response.failure(Response.Error.Type.PermissionDenied))
            })
            withLocationPermissionActions.add(delayedAction)

            ActivityCompat.requestPermissions(registrar.activity(), arrayOf(Manifest.permission.ACCESS_FINE_LOCATION), LocationPermissionRequestId)
            return
        }

        try {
            launch(UI) { action() }
        } catch (e: Exception) {
            result.sendRuntimeError(e)
        }
    }

    @SuppressLint("MissingPermission")
    private fun lastLocation(result: Result, callback: (Location?) -> Unit) {
        locationProviderClient.lastLocation
                .addFailureListener(result)
                .addOnSuccessListener { location: Location? ->
                    callback(location)
                }
    }

    private fun decodeSingleLocationParam(arguments: Any): Param.SingleLocationParam {
        return moshi.adapter(Param.SingleLocationParam::class.java).fromJson(arguments as String)!!
    }

    private fun <T> Task<T>.addFailureListener(result: Result) = addOnFailureListener {
        result.sendResponse(Response.failure(Response.Error.Type.Runtime, message = it.message
                ?: ""))
    }


    private fun Result.sendResponse(response: Response) {
        success(moshi.adapter(Response::class.java).toJson(response))
    }

    private fun Result.sendRuntimeError(error: Exception) {
        sendResponse(Response.failure(Response.Error.Type.Runtime, message = error.message
                ?: ""))
    }

    companion object {
        private const val LocationPermissionRequestId = 138978923

        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), "io.intheloup.geolocation")
            channel.setMethodCallHandler(GeolocationPlugin(registrar))
        }
    }

    class DelayedResultAction<in T, in E>(val result: Result,
                                          inline val successAction: (T?) -> Unit,
                                          inline val failureAction: (E?) -> Unit
    )
}
