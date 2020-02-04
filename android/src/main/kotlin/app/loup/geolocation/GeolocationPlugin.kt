package app.loup.geolocation

import android.app.Activity
import android.app.Application
import android.content.Context
import android.os.Bundle
import androidx.annotation.NonNull;
import app.loup.geolocation.location.LocationClient
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

public class GeolocationPlugin(context: Context) : FlutterPlugin, ActivityAware, Application.ActivityLifecycleCallbacks {

  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      register(registrar.activeContext(), registrar.messenger())
    }

    private fun register(context: Context, binaryMessenger: BinaryMessenger) {
      val instance = GeolocationPlugin(context)
      val methodChannel = MethodChannel(binaryMessenger, "geolocation/location")
      val eventChannel = EventChannel(binaryMessenger, "geolocation/locationUpdates")

      methodChannel.setMethodCallHandler(instance.handler)
      eventChannel.setStreamHandler(instance.handler)
    }
  }

  private val locationClient = LocationClient(context)
  private val handler = Handler(locationClient)
  private var activityBinding: ActivityPluginBinding? = null

  private fun attachToActivity(binding: ActivityPluginBinding) {
    if (activityBinding != null) {
      detachFromActivity()
    }
    activityBinding = binding

    locationClient.activity = binding.activity

    binding.addRequestPermissionsResultListener(locationClient.permissionResultListener)
    binding.addActivityResultListener(locationClient.activityResultListener)
    binding.activity.application.registerActivityLifecycleCallbacks(this)
  }

  private fun detachFromActivity() {
    val binding = activityBinding ?: return

    locationClient.activity = null

    binding.removeRequestPermissionsResultListener(locationClient.permissionResultListener)
    binding.removeActivityResultListener(locationClient.activityResultListener)
    binding.activity.application.unregisterActivityLifecycleCallbacks(this)

    activityBinding = null
  }


  // FlutterPlugin

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    register(flutterPluginBinding.applicationContext, flutterPluginBinding.binaryMessenger)
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
  }


  // ActivityAware

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    attachToActivity(binding)
  }

  override fun onDetachedFromActivity() {
    detachFromActivity()
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    attachToActivity(binding)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    detachFromActivity()
  }


  // Application.ActivityLifecycleCallbacks

  override fun onActivityPaused(activity: Activity?) {
    locationClient.pause()
  }

  override fun onActivityResumed(activity: Activity?) {
    locationClient.resume()
  }

  override fun onActivityStarted(activity: Activity?) {

  }

  override fun onActivityDestroyed(activity: Activity?) {

  }

  override fun onActivitySaveInstanceState(activity: Activity?, outState: Bundle?) {

  }

  override fun onActivityStopped(activity: Activity?) {

  }

  override fun onActivityCreated(activity: Activity?, savedInstanceState: Bundle?) {

  }


  object Intents {
    const val LocationPermissionRequestId = 12234
    const val EnableLocationSettingsRequestId = 12237
  }
}
