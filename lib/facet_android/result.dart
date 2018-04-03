//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

part of geolocation;

enum GeolocationAndroidPlayServices {
  missing,
  updating,
  versionUpdateRequired,
  disabled,
  invalid,
}

GeolocationAndroidPlayServices _mapPlayServicesJson(String jsonValue) {
  switch (jsonValue) {
    case 'missing':
      return GeolocationAndroidPlayServices.missing;
    case 'updating':
      return GeolocationAndroidPlayServices.updating;
    case 'versionUpdateRequired':
      return GeolocationAndroidPlayServices.versionUpdateRequired;
    case 'disabled':
      return GeolocationAndroidPlayServices.disabled;
    case 'invalid':
      return GeolocationAndroidPlayServices.invalid;
    default:
      assert(false,
          'cannot parse json to GeolocationAndroidPlayServices: $jsonValue');
      return null;
  }
}
