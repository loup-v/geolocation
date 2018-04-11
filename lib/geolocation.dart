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

/// Provides an access to geolocation features of the underlying platform (Android or iOS).
class Geolocation {
  /// Checks if location service is currently operational.
  ///
  /// Operational location means that the device is able to make location requests.
  /// Otherwise it means that the device's location service is disabled, restricted, or not permitted.
  ///
  /// Note that being operational does not mean that location request is guaranteed to succeed.
  /// Location request might still fail if device has no GPS coverage for instance. There is no way to know this
  /// before making the location request.
  ///
  /// See also:
  ///
  ///  * [GeolocationResult], the result you can expect from this request.
  static Future<GeolocationResult> get isLocationOperational =>
      _locationChannel.isLocationOperational();

  /// Requests the location permission, if needed.
  ///
  /// If location permission is already granted, it returns successfully.
  /// If location is not operational, the request will fail without asking the permission.
  ///
  /// You don't need to call this method manually.
  /// Every [Geolocation] method requiring the location permission will request it automatically if needed.
  /// However it's a common practice to request the permission early in the application flow (like during an on boarding flow).
  ///
  /// Behaviour per platform:
  ///
  ///  * Android: Requests `fine` or `coarse` location permission, depending on what the declaration in `AndroidManifest.xml`.
  ///  * iOS: Requests `when in use` or `always` location permission, depending on what description is provided in `Infos.plist`.
  ///
  /// If required declaration is missing in `AndroidManifest.xml` or in `Infos.plist`, location will not work.
  /// Throws a [GeolocationException] if missing, to help you catch this mistake.
  ///
  /// See also:
  ///
  ///  * [GeolocationResult], the result you can expect from this request.
  static Future<GeolocationResult> requestLocationPermission() =>
      _locationChannel.requestLocationPermission();

  /// Retrieves the most recent [Location] currently available.
  ///
  /// It does not request the device to fetch a new location, but returns the last cached location.
  /// Location is not guaranteed to be available, and request will fail with [GeolocationResultErrorType.locationNotFound] otherwise.
  /// This method is reliable to get a one-shot current location on Android, but not so much on iOS.
  ///
  /// See also:
  ///
  ///  * [currentLocation], which provides a better way to get the current one-shot location on both platforms.
  ///  * [LocationResult], the result you can expect from this request.
  ///  * Android behaviour: <https://developer.android.com/training/location/retrieve-current.html>
  ///  * iOS behaviour: <https://developer.apple.com/documentation/corelocation/cllocationmanager/1423687-location>
  static Future<LocationResult> get lastKnownLocation =>
      _locationChannel.lastKnownLocation();

  /// Requests a single [Location] update.
  ///
  /// The location service will try to match the requested [accuracy], but it can also return a less accurate [Location] as fallback.
  ///
  /// By default, location requests are stopped when app goes to background, and resumed when app comes back to foreground.
  /// You can disable this behaviour by setting `true` for [inBackground].
  ///
  /// A single [LocationResult] will be pushed down the stream, and the stream will complete.
  /// To stop the ongoing location request, cancel the subscription.
  ///
  /// If no location is retrieved after some time (30 seconds on Android, ~10 seconds on iOS), the request will timeout and complete.
  /// On timeout, the device will return a less accurate location if available, or [GeolocationResultErrorType.locationNotFound].
  ///
  /// See also:
  ///
  ///  * [currentLocation], which provides a better way to get the current one-shot location on both platforms.
  ///  * [LocationResult], the result you can expect from this request.
  ///  * Android behaviour: <https://developer.android.com/training/location/receive-location-updates.html>
  ///  * iOS behaviour: <https://developer.apple.com/documentation/corelocation/cllocationmanager/1620548-requestlocation>
  static Stream<LocationResult> singleLocationUpdate({
    @required LocationAccuracy accuracy,
    bool inBackground = false,
  }) =>
      _locationChannel.locationUpdates(new _LocationUpdatesRequest(
        _LocationUpdateStrategy.single,
        accuracy,
        inBackground,
      ));

  /// Requests the current "one-shot" [Location], using Android and iOS best practice mechanics.
  ///
  /// The location service will try to match the requested [accuracy], but it can also return a less accurate [Location] as fallback.
  ///
  /// By default, location requests are stopped when app goes to background, and resumed when app comes back to foreground.
  /// You can disable this behaviour by setting `true` for [inBackground].
  ///
  /// A single [LocationResult] will be pushed down the stream, and the stream will complete.
  /// To stop the ongoing location request, cancel the subscription.
  ///
  /// Behaviour per platform:
  ///
  ///  * Android: Returns the last known location if available and valid. Otherwise requests a single location update.
  ///  If last known location is retrieved, no location request is started. [accuracy] and [inBackground] will be ignored.
  ///  * iOS: Requests a single location update.
  ///
  /// See also:
  ///
  ///  * [lastKnownLocation], for more explanation on how getting last known location work.
  ///  * [singleLocationUpdate], for more explanation on how single location update work.
  ///  * [LocationResult], the result you can expect from this request.
  static Stream<LocationResult> currentLocation({
    @required LocationAccuracy accuracy,
    bool inBackground = false,
  }) =>
      _locationChannel.locationUpdates(new _LocationUpdatesRequest(
        _LocationUpdateStrategy.current,
        accuracy,
        inBackground,
      ));

  /// Requests continuous [Location] updates.
  ///
  /// The location service will try to match the requested [accuracy], but it can also return a less accurate [Location] as fallback.
  ///
  /// Filter minimum [displacementFilter] distance in meters between each [Location] updates.
  ///
  /// By default, location requests are stopped when app goes to background, and resumed when app comes back to foreground.
  /// You can disable this behaviour by setting `true` for [inBackground].
  ///
  /// [LocationResult] will be pushed down the stream continuously until the subscription is cancelled.
  /// To stop the ongoing location request, cancel the subscription.
  ///
  /// See also:
  ///
  ///  * [LocationResult], the result you can expect from this request.
  ///  * Android behaviour: <https://developer.android.com/training/location/receive-location-updates.html>
  ///  * iOS behaviour: <https://developer.apple.com/documentation/corelocation/cllocationmanager/1423750-startupdatinglocation>
  static Stream<LocationResult> locationUpdates({
    @required LocationAccuracy accuracy,
    double displacementFilter = 0.0,
    bool inBackground = false,
  }) =>
      _locationChannel.locationUpdates(new _LocationUpdatesRequest(
        _LocationUpdateStrategy.continuous,
        accuracy,
        inBackground,
        displacementFilter,
      ));

  /// Activate verbose logging for debugging purposes.
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
