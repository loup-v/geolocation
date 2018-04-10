//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

part of geolocation;

class LocationResult extends GeolocationResult {
  LocationResult._(
      bool isSuccessful, GeolocationResultError error, this.locations)
      : super._(isSuccessful, error);

  /// In context of location updates, result might contain more than one location: all
  /// locations retrieved by the device since the previous result.
  /// Locations are ordered from oldest to newest.
  /// Locations are guaranteed to contain at least one location.
  final List<Location> locations;

  /// Convenience to get the newest single location
  Location get location => locations.last;

  @override
  String dataToString() {
    return location.toString();
  }
}
