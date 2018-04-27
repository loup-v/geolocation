//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

part of geolocation;

/// Contains the result from a geofence request.
/// [id] the identifier specified in the 
/// [didEnter] if true means the region specified in [geoFence] was entered, if false means it was exited.
class GeoFenceResult {

  GeoFenceResult._(
      this.id, this.didEnter, this.geoFence);

  final GeoFence geoFence;
  final int id;
  final bool didEnter;

  String dataToString() {
    return '{geofence: $geoFence.toString(), didEnter: $didEnter}';
  }
}
