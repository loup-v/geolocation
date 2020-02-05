//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

part of geolocation;

/// Contains the result from a binary (success or failed) request.
///
/// [isSuccessful] means the request was successful.
/// Otherwise, [error] will contain more details.
///
/// See also:
///
///  * [GeolocationResultError], which contains details on why/what failed.
class GeolocationResult {
  GeolocationResult._(
    this.isSuccessful,
    this.error,
  ) {
    assert(isSuccessful != null);
    assert(isSuccessful || error != null);
  }

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
  GeolocationResultError._(
    this.type,
    this.message,
    this.additionalInfo,
  );

  final GeolocationResultErrorType type;
  final String message;
  final dynamic additionalInfo;

  @override
  String toString() {
    switch (type) {
      case GeolocationResultErrorType.locationNotFound:
        return 'location not found';
      case GeolocationResultErrorType.permissionNotGranted:
        return 'permission not granted';
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
  permissionNotGranted,
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
    case 'permissionNotGranted':
      return GeolocationResultErrorType.permissionNotGranted;
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
