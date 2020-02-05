//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

package app.loup.geolocation.data

import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class PermissionRequest(val value: Permission,
                             val openSettingsIfDenied: Boolean)