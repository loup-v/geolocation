//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

part of geolocation;

class _Json {
  static GeolocationResult resultFromJson(Map<String, dynamic> json) =>
      new GeolocationResult._(
        json['isSuccessful'],
        json['error'] != null ? resultErrorFromJson(json['error']) : null,
      );

  static GeolocationResultError resultErrorFromJson(Map<String, dynamic> json) {
    final GeolocationResultErrorType type =
        _Json._resultErrorTypeFromJson(json['type']);

    var additionalInfo;
    switch (type) {
      case GeolocationResultErrorType.permissionDenied:
        additionalInfo = _mapPlayServicesJson(json['playServices']);//TODO
        break;
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

  static GeolocationResultErrorType _resultErrorTypeFromJson(String jsonValue) {
    switch (jsonValue) {
      case 'runtime':
        return GeolocationResultErrorType.runtime;
      case 'locationNotFound':
        return GeolocationResultErrorType.locationNotFound;
      case 'permissionDenied':
        return GeolocationResultErrorType.permissionDenied;
      case 'serviceDisabled':
        return GeolocationResultErrorType.serviceDisabled;
      case 'playServicesUnavailable':
        return GeolocationResultErrorType.playServicesUnavailable;
      default:
        assert(false,
            'cannot parse json to GeolocationResultErrorType: $jsonValue');
        return null;
    }
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
}
