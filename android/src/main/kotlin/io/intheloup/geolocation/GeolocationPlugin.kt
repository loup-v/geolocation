//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

package io.intheloup.geolocation

import com.google.android.gms.tasks.Task
import com.squareup.moshi.Moshi
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.PluginRegistry.Registrar
import io.intheloup.geolocation.data.Param
import io.intheloup.geolocation.data.Result
import io.intheloup.geolocation.location.LocationClient
import kotlinx.coroutines.experimental.android.UI
import kotlinx.coroutines.experimental.launch

class GeolocationPlugin(private val registrar: Registrar) : MethodCallHandler {

    private val locationClient = LocationClient(registrar.activity())
    private val moshi = Moshi.Builder().build()

    init {
        registrar.addRequestPermissionsResultListener(locationClient.permissionResultListener)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "lastKnownLocation" -> lastKnownLocation(result)
//            "currentLocation" -> currentLocation(decodeSingleLocationParam(call.arguments), result)
//            "singleLocationUpdate" -> singleLocationUpdate(decodeSingleLocationParam(call.arguments), result)
            else -> result.notImplemented()
        }
    }

    private fun lastKnownLocation(result: MethodChannel.Result) {
        launch(UI) {
            result.sendResponse(locationClient.lastKnownLocation())
        }
    }

//    private fun currentLocation(param: Param.SingleLocationParam, result: Result) {
//        runWithLocationContext(result) {
//            val locationAvailability = locationClient.locationAvailability()
//
//            val location = if (locationAvailability.isLocationAvailable) {
//                locationClient.lastLocation()
//            } else {
//                null
//            }
//
//            if (location != null) {
//                result.sendResponse(Result.success(LocationData.from(location)))
//            } else {
//                val locationFromUpdate = locationClient.singleLocationUpdate(Priority.toAndroidValue(param.accuracy.android))
//                if (locationFromUpdate != null) {
//                    result.sendResponse(Result.success(LocationData.from(locationFromUpdate)))
//                } else {
//                    result.sendResponse(Result.failure(Result.Error.Type.LocationNotFound))
//                }
//            }
//        }
//    }
//
//    private fun singleLocationUpdate(param: Param.SingleLocationParam, result: Result) {
//        runWithLocationContext(result) {
//            val location = locationClient.singleLocationUpdate(Priority.toAndroidValue(param.accuracy.android))
//            if (location != null) {
//                result.sendResponse(Result.success(LocationData.from(location)))
//            } else {
//                result.sendResponse(Result.failure(Result.Error.Type.LocationNotFound))
//            }
//        }
//    }

//    private fun runWithLocationContext(result: Result, isRecursive: Boolean = false, action: suspend () -> Unit) {
//        val connectionResult = GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable(registrar.context())
//        if (connectionResult != ConnectionResult.SUCCESS) {
//            result.sendResponse(Result.failure(Result.Error.Type.PlayServicesUnavailable, playServices = Result.Error.PlayServices.fromConnectionResult(connectionResult)))
//            return
//        }
//
//        if (!AndroidHelper.isLocationEnabled(registrar.context())) {
//            result.sendResponse(Result.failure(Result.Error.Type.ServiceDisabled))
//            return
//        }
//
//        if (!AndroidHelper.isLocationPermissionDefinedInManifest(registrar.context())) {
//            result.sendResponse(Result.failure(Result.Error.Type.Runtime, message = "Missing location permission in AndroidManifest.xml. You need one of ACCESS_FINE_LOCATION or ACCESS_COARSE_LOCATION. See readme for details.", fatal = true))
//            return
//        }
//
//        if (!AndroidHelper.hasLocationPermission(registrar.context())) {
//            // avoid request permission loop
//            if (isRecursive) {
//                return
//            }
//
//            val delayedAction = DelayedResultAction<Unit, Unit>(result, { _ ->
//                // run with location context again, in case some location settings changed
//                // however avoid restarting permission request, just in case
//                runWithLocationContext(result, isRecursive = true, action = action)
//            }, { _ ->
//                result.sendResponse(Result.failure(Result.Error.Type.PermissionDenied))
//            })
//            withLocationPermissionActions.add(delayedAction)
//
//            ActivityCompat.requestPermissions(registrar.activity(), arrayOf(Manifest.permission.ACCESS_FINE_LOCATION), LocationPermissionRequestId)
//            return
//        }
//
//        try {
//            launch(UI) { action() }
//        } catch (e: Exception) {
//            result.sendRuntimeError(e)
//        }
//    }
//
//    @SuppressLint("MissingPermission")
//    private fun lastLocation(result: Result, callback: (Location?) -> Unit) {
//        locationProviderClient.lastLocation
//                .addFailureListener(result)
//                .addOnSuccessListener { location: Location? ->
//                    callback(location)
//                }
//    }

    private fun decodeSingleLocationParam(arguments: Any): Param.SingleLocationParam {
        return moshi.adapter(Param.SingleLocationParam::class.java).fromJson(arguments as String)!!
    }

    private fun <T> Task<T>.addFailureListener(result: MethodChannel.Result) = addOnFailureListener {
        result.sendResponse(Result.failure(Result.Error.Type.Runtime, message = it.message
                ?: ""))
    }


    private fun MethodChannel.Result.sendResponse(result: io.intheloup.geolocation.data.Result) {
        success(moshi.adapter(Result::class.java).toJson(result))
    }

    private fun MethodChannel.Result.sendRuntimeError(error: Exception) {
        sendResponse(Result.failure(Result.Error.Type.Runtime, message = error.message
                ?: ""))
    }

    companion object {

        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), "io.intheloup.geolocation")
            channel.setMethodCallHandler(GeolocationPlugin(registrar))
        }
    }

    object Intents {
        const val LocationPermissionRequestId = 138978923
    }
}
