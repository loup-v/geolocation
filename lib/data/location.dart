//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

part of geolocation;

/// Location data retrieved from the platform
class Location {
  Location._({this.latitude, this.longitude, this.altitude});

  Location._fromJson(Map<String, dynamic> json)
      : latitude = _Codec.parseJsonNumber(json['latitude']),
        longitude = _Codec.parseJsonNumber(json['longitude']),
        altitude = _Codec.parseJsonNumber(json['altitude']);

  /// Latitude in degrees
  final double latitude;

  /// Longitude in degrees
  final double longitude;

  /// Altitude measured in meters.
  final double altitude;

  @override
  String toString() {
    return '{lat: $latitude, lng: $longitude}';
  }
}

/// Desired accuracy for the next location request.
/// Accuracy works differently on Android and iOS, but this class tries to find common ground.
///
/// Lower accuracy location request use less battery, so be sure to always choose accuracy
/// that make sense for your usage.
///
/// Defers to [GeolocationAndroidPriority] for Android platform specifics.
/// See: https://developers.google.com/android/reference/com/google/android/gms/location/LocationRequest.html#PRIORITY_BALANCED_POWER_ACCURACY
///
/// Defers to [GeolocationIosAccuracy] for iOS platform specifics.
/// See: https://developer.apple.com/documentation/corelocation/cllocationaccuracy
class LocationAccuracy {
  /// In case the common ground constants are not satisfactory, you can build a custom [LocationAccuracy]
  /// using specific platform values.
  const LocationAccuracy({@required this.android, @required this.ios});

  final GeolocationAndroidPriority android;
  final GeolocationIosAccuracy ios;

  /// Low accuracy that can locate the device accurately to within several kilometers.
  static const LocationAccuracy city = const LocationAccuracy(
    android: GeolocationAndroidPriority.low,
    ios: GeolocationIosAccuracy.threeKilometers,
  );

  /// Balanced accuracy that can locate the device accurately to within hundred meters.
  static const LocationAccuracy block = const LocationAccuracy(
    android: GeolocationAndroidPriority.balanced,
    ios: GeolocationIosAccuracy.hundredMeters,
  );

  /// Highest accuracy that will generate the most precise device location, but also the most
  /// battery consuming.
  static const LocationAccuracy best = const LocationAccuracy(
    android: GeolocationAndroidPriority.high,
    ios: GeolocationIosAccuracy.bestForNavigation,
  );
}
