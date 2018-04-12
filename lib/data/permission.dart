//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

part of geolocation;

/// Necessarily permission to work with location service on Android and iOS.
///
/// See also:
///
///  * [LocationPermissionAndroid], to which this defers for Android.
///  * [LocationPermissionIOS], to which this defers for iOS.
class LocationPermission {
  const LocationPermission({
    this.android = LocationPermissionAndroid.fine,
    this.ios = LocationPermissionIOS.whenInUse,
  });

  final LocationPermissionAndroid android;
  final LocationPermissionIOS ios;
}
