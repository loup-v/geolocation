//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

package io.intheloup.geolocation

import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.intheloup.geolocation.data.LocationUpdatesRequest
import io.intheloup.geolocation.location.LocationClient
import kotlinx.coroutines.experimental.android.UI
import kotlinx.coroutines.experimental.launch

class LocationChannel(private val locationClient: LocationClient) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    fun register(plugin: GeolocationPlugin) {
        val methodChannel = MethodChannel(plugin.registrar.messenger(), "io.intheloup.geolocation/location")
        methodChannel.setMethodCallHandler(this)

        val eventChannel = EventChannel(plugin.registrar.messenger(), "io.intheloup.geolocation/locationUpdates")
        eventChannel.setStreamHandler(this)
    }

    private fun isLocationOperational(result: MethodChannel.Result) {
        launch(UI) {
            result.success(Codec.encodeResult(locationClient.isLocationOperational()))
        }
    }

    private fun requestLocationPermission(result: MethodChannel.Result) {
        launch(UI) {
            result.success(Codec.encodeResult(locationClient.requestLocationPermission()))
        }
    }

    private fun lastKnownLocation(result: MethodChannel.Result) {
        launch(UI) {
            result.success(Codec.encodeResult(locationClient.lastKnownLocation()))
        }
    }

    private fun addLocationUpdatesRequest(request: LocationUpdatesRequest) {
        locationClient.addLocationUpdatesRequest(request)
    }

    private fun removeLocationUpdatesRequest(request: LocationUpdatesRequest) {
        locationClient.removeLocationUpdatesRequest(request)
    }


    // MethodChannel.MethodCallHandler

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isLocationOperational" -> isLocationOperational(result)
            "requestLocationPermission" -> requestLocationPermission(result)
            "lastKnownLocation" -> lastKnownLocation(result)
            "addLocationUpdatesRequest" -> addLocationUpdatesRequest(Codec.decodeLocationUpdatesRequest(call.arguments))
            "removeLocationUpdatesRequest" -> removeLocationUpdatesRequest(Codec.decodeLocationUpdatesRequest(call.arguments))
            else -> result.notImplemented()
        }
    }


    // EventChannel.StreamHandler

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        locationClient.registerForLocationUpdates { result ->
            events.success(Codec.encodeResult(result))
        }
    }

    override fun onCancel(arguments: Any?) {
        locationClient.stopLocationUpdates()
    }
}