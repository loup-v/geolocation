//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

package io.intheloup.geolocation

import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
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

    private fun lastKnownLocation(result: MethodChannel.Result) {
        launch(UI) {
            Codec.encodeResult(locationClient.lastKnownLocation())
        }
    }


    // MethodChannel.MethodCallHandler

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "lastKnownLocation" -> lastKnownLocation(result)
//            "currentLocation" -> currentLocation(decodeSingleLocationParam(call.arguments), result)
//            "singleLocationUpdate" -> singleLocationUpdate(decodeSingleLocationParam(call.arguments), result)
            else -> result.notImplemented()
        }
    }


    // EventChannel.StreamHandler

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {

    }

    override fun onCancel(arguments: Any?) {

    }
}