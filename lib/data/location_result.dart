//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

part of geolocation;

/// Contains the result from a location request.
///
/// [isSuccessful] means a location was retrieved and [locations] is guaranteed to contain at least one [Location].
/// Otherwise, [error] will contain more details.
///
/// See also:
///
///  * [GeolocationResultError], which contains details on why/what failed.
class LocationResult extends GeolocationResult {
  LocationResult._(
      bool isSuccessful, GeolocationResultError error, this.locations)
      : super._(isSuccessful, error);

  /// Location updates might return more than one location at once. It contains
  /// all the locations that were retrieved by the device since the previous result.
  /// Locations are ordered from oldest to newest.
  /// If [isSuccessful] is `true`, [locations] is guaranteed to contain at least one [Location].
  final List<Location> locations;

  /// Most up-to-date location.
  /// If [isSuccessful] is `true`, [location] is guaranteed to contain a [Location].
  Location get location => locations.last;

  @override
  String dataToString() {
    return location.toString();
  }
}
