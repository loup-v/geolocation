//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

package app.loup.geolocation

import app.loup.geolocation.data.LocationUpdatesRequest
import app.loup.geolocation.data.Permission
import app.loup.geolocation.data.PermissionRequest
import app.loup.geolocation.location.LocationClient
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch


class Handler(private val locationClient: LocationClient) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {


  private fun isLocationOperational(permission: Permission, result: MethodChannel.Result) {
    result.success(Codec.encodeResult(locationClient.isLocationOperational(permission)))
  }

  private fun requestLocationPermission(permission: PermissionRequest, result: MethodChannel.Result) {
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
      "requestLocationPermission" -> requestLocationPermission(Codec.decodePermissionRequest(call.arguments), result)
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
