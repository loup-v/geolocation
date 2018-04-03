//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

part of geolocation;

abstract class GeolocationResult {
  GeolocationResult._({
    @required this.isSuccessful,
    this.error,
  }) {
    assert(isSuccessful != null);
    assert(isSuccessful || error != null);
  }

  GeolocationResult._fromJson(Map<String, dynamic> json)
      : isSuccessful = json['isSuccessful'],
        error = json['error'] != null
            ? GeolocationResultError._fromJson(json['error'])
            : null;

  final bool isSuccessful;
  final GeolocationResultError error;

  String dataToString() {
    return "without additional data";
  }

  @override
  String toString() {
    if (isSuccessful) {
      return '{success: ${dataToString()} }';
    } else {
      return '{failure: $error }';
    }
  }
}

class GeolocationResultError {
  GeolocationResultError({
    @required this.type,
    this.message,
    this.additionalInfo,
  });

  final GeolocationResultErrorType type;
  final String message;
  final dynamic additionalInfo;

  GeolocationResultError._fromJson(Map<String, dynamic> json)
      : type = _mapResultErrorTypeJson(json['type']),
        message = json['message'],
        additionalInfo = GeolocationResultError._mapAdditionalInfoJson(json) {
    if (json['fatal']) {
      throw GeolocationException(message);
    }
  }

  static dynamic _mapAdditionalInfoJson(Map<String, dynamic> json) {
    final GeolocationResultErrorType type =
        _mapResultErrorTypeJson(json['type']);
    switch (type) {
      case GeolocationResultErrorType.playServicesUnavailable:
        return _mapPlayServicesJson(json['playServices']);
      default:
        return null;
    }
  }

  @override
  String toString() {
    switch (type) {
      case GeolocationResultErrorType.locationNotFound:
        return 'location not found';
      case GeolocationResultErrorType.permissionDenied:
        return 'permission denied';
      case GeolocationResultErrorType.serviceDisabled:
        return 'service disabled';
      case GeolocationResultErrorType.playServicesUnavailable:
        return 'play services -> $additionalInfo';
      default:
        assert(false);
        return null;
    }
  }
}

enum GeolocationResultErrorType {
  runtime,
  locationNotFound,
  permissionDenied,
  serviceDisabled,
  playServicesUnavailable,
}

GeolocationResultErrorType _mapResultErrorTypeJson(String jsonValue) {
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
      assert(
          false, 'cannot parse json to GeolocationResultErrorType: $jsonValue');
      return null;
  }
}
