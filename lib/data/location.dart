//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

part of geolocation;

class Location {
  Location._(this.latitude, this.longitude, this.altitude, this.isMocked);

  /// Latitude in degrees
  final double latitude;

  /// Longitude in degrees
  final double longitude;

  /// Altitude measured in meters.
  final double altitude;

  final bool isMocked;

  @override
  String toString() {
    return '{lat: $latitude, lng: $longitude}';
  }
}

/// Desired accuracy for a location request.
/// Accuracy works differently on Android and iOS, but this class tries to find common ground.
///
/// Lower accuracy location request use less battery, so be sure to always choose accuracy
/// that make sense for your usage.
///
/// See also:
///
///  * [LocationPriorityAndroid], to which this defers for Android.
///  * [LocationAccuracyIOS], to which this defers for iOS.
class LocationAccuracy {
  /// In case the common ground constants are not satisfactory, you can build a custom [LocationAccuracy]
  /// using specific platform values.
  const LocationAccuracy({@required this.android, @required this.ios});

  final LocationPriorityAndroid android;
  final LocationAccuracyIOS ios;

  /// Low accuracy that can locate the device accurately to within several kilometers.
  static const LocationAccuracy city = const LocationAccuracy(
    android: LocationPriorityAndroid.low,
    ios: LocationAccuracyIOS.threeKilometers,
  );

  /// Balanced accuracy that can locate the device accurately to within hundred meters.
  static const LocationAccuracy block = const LocationAccuracy(
    android: LocationPriorityAndroid.balanced,
    ios: LocationAccuracyIOS.hundredMeters,
  );

  /// Highest accuracy that will generate the most precise device location, but also the most
  /// battery consuming.
  static const LocationAccuracy best = const LocationAccuracy(
    android: LocationPriorityAndroid.high,
    ios: LocationAccuracyIOS.bestForNavigation,
  );
}
