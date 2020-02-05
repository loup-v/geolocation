//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

package app.loup.geolocation.data

import com.squareup.moshi.FromJson
import com.squareup.moshi.JsonClass
import com.squareup.moshi.ToJson

@JsonClass(generateAdapter = true)
data class LocationUpdatesRequest(val id: Int,
                                  val strategy: Strategy,
                                  val permission: Permission,
                                  val accuracy: Priority,
                                  val inBackground: Boolean,
                                  val displacementFilter: Float,
                                  val options: Options) {


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

  @JsonClass(generateAdapter = true)
  data class Options(val interval: Long?,
                     val fastestInterval: Long?,
                     val expirationTime: Long?,
                     val expirationDuration: Long?,
                     val maxWaitTime: Long?,
                     val numUpdates: Int?)
}