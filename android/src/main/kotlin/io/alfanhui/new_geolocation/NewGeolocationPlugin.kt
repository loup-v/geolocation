//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

package io.alfanhui.new_geolocation

import android.app.Activity
import android.app.Application
import android.os.Bundle
import io.flutter.plugin.common.PluginRegistry.Registrar
import io.alfanhui.new_geolocation.location.LocationClient

class NewGeolocationPlugin(val registrar: Registrar) {

    private val locationClient = LocationClient(registrar.activity())
    private val locationChannel = LocationChannel(locationClient)

    init {
        registrar.addRequestPermissionsResultListener(locationClient.permissionResultListener)
        registrar.addActivityResultListener(locationClient.activityResultListener);
        registrar.activity().application.registerActivityLifecycleCallbacks(object : Application.ActivityLifecycleCallbacks {
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
        })

        locationChannel.register(this)
    }

    companion object {

        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val plugin = NewGeolocationPlugin(registrar)
        }
    }

    object Intents {
        const val LocationPermissionRequestId = 12234
        const val EnableLocationSettingsRequestId = 12237
    }
}
