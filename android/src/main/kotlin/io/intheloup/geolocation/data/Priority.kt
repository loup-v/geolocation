//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

package io.intheloup.geolocation.data

import com.google.android.gms.location.LocationRequest

object Priority {
    const val Low = "low"
    const val Balanced = "balanced"
    const val High = "high"

    fun toAndroidValue(value: String) = when (value) {
        Low -> LocationRequest.PRIORITY_LOW_POWER
        Balanced -> LocationRequest.PRIORITY_BALANCED_POWER_ACCURACY
        High -> LocationRequest.PRIORITY_HIGH_ACCURACY
        else -> throw IllegalStateException("unknown accuracy: $value")
    }
}