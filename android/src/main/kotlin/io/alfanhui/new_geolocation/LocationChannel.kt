//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

package io.alfanhui.new_geolocation

import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.alfanhui.new_geolocation.data.LocationUpdatesRequest
import io.alfanhui.new_geolocation.data.Permission
import io.alfanhui.new_geolocation.location.LocationClient
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch


class LocationChannel(private val locationClient: LocationClient) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    fun register(plugin: NewGeolocationPlugin) {
        val methodChannel = MethodChannel(plugin.registrar.messenger(), "new_geolocation/location")
        methodChannel.setMethodCallHandler(this)

        val eventChannel = EventChannel(plugin.registrar.messenger(), "new_geolocation/locationUpdates")
        eventChannel.setStreamHandler(this)
    }

    private fun isLocationOperational(permission: Permission, result: MethodChannel.Result) {
        result.success(Codec.encodeResult(locationClient.isLocationOperational(permission)))
    }

    private fun requestLocationPermission(permission: Permission, result: MethodChannel.Result) {
        GlobalScope.launch(Dispatchers.Main) {
            result.success(Codec.encodeResult(locationClient.requestLocationPermission(permission)))
        }
    }

    private fun enableLocationSettings(result: MethodChannel.Result) {
        GlobalScope.launch(Dispatchers.Main) {
            result.success(Codec.encodeResult(locationClient.enableLocationServices()))
        }
    }

    private fun lastKnownLocation(permission: Permission, result: MethodChannel.Result) {
        GlobalScope.launch(Dispatchers.Main) {
            result.success(Codec.encodeResult(locationClient.lastKnownLocation(permission)))
        }
    }

    private fun addLocationUpdatesRequest(request: LocationUpdatesRequest) {
        GlobalScope.launch(Dispatchers.Main) {
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
