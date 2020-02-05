//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

library geolocation;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

part 'channel/codec.dart';
part 'channel/helper.dart';
part 'channel/location_channel.dart';
part 'channel/param.dart';
part 'data/location.dart';
part 'data/location_result.dart';
part 'data/permission.dart';
part 'data/result.dart';
part 'facet_android/location.dart';
part 'facet_android/permission.dart';
part 'facet_android/result.dart';
part 'facet_ios/location.dart';
part 'facet_ios/permission.dart';

/// Provides an access to geolocation features of the underlying platform (Android or iOS).
class Geolocation {
  /// Checks if location service is currently operational.
  /// It includes if location [permission] is granted.
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
  static Future<GeolocationResult> isLocationOperational({
    LocationPermission permission = const LocationPermission(),
  }) =>
      _locationChannel.isLocationOperational(permission);

  /// Requests enabling location services, if needed.
  ///
  /// If location services are already enabled, it returns successfully.
  /// If location is not operational it'll ask to enable it and will fail right away
  ///
  ///
  static Future<GeolocationResult> enableLocationServices() =>
      _locationChannel.enableLocationServices();

  /// Requests the location [permission], if needed.
  ///
  /// If location permission is already granted, it returns successfully.
  /// If location is not operational (location disabled, google play services unavailable on Android, etc), the request will fail without asking the permission.
  ///
  /// If the user denied the permission before, requesting it again won't show the dialog again on iOS.
  /// On Android, it happens when user declines and checks `don't ask again`.
  /// In this situation, [openSettingsIfDenied] will show the system settings where the user can manually enable location for the app.
  ///
  /// You don't need to call this method manually before requesting a location.
  /// Every [Geolocation] location request will also request the permission automatically if needed.
  ///
  /// This method is useful to request the permission earlier in the application flow, like during an on boarding.
  ///
  /// Requested permission must be declared in `Info.plist` for iOS and `AndroidManifest.xml` for Android.
  /// Throws a [GeolocationException] if the associated declaration is missing.
  ///
  /// See also:
  ///
  ///  * [LocationPermission], which describes what are the available permissions
  ///  * [GeolocationResult], the result you can expect from this request.
  static Future<GeolocationResult> requestLocationPermission({
    LocationPermission permission = const LocationPermission(),
    bool openSettingsIfDenied = true,
  }) =>
      _locationChannel.requestLocationPermission(_PermissionRequest(
        permission,
        openSettingsIfDenied: openSettingsIfDenied,
      ));

  /// Retrieves the most recent [Location] currently available.
  /// Automatically request location [permission] beforehand if not granted.
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
  static Future<LocationResult> lastKnownLocation({
    LocationPermission permission = const LocationPermission(),
  }) =>
      _locationChannel.lastKnownLocation(permission);

  /// Requests a single [Location] update.
  /// Automatically request location [permission] beforehand if not granted.
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
    LocationPermission permission = const LocationPermission(),
    LocationOptionsAndroid androidOptions =
        LocationOptionsAndroid.defaultSingle,
    LocationOptionsIOS iosOptions = const LocationOptionsIOS(),
  }) =>
      _locationChannel.locationUpdates(_LocationUpdatesRequest(
        _LocationUpdateStrategy.single,
        permission,
        accuracy,
        inBackground,
        androidOptions,
        iosOptions,
      ));

  /// Requests the current "one-shot" [Location], using Android and iOS best practice mechanics.
  /// Automatically request location [permission] beforehand if not granted.
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
    LocationPermission permission = const LocationPermission(),
    LocationOptionsAndroid androidOptions =
        LocationOptionsAndroid.defaultSingle,
    LocationOptionsIOS iosOptions = const LocationOptionsIOS(),
  }) =>
      _locationChannel.locationUpdates(_LocationUpdatesRequest(
        _LocationUpdateStrategy.current,
        permission,
        accuracy,
        inBackground,
        androidOptions,
        iosOptions,
      ));

  /// Requests continuous [Location] updates.
  /// Automatically request location [permission] beforehand if not granted.
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
    LocationPermission permission = const LocationPermission(),
    LocationOptionsAndroid androidOptions =
        LocationOptionsAndroid.defaultContinuous,
    LocationOptionsIOS iosOptions = const LocationOptionsIOS(),
  }) =>
      _locationChannel.locationUpdates(_LocationUpdatesRequest(
        _LocationUpdateStrategy.continuous,
        permission,
        accuracy,
        inBackground,
        androidOptions,
        iosOptions,
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
