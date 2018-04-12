//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

part of geolocation;

class _Codec {
  static GeolocationResult decodeResult(String data) =>
      _JsonCodec.resultFromJson(json.decode(data));

  static LocationResult decodeLocationResult(String data) =>
      _JsonCodec.locationResultFromJson(json.decode(data));

  static String encodeLocationPermission(LocationPermission permission) =>
      platformSpecific(
        _Codec.encodeEnum(permission.android),
        _Codec.encodeEnum(permission.ios),
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

  static String platformSpecific(String android, String ios) {
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

  static Location locationFromJson(Map<String, dynamic> json) => new Location._(
        _Codec.parseJsonNumber(json['latitude']),
        _Codec.parseJsonNumber(json['longitude']),
        _Codec.parseJsonNumber(json['altitude']),
      );

  static Map<String, dynamic> locationUpdatesRequestToJson(
          _LocationUpdatesRequest request) =>
      {
        'id': request.id,
        'strategy': _Codec.encodeEnum(request.strategy),
        'permission': _Codec.encodeLocationPermission(request.permission),
        'accuracy': _Codec.platformSpecific(
          _Codec.encodeEnum(request.accuracy.android),
          _Codec.encodeEnum(request.accuracy.ios),
        ),
        'displacementFilter': request.displacementFilter,
        'inBackground': request.inBackground,
      };


}
