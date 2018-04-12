//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

package io.intheloup.geolocation

import com.squareup.moshi.Moshi
import io.intheloup.geolocation.data.LocationUpdatesRequest
import io.intheloup.geolocation.data.Permission
import io.intheloup.geolocation.data.Priority
import io.intheloup.geolocation.data.Result

object Codec {

    private val moshi: Moshi = Moshi.Builder()
            .add(Permission.Adapter())
            .add(Priority.Adapter())
            .add(LocationUpdatesRequest.Strategy.Adapter())
            .build()

    fun encodeResult(result: Result): String =
            moshi.adapter(Result::class.java).toJson(result)

    fun decodePermission(arguments: Any?): Permission =
            Permission.Adapter().fromJson(arguments!! as String)

    fun decodeLocationUpdatesRequest(arguments: Any?): LocationUpdatesRequest =
            moshi.adapter(LocationUpdatesRequest::class.java).fromJson(arguments!! as String)!!

}
