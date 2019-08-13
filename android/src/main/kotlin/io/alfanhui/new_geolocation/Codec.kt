//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

package io.alfanhui.new_geolocation

import com.squareup.moshi.Moshi
import io.alfanhui.new_geolocation.data.LocationUpdatesRequest
import io.alfanhui.new_geolocation.data.Permission
import io.alfanhui.new_geolocation.data.Priority
import io.alfanhui.new_geolocation.data.Result

object Codec {

    private val moshi: Moshi = Moshi.Builder()
            .add(Permission.Adapter())
            .add(Priority.Adapter())
            .add(LocationUpdatesRequest.Strategy.Adapter())
            .build()

    fun encodeResult(result: Result): String =
            moshi.adapter(Result::class.java).toJson(result)

    fun decodeInt(arguments: Any?): Int =
            arguments!! as Int

    fun decodePermission(arguments: Any?): Permission =
            Permission.Adapter().fromJson(arguments!! as String)

    fun decodeLocationUpdatesRequest(arguments: Any?): LocationUpdatesRequest =
            moshi.adapter(LocationUpdatesRequest::class.java).fromJson(arguments!! as String)!!

}
