//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

part of geolocation;

/// Necessarily permission to work with location service on Android and iOS.
///
/// See also:
///
///  * Android permissions description: <https://developer.android.com/training/location/retrieve-current.html#permissions>
///  * iOS permissions description: <https://developer.apple.com/documentation/corelocation/choosing_the_authorization_level_for_location_services>
class LocationPermission {
  const LocationPermission({
    this.android = LocationPermissionAndroid.fine,
    this.ios = LocationPermissionIOS.whenInUse,
  });

  final LocationPermissionAndroid android;
  final LocationPermissionIOS ios;
}
