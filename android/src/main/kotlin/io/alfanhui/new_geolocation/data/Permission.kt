//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

package io.alfanhui.new_geolocation.data

import android.Manifest
import com.squareup.moshi.FromJson
import com.squareup.moshi.ToJson

enum class Permission {
    Coarse, Fine;

    val manifestValue get() = when(this) {
        Fine -> Manifest.permission.ACCESS_FINE_LOCATION
        Coarse -> Manifest.permission.ACCESS_COARSE_LOCATION
    }

    class Adapter {
        @FromJson
        fun fromJson(json: String): Permission =
                Permission.valueOf(json.capitalize())

        @ToJson
        fun toJson(value: Permission): String =
                value.toString().toLowerCase()
    }
}