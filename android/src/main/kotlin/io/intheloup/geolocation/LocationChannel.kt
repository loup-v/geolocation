//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

package io.intheloup.geolocation

import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.intheloup.geolocation.data.LocationUpdatesRequest
import io.intheloup.geolocation.data.Permission
import io.intheloup.geolocation.location.LocationClient
import kotlinx.coroutines.experimental.android.UI
import kotlinx.coroutines.experimental.launch

class LocationChannel(private val locationClient: LocationClient) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    fun register(plugin: GeolocationPlugin) {
        val methodChannel = MethodChannel(plugin.registrar.messenger(), "geolocation/location")
        methodChannel.setMethodCallHandler(this)

        val eventChannel = EventChannel(plugin.registrar.messenger(), "geolocation/locationUpdates")
        eventChannel.setStreamHandler(this)
    }

    private fun isLocationOperational(permission: Permission, result: MethodChannel.Result) {
        result.success(Codec.encodeResult(locationClient.isLocationOperational(permission)))
    }

    private fun requestLocationPermission(permission: Permission, result: MethodChannel.Result) {
        launch(UI) {
            result.success(Codec.encodeResult(locationClient.requestLocationPermission(permission)))
        }
    }

    private fun enableLocationSettings(result: MethodChannel.Result) {
        launch(UI) {
            result.success(Codec.encodeResult(locationClient.enableLocationServices()))
        }
    }

    private fun lastKnownLocation(permission: Permission, result: MethodChannel.Result) {
        launch(UI) {
            result.success(Codec.encodeResult(locationClient.lastKnownLocation(permission)))
        }
    }

    private fun addLocationUpdatesRequest(request: LocationUpdatesRequest) {
        launch(UI) {
            locationClient.addLocationUpdatesRequest(request)
        }
    }

    private fun removeLocationUpdatesRequest(id: Int) {
        locationClient.removeLocationUpdatesRequest(id)
    }


    // MethodChannel.MethodCallHandler

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isLocationOperational" -> isLocationOperational(Codec.decodePermission(call.arguments), result)
            "requestLocationPermission" -> requestLocationPermission(Codec.decodePermission(call.arguments), result)
            "lastKnownLocation" -> lastKnownLocation(Codec.decodePermission(call.arguments), result)
            "addLocationUpdatesRequest" -> addLocationUpdatesRequest(Codec.decodeLocationUpdatesRequest(call.arguments))
            "removeLocationUpdatesRequest" -> removeLocationUpdatesRequest(Codec.decodeInt(call.arguments))
            "enableLocationServices" -> enableLocationSettings(result)
            else -> result.notImplemented()
        }
    }


    // EventChannel.StreamHandler

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        locationClient.registerLocationUpdatesCallback { result ->
            events.success(Codec.encodeResult(result))
        }
    }

    override fun onCancel(arguments: Any?) {
        locationClient.deregisterLocationUpdatesCallback()
    }
}
