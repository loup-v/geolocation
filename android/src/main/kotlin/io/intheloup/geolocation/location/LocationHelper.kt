package io.intheloup.geolocation.location

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import android.support.v4.content.ContextCompat

object LocationHelper {

    fun getLocationPermissionRequest(context: Context) : LocationPermissionRequest {
        val permissions = context.packageManager
                .getPackageInfo(context.packageName, PackageManager.GET_PERMISSIONS)
                .requestedPermissions

        return when {
            permissions.count {  it == Manifest.permission.ACCESS_FINE_LOCATION } > 0 -> LocationPermissionRequest.Fine
            permissions.count {  it == Manifest.permission.ACCESS_COARSE_LOCATION } > 0 -> LocationPermissionRequest.Coarse
            else -> LocationPermissionRequest.Undefined
        }
    }

    fun isLocationEnabled(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.KITKAT) {
            return true
        }

        val locationMode = try {
            Settings.Secure.getInt(context.contentResolver, Settings.Secure.LOCATION_MODE)
        } catch (e: Settings.SettingNotFoundException) {
            Settings.Secure.LOCATION_MODE_OFF
        }

        return locationMode != Settings.Secure.LOCATION_MODE_OFF
    }

    fun hasLocationPermission(context: Context) =
            ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
                    ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED

    enum class LocationPermissionRequest {
        Undefined, Coarse, Fine
    }
}