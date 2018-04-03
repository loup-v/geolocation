//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

library geolocation;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

part 'channel/api.dart';
part 'channel/codec.dart';
part 'data/location.dart';
part 'data/location_result.dart';
part 'data/result.dart';
part 'facet_android/location.dart';
part 'facet_android/result.dart';
part 'facet_ios/location.dart';

/// Provides access to geolocation features of the underlying platform (Android or iOS).
class Geolocation {
  static final _Api _api = new _Api();

  /// Returns the most recent location currently available.
  /// It does not wait for the device to fetch a new location, and returns immediately the
  /// last cached location, if available.
  ///
  /// This method is appropriate to get a one shot current location on Android, but
  /// not so much on iOS. See [currentLocation] for a better way to get the current
  /// location on both platforms.
  ///
  /// On Android, it calls FusedLocationProviderClient.getLastLocation()
  /// See: https://developers.google.com/android/reference/com/google/android/gms/location/FusedLocationProviderClient#getLastLocation()
  ///
  /// On iOS, it calls CLLocationManager.location
  /// See: https://developer.apple.com/documentation/corelocation/cllocationmanager/1423687-location
  static Future<LocationResult> get lastKnownLocation async =>
      _api.lastKnownLocation();

  /// Returns the current location, using different mechanics on Android and iOS that are
  /// more appropriate for this purpose.
  ///
  /// On Android, it returns the last known location in case the location is available and still
  /// valid. Otherwise it requests a single location update with the provided [accuracy].
  ///
  /// On iOS, it requests a single location update with the provided [accuracy].
  ///
  /// For more info on how work single location update, see [singleLocationUpdate].
  static Future<LocationResult> currentLocation(
          LocationAccuracy accuracy) async =>
      _api.currentLocation(accuracy);

  /// Requests a single location update with the provided [accuracy].
  ///
  /// On Android, it calls FusedLocationProviderClient.requestLocationUpdates()
  /// See: https://developers.google.com/android/reference/com/google/android/gms/location/FusedLocationProviderClient#requestLocationUpdates(com.google.android.gms.location.LocationRequest,%20com.google.android.gms.location.LocationCallback,%20android.os.Looper)
  ///
  /// On iOS, it calls CLLocationManager.requestLocation()
  /// See: https://developer.apple.com/documentation/corelocation/cllocationmanager/1620548-requestlocation
  ///
  /// Request timeout is handled differently per platform.
  /// On Android, request will timeout with an error after 60 seconds.
  /// On iOS, request might timeout with an error after some time, or might return a less
  /// accurate location than requested.
  static Future<LocationResult> singleLocationUpdate(
          LocationAccuracy accuracy) async =>
      _api.singleLocationUpdate(accuracy);
}

class GeolocationException implements Exception {
  GeolocationException(this.message);

  final String message;

  @override
  String toString() {
    return 'Geolocation error: $message';
  }
}
