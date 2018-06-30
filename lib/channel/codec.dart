//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

part of geolocation;

class _Codec {
  static GeolocationResult decodeResult(String data) =>
      _JsonCodec.resultFromJson(json.decode(data));

  static LocationResult decodeLocationResult(String data) =>
      _JsonCodec.locationResultFromJson(json.decode(data));

  static GeofenceEventResult decodeGeofenceEventResult(String data) =>
      _JsonCodec.geofenceEventResultFromJson(json.decode(data));

  static String encodeGeofenceRegion(GeofenceRegion geofenceRegion) =>
      json.encode(_JsonCodec.geofenceRegionToJson(geofenceRegion));

  static GeofenceRegion decodeGeofenceRegion(String data) =>
      _JsonCodec.geofenceRegionFromJson(json.decode(data));

  static List<GeofenceRegion> decodeGeofenceRegions(String data) {
    final List<dynamic> elements = json.decode(data);
    return elements
        .map((element) => _JsonCodec.geofenceRegionFromJson(element))
        .toList();
  }

  static String encodeLocationPermission(LocationPermission permission) =>
      platformSpecific(
        android: _Codec.encodeEnum(permission.android),
        ios: _Codec.encodeEnum(permission.ios),
      );

  static String encodeLocationUpdatesRequest(_LocationUpdatesRequest request) =>
      json.encode(_JsonCodec.locationUpdatesRequestToJson(request));

  // see: https://stackoverflow.com/questions/49611724/dart-how-to-json-decode-0-as-double
  static double parseJsonNumber(dynamic value) {
    return value.runtimeType == int ? (value as int).toDouble() : value;
  }

  static String encodeEnum(dynamic value) {
    return value.toString().split('.').last;
  }

  static T decodeEnum<T>(String data, List<T> possibleValues) {
    return possibleValues.firstWhere((v) => describeEnum(v) == data);
  }

  static String platformSpecific({
    @required String android,
    @required String ios,
  }) {
    if (Platform.isAndroid) {
      return android;
    } else if (Platform.isIOS) {
      return ios;
    } else {
      throw new GeolocationException(
          'Unsupported platform: ${Platform.operatingSystem}');
    }
  }
}

class _JsonCodec {
  static GeolocationResult resultFromJson(Map<String, dynamic> json) =>
      new GeolocationResult._(
        json['isSuccessful'],
        json['error'] != null ? resultErrorFromJson(json['error']) : null,
      );

  static GeolocationResultError resultErrorFromJson(Map<String, dynamic> json) {
    final GeolocationResultErrorType type =
        _mapResultErrorTypeJson(json['type']);

    var additionalInfo;
    switch (type) {
      case GeolocationResultErrorType.playServicesUnavailable:
        additionalInfo = _mapPlayServicesJson(json['playServices']);
        break;
      default:
        additionalInfo = null;
    }

    final GeolocationResultError error = new GeolocationResultError._(
      type,
      json['message'],
      additionalInfo,
    );

    if (json.containsKey('fatal') && json['fatal']) {
      throw new GeolocationException(error.message);
    }

    return error;
  }

  static LocationResult locationResultFromJson(Map<String, dynamic> json) =>
      new LocationResult._(
        json['isSuccessful'],
        json['error'] != null ? resultErrorFromJson(json['error']) : null,
        json['data'] != null
            ? (json['data'] as List<dynamic>)
                .map((it) => locationFromJson(it as Map<String, dynamic>))
                .toList()
            : null,
      );

  static Location locationFromJson(Map<String, dynamic> json) => new Location(
        latitude: _Codec.parseJsonNumber(json['latitude']),
        longitude: _Codec.parseJsonNumber(json['longitude']),
        altitude: _Codec.parseJsonNumber(json['altitude']),
      );

  static Map<String, dynamic> geofenceRegionToJson(
          GeofenceRegion geofenceRegion) =>
      {
        'id': geofenceRegion.id,
        'region': regionToJson(geofenceRegion.region),
        'notifyOnEntry': geofenceRegion.notifyOnEntry,
        'notifyOnExit': geofenceRegion.notifyOnExit,
      };

  static Map<String, dynamic> locationUpdatesRequestToJson(
          _LocationUpdatesRequest request) =>
      {
        'id': request.id,
        'strategy': _Codec.encodeEnum(request.strategy),
        'permission': _Codec.encodeLocationPermission(request.permission),
        'accuracy': _Codec.platformSpecific(
          android: _Codec.encodeEnum(request.accuracy.android),
          ios: _Codec.encodeEnum(request.accuracy.ios),
        ),
        'displacementFilter': request.displacementFilter,
        'inBackground': request.inBackground,
        'options': _Codec.platformSpecific(
          android: _Codec.encodeEnum(request.androidOptions),
          ios: _Codec.encodeEnum(request.accuracy.ios),
        ),
      };

  static Map<String, dynamic> regionToJson(Region region) => {
        'radius': region.radius,
        'center': locationToJson(region.center),
      };

  static Map<String, dynamic> locationToJson(Location location) => {
        'latitude': location.latitude,
        'longitude': location.longitude,
        'altitude': location.altitude
      };

  static GeofenceEventResult geofenceEventResultFromJson(
          Map<String, dynamic> json) =>
      new GeofenceEventResult._(
          json['isSuccessful'],
          json['error'] != null ? resultErrorFromJson(json['error']) : null,
          json['data'] != null ? geofenceEventFromJson(json['data']) : null);

  static GeofenceEvent geofenceEventFromJson(Map<String, dynamic> json) =>
      new GeofenceEvent._(
          _Codec.decodeEnum(json['type'], GeofenceEventType.values),
          _JsonCodec.geofenceRegionFromJson(json['geofenceRegion']));

  static GeofenceRegion geofenceRegionFromJson(Map<String, dynamic> json) =>
      new GeofenceRegion(
        region: _JsonCodec.regionFromJson(json['region']),
        id: json['id'],
        notifyOnEntry: json['notifyOnEntry'],
        notifyOnExit: json['notifyOnExit'],
      );

  static Region regionFromJson(Map<String, dynamic> json) => new Region(
      center: _JsonCodec.locationFromJson(json['center']),
      radius: _Codec.parseJsonNumber(json['radius']));
}
