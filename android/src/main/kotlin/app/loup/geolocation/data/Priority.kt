//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

package app.loup.geolocation.data

import com.google.android.gms.location.LocationRequest
import com.squareup.moshi.FromJson
import com.squareup.moshi.ToJson

enum class Priority {
  NoPower, Low, Balanced, High;

  val androidValue
    get() = when (this) {
      NoPower -> LocationRequest.PRIORITY_NO_POWER
      Low -> LocationRequest.PRIORITY_LOW_POWER
      Balanced -> LocationRequest.PRIORITY_BALANCED_POWER_ACCURACY
      High -> LocationRequest.PRIORITY_HIGH_ACCURACY
    }

  class Adapter {
    @FromJson
    fun fromJson(json: String): Priority =
        Priority.valueOf(json.capitalize())

    @ToJson
    fun toJson(value: Priority): String =
        value.toString().toLowerCase()
  }
}