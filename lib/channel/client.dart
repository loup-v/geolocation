//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

part of geolocation;

class _Client {
  static const MethodChannel _channel =
      const MethodChannel('io.intheloup.geolocation');

  static const EventChannel _locationUpdatesChannel =
      const EventChannel('io.intheloup.geolocation/locationUpdatesStream');

  bool verboseLogging = false;

  Future<GeolocationResult> isLocationOperational() async {
    final response = await invokeChannelMethod('isLocationOperational');
    return _Codec.decodeResult(response);
  }

  Future<GeolocationResult> requestLocationPermission() async {
    final response = await invokeChannelMethod('requestLocationPermission');
    return _Codec.decodeResult(response);
  }

  Future<LocationResult> lastKnownLocation() async {
    final response = await invokeChannelMethod('lastKnownLocation');
    return _Codec.decodeLocationResult(response);
  }

  Future<Stream<LocationResult>> currentLocation(
      LocationAccuracy accuracy) async {
    return _locationUpdatesStream(_LocationUpdateParam(
      strategy: _LocationUpdateStrategy.current,
      accuracy: accuracy,
    ));
  }

  Future<Stream<LocationResult>> singleLocationUpdate(
      LocationAccuracy accuracy) async {
    return _locationUpdatesStream(_LocationUpdateParam(
      strategy: _LocationUpdateStrategy.single,
      accuracy: accuracy,
    ));
  }

  Future<Stream<LocationResult>> locationUpdates(
      LocationAccuracy accuracy) async {
    return _locationUpdatesStream(_LocationUpdateParam(
      strategy: _LocationUpdateStrategy.continuous,
      accuracy: accuracy,
    ));
  }

  Future<Stream<LocationResult>> _locationUpdatesStream(
      _LocationUpdateParam param) async {
    debugPrint('geolocation: ensure location permission is granted');
    final result = await requestLocationPermission();

    debugPrint('geolocation: start location update using strategy: ${_Codec.encodeEnum(param.strategy)}');

    if (result.isSuccessful) {
      return _locationUpdatesChannel
          .receiveBroadcastStream(_Codec.encodeLocationUpdateParam(param))
          .map((data) {
        if (verboseLogging) {
          debugPrint('geolocation result: $data');
        }

        return _Codec.decodeLocationResult(data);
      });
    } else {
      return _singleResultStream(result);
    }
  }

  Stream<LocationResult> _singleResultStream(LocationResult result) {
    final StreamController<LocationResult> controller =
        new StreamController<LocationResult>();
    controller.onListen = () {
      controller.add(result);
      controller.close();
    };
    return controller.stream;
  }

  Future<String> invokeChannelMethod(String method, [dynamic arguments]) async {
    final String data = await _channel.invokeMethod(method, arguments);
    if (verboseLogging) {
      debugPrint('geolocation result: $data');
    }

    return data;
  }
}
