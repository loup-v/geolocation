//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

package app.loup.geolocation.location

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import app.loup.geolocation.data.Permission
import com.google.android.gms.location.LocationRequest

object LocationHelper {

  fun isPermissionDeclared(context: Context, permission: Permission): Boolean {
    val permissions = context.packageManager
        .getPackageInfo(context.packageName, PackageManager.GET_PERMISSIONS)
        .requestedPermissions

    return permissions.any { it == permission.manifestValue }
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

  fun isPermissionDeclined(activity: Activity, permission: Permission) = ActivityCompat.shouldShowRequestPermissionRationale(activity, permission.manifestValue)

  /**
   * Android doesn't make any difference between coarse and fine for permission.
   */
  fun isPermissionGranted(context: Context) =
      ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
          ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED

  fun getBestPriority(p1: Int, p2: Int) = when {
    p1 == LocationRequest.PRIORITY_HIGH_ACCURACY -> p1
    p2 == LocationRequest.PRIORITY_HIGH_ACCURACY -> p2
    p1 == LocationRequest.PRIORITY_BALANCED_POWER_ACCURACY -> p1
    p2 == LocationRequest.PRIORITY_BALANCED_POWER_ACCURACY -> p2
    p1 == LocationRequest.PRIORITY_LOW_POWER -> p1
    p2 == LocationRequest.PRIORITY_LOW_POWER -> p2
    p1 == LocationRequest.PRIORITY_NO_POWER -> p1
    p2 == LocationRequest.PRIORITY_NO_POWER -> p2
    else -> throw IllegalArgumentException("Unknown priority: $p1 vs $p2")
  }
}