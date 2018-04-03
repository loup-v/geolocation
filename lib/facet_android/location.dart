//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

part of geolocation;

/// Android specific values for [LocationAccuracy]
/// For description of each value, see: https://developers.google.com/android/reference/com/google/android/gms/location/LocationRequest.html#PRIORITY_BALANCED_POWER_ACCURACY
enum GeolocationAndroidPriority { low, balanced, high }
