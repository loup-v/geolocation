//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

part of geolocation;

class LocationResult extends GeolocationResult {
  LocationResult._fromJson(Map<String, dynamic> json)
      : location =
            json['data'] != null ? Location._fromJson(json['data']) : null,
        super._fromJson(json);

  final Location location;

  @override
  String dataToString() {
    return location.toString();
  }
}
