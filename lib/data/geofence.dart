part of geolocation;

class GeoFence {
  Location center;
  double radius;
  String identifier;

  GeoFence(double centerLatitude, double centerLongitude, double centerAltitude, double radius, String identifier) {
    this.center = new Location._(centerLatitude, 
      centerLongitude, 
      centerAltitude,);
    this.radius = radius;
    this.identifier = identifier;
  }

  @override
  String toString() {
    return '{lat: $center.latitude, lng: $center.longitude, radius: $radius, identifier: $identifier}';
  }
}