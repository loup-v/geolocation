//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

library geolocation;

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

part 'channel/codec.dart';
part 'channel/helper.dart';
part 'channel/location_channel.dart';
part 'channel/param.dart';
part 'data/location.dart';
part 'data/location_result.dart';
part 'data/result.dart';
part 'facet_android/location.dart';
part 'facet_android/result.dart';
part 'facet_ios/location.dart';

/// Provides access to geolocation features of the underlying platform (Android or iOS).
class Geolocation {
  /// Checks if location service is currently operational, meaning that it can be used to make
  /// location requests. Location is not operational if location service is disabled, restricted, or permission is not
  /// granted.
  ///
  /// Note that being operational does not mean that location request is guaranteed to succeed.
  /// Location request might still fail if device has no GPS coverage for instance. There is no way to know
  /// before making the location request.
  ///
  /// [GeolocationResult.isSuccessful] means location is operational.
  /// Otherwise, [GeolocationResult.error] will contain details on what's wrong.
  ///
  /// See also:
  /// * [GeolocationResultError]
  /// * [GeolocationResultErrorType]
  static Future<GeolocationResult> get isLocationOperational =>
      _locationChannel.isLocationOperational();

  /// On Android, it requests location permission.
  /// On iOS, it requests "when in use" or "always" location permission.
  /// The plugin will automatically request the appropriate permission based on the content of Infos.plist (iOS)
  ///
  /// In case permission declaration is missing from AndroidManifest.xml (android) or Infos.plist (iOS),
  /// the plugin will throw a [GeolocationException] at runtime.
  ///
  /// Location permission is automatically requested for every location-related operations,
  /// so you don't need to request permission manually. However it's common for apps to request
  /// location permission beforehand, like in an Onboarding flow for example.
  ///
  /// [GeolocationResult.isSuccessful] means permission is granted (or was already granted).
  /// Otherwise, [GeolocationResult.error] will contain details on what's wrong.
  /// Note that failure does not necessarily mean that user denied permission. It can also be that
  /// location service is not available or restricted (location not operational). In that case, permission request
  /// dialog was never showed to the user.
  ///
  /// See also:
  /// * [isLocationOperational]
  static Future<GeolocationResult> requestLocationPermission() =>
      _locationChannel.requestLocationPermission();

  /// Retrieves the most recent [Location] currently available.
  /// It does not wait for the device to fetch a new location, and returns immediately the
  /// last cached location, if available.
  ///
  /// This method is appropriate to get a one shot current location on Android, but
  /// not so much on iOS. See [currentLocation] for a better way to get the current
  /// location on both platforms.
  ///
  /// To cancel ongoing location request, unsubscribe from the stream.
  ///
  /// On Android, it calls FusedLocationProviderClient.getLastLocation()
  /// See: https://developers.google.com/android/reference/com/google/android/gms/location/FusedLocationProviderClient#getLastLocation()
  ///
  /// On iOS, it calls CLLocationManager.location
  /// See: https://developer.apple.com/documentation/corelocation/cllocationmanager/1423687-location
  ///
  /// [LocationResult.isSuccessful] means a location was retrieved and [LocationResult.location] is guaranteed
  /// to not be null.
  /// Otherwise, [GeolocationResult.error] will contain details on what failed.
  static Future<LocationResult> get lastKnownLocation =>
      _locationChannel.lastKnownLocation();

  /// Retrieves the current [Location], using different mechanics on Android and iOS that are
  /// more appropriate for this purpose.
  ///
  /// Stream will push a single [LocationResult] downstream then complete.//
  /// To cancel ongoing location request, unsubscribe from the stream.
  ///
  /// On Android, it returns the last known location in case the location is available and still
  /// valid. Otherwise it requests a single location update with the provided [accuracy].
  ///
  /// On iOS, it requests a single location update with the provided [accuracy].
  ///
  /// [LocationResult.isSuccessful] means a location was retrieved and [LocationResult.location] is guaranteed
  /// to not be null.
  /// Otherwise, [GeolocationResult.error] will contain details on what failed.
  ///
  /// See also:
  /// * [singleLocationUpdate]
  static Stream<LocationResult> currentLocation(LocationAccuracy accuracy) =>
      _locationChannel.locationUpdates(new _LocationUpdatesRequest(
          strategy: _LocationUpdateStrategy.current, accuracy: accuracy));

  /// Requests a single [Location] update with the provided [accuracy].
  /// If you just want to get a single optimized and accurate location, it's better to use [currentLocation].
  ///
  /// Stream will push a single [LocationResult] downstream then complete.
  /// To cancel ongoing location request, unsubscribe from the stream.
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
  ///
  /// [LocationResult.isSuccessful] means a location was retrieved and [LocationResult.location] is guaranteed
  /// to not be null.
  /// Otherwise, [GeolocationResult.error] will contain details on what failed.
  ///
  /// See also:
  /// * [currentLocation]
  static Stream<LocationResult> singleLocationUpdate(
          LocationAccuracy accuracy) =>
      _locationChannel.locationUpdates(new _LocationUpdatesRequest(
          strategy: _LocationUpdateStrategy.single, accuracy: accuracy));

  static Stream<LocationResult> locationUpdates(LocationAccuracy accuracy) =>
      _locationChannel.locationUpdates(new _LocationUpdatesRequest(
          strategy: _LocationUpdateStrategy.continuous, accuracy: accuracy));

  /// When activated, the plugin will print the following logs:
  /// * location updates event (start/stop)
  /// * json payloads exchanged between flutter and platform plugins
  static bool loggingEnabled = false;

  static final _LocationChannel _locationChannel = new _LocationChannel();
}

class GeolocationException implements Exception {
  GeolocationException(this.message);

  final String message;

  @override
  String toString() {
    return 'Geolocation error: $message';
  }
}

_log(String message, {String tag}) {
  if (Geolocation.loggingEnabled) {
    debugPrint(tag != null ? '$tag: $message' : message);
  }
}
