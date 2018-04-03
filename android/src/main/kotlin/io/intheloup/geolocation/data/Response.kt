//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

package io.intheloup.geolocation.data

import com.google.android.gms.common.ConnectionResult

data class Response(val isSuccessful: Boolean,
                    val data: Any? = null,
                    val error: Error? = null
) {
    companion object {
        fun success(data: Any) = Response(isSuccessful = true, data = data)

        fun failure(type: String, playServices: String? = null, message: String? = null, fatal: Boolean = false) = Response(
                isSuccessful = false,
                error = Response.Error(
                        type = type,
                        playServices = playServices,
                        message = message,
                        fatal = fatal
                )
        )
    }

    data class Error(val type: String,
                     val playServices: String?,
                     val message: String?,
                     val fatal: Boolean) {

        object Type {
            const val Runtime = "runtime"
            const val LocationNotFound = "locationNotFound"
            const val PermissionDenied = "permissionDenied"
            const val ServiceDisabled = "serviceDisabled"
            const val PlayServicesUnavailable = "playServicesUnavailable"
        }

        object PlayServices {
            const val Missing = "missing"
            const val Updating = "updating"
            const val VersionUpdateRequired = "versionUpdateRequired"
            const val Disabled = "disabled"
            const val Invalid = "invalid"

            fun fromConnectionResult(value: Int) = when (value) {
                ConnectionResult.SERVICE_MISSING -> Missing
                ConnectionResult.SERVICE_UPDATING -> Updating
                ConnectionResult.SERVICE_VERSION_UPDATE_REQUIRED -> VersionUpdateRequired
                ConnectionResult.SERVICE_DISABLED -> Disabled
                ConnectionResult.SERVICE_INVALID -> Invalid
                else -> throw IllegalStateException("unknown ConnectionResult: $value")
            }
        }
    }
}