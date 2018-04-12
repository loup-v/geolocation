//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

part of geolocation;

/// iOS values for [LocationAccuracy]
/// See: <https://developer.apple.com/documentation/corelocation/cllocationaccuracy>
enum LocationAccuracyIOS {
  threeKilometers,
  kilometer,
  hundredMeters,
  nearestTenMeters,
  best,
  bestForNavigation
}
