//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

part of geolocation;

class _Codec {
  static GeolocationResult decodeResult(String data) =>
      _JsonCodec.resultFromJson(json.decode(data));

  static LocationResult decodeLocationResult(String data) =>
      _JsonCodec.locationResultFromJson(json.decode(data));

  static String encodeLocationPermission(LocationPermission permission) =>
      _Codec.platformSpecific(
        android: _Codec.encodeEnum(permission.android),
        ios: _Codec.encodeEnum(permission.ios),
      );

  static String encodeLocationUpdatesRequest(_LocationUpdatesRequest request) =>
      json.encode(_JsonCodec.locationUpdatesRequestToJson(request));

  static String encodePermissionRequest(_PermissionRequest request) =>
      json.encode(_JsonCodec.permissionRequestToJson(request));

  // see: https://stackoverflow.com/questions/49611724/dart-how-to-json-decode-0-as-double
  static double parseJsonNumber(dynamic value) {
    return value.runtimeType == int ? (value as int).toDouble() : value;
  }

  static bool parseJsonBoolean(dynamic value) {
    return value.toString() == 'true';
  }

  static String encodeEnum(dynamic value) {
    return value.toString().split('.').last;
  }

  static dynamic platformSpecific({
    @required dynamic android,
    @required dynamic ios,
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

  static Map<String, dynamic> platformSpecificMap({
    @required Map<String, dynamic> android,
    @required Map<String, dynamic> ios,
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

  static Location locationFromJson(Map<String, dynamic> json) => new Location._(
        _Codec.parseJsonNumber(json['latitude']),
        _Codec.parseJsonNumber(json['longitude']),
        _Codec.parseJsonNumber(json['altitude']),
        _Codec.parseJsonBoolean(json['isMocked']),
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
          android: request.androidOptions,
          ios: request.iosOptions,
        ),
      };

  static Map<String, dynamic> permissionRequestToJson(
          _PermissionRequest request) =>
      {
        'value': _Codec.encodeLocationPermission(request.value),
        'openSettingsIfDenied': request.openSettingsIfDenied,
      };
}
