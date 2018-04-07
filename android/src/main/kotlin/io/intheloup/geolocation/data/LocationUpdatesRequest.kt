//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

package io.intheloup.geolocation.data

import com.squareup.moshi.FromJson
import com.squareup.moshi.ToJson


class LocationUpdatesRequest(val id: Int, val strategy: Strategy, facet: Facet) {

    class Facet(val android: Priority)

    enum class Strategy {
        Current, Single, Continuous;

        class Adapter {
            @FromJson
            fun fromJson(json: String): Strategy =
                    valueOf(json.capitalize())

            @ToJson
            fun toJson(value: Strategy): String =
                    value.toString().toLowerCase()
        }
    }
}