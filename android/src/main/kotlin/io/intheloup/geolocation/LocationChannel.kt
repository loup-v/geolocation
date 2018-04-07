package io.intheloup.geolocation

import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class LocationChannel: MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {

    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {

    }

    override fun onCancel(arguments: Any?) {

    }
}