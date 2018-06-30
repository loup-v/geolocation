//  Licensed under Apache License v2.0

part of geolocation;

/// Represents a circular region
class Region {
  Region({@required this.center, @required this.radius});

  /// Center of the circular region
  final Location center;

  /// Radius measured in meters.
  final double radius;

  @override
  String toString() {
    return '{center: $center, radius: $radius}';
  }
}

class GeofenceRegion {
  final Region region;
  final String id;
  final bool notifyOnEntry;
  final bool notifyOnExit;

  GeofenceRegion(
      {@required this.region,
      @required this.id,
      this.notifyOnEntry = true,
      this.notifyOnExit = false});

  @override
  String toString() {
    return '{region: $region, id: $id, notifyOnEntry: $notifyOnEntry, notifyOnExit: $notifyOnExit}';
  }
}

enum GeofenceEventType { entered, exited }

class GeofenceEvent {
  final GeofenceEventType type;
  final GeofenceRegion geofenceRegion;

  GeofenceEvent._(this.type, this.geofenceRegion);
}

class GeofenceEventResult extends GeolocationResult {
  GeofenceEventResult._(
      bool isSuccessful, GeolocationResultError error, this.geofenceEvent)
      : super._(isSuccessful, error);

  final GeofenceEvent geofenceEvent;

  @override
  String dataToString() {
    return geofenceEvent.toString();
  }
}
