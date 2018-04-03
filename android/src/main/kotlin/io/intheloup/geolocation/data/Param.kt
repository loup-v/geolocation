//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

package io.intheloup.geolocation.data

object Param {

    data class SingleLocationParam(val accuracy: Facet) {
        class Facet(val android: String)
    }
}