//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

part of geolocation;

/// Android values for [LocationAccuracy].
///
/// Documentation: <https://developers.google.com/android/reference/com/google/android/gms/location/LocationRequest.html#PRIORITY_BALANCED_POWER_ACCURACY>
enum LocationPriorityAndroid { noPower, low, balanced, high }

/// Android specific options for location request.
///
/// Documentation: <https://developers.google.com/android/reference/com/google/android/gms/location/LocationRequest.html>
class LocationOptionsAndroid {
  const LocationOptionsAndroid({
    this.interval,
    this.fastestInterval,
    this.expirationTime,
    this.expirationDuration,
    this.maxWaitTime,
    this.numUpdates,
  });

  /// Default options for single (one-shot) location request
  static const LocationOptionsAndroid defaultSingle =
      const LocationOptionsAndroid(
    interval: 5000,
    fastestInterval: 2500,
    expirationDuration: 30000,
  );

  /// Default options for continuous location request
  static const LocationOptionsAndroid defaultContinuous =
      const LocationOptionsAndroid(
    interval: 5000,
    fastestInterval: 2500,
  );

  final int interval;
  final int fastestInterval;
  final int expirationTime;
  final int expirationDuration;
  final int maxWaitTime;

  /// Always `1` in single location request
  final int numUpdates;

  Map toJson() => {
        'interval': interval,
        'fastestInterval': fastestInterval,
        'expirationTime': expirationTime,
        'expirationDuration': expirationDuration,
        'maxWaitTime': maxWaitTime,
        'numUpdates': numUpdates
      };
}
