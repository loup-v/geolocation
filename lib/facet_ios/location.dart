//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

part of geolocation;

/// iOS values for [LocationAccuracy].
///
/// Documentation: <https://developer.apple.com/documentation/corelocation/cllocationaccuracy>
enum LocationAccuracyIOS {
  threeKilometers,
  kilometer,
  hundredMeters,
  nearestTenMeters,
  best,
  bestForNavigation
}

/// iOS specific options for location request.
///
/// Documentation: <https://developer.apple.com/documentation/corelocation/cllocationmanager>
class LocationOptionsIOS {
  const LocationOptionsIOS({
    this.showsBackgroundLocationIndicator = false,
    this.activityType = LocationActivityIOS.other,
  });

  final bool showsBackgroundLocationIndicator;
  final LocationActivityIOS activityType;

  Map toJson() => {
        'showsBackgroundLocationIndicator': showsBackgroundLocationIndicator,
        'activityType': _Codec.encodeEnum(activityType)
      };

  toMap() => {
        'showsBackgroundLocationIndicator': showsBackgroundLocationIndicator,
        'activityType': activityType.toString().split('.').last
      };
}

enum LocationActivityIOS {
  other,
  automotiveNavigation,
  fitness,
  otherNavigation
}
