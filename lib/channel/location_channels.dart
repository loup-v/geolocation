//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

part of geolocation;

class _LocationChannels {
  static const MethodChannel _channel =
      const MethodChannel('geolocation/location');

  static final StreamsChannel _updatesChannel =
      new StreamsChannel('geolocation/locationUpdates', JSONMethodCodec());

  Future<GeolocationResult> isLocationOperational(
      LocationPermission permission) async {
    final response = await _invokeChannelMethod('location', _channel,
        'isLocationOperational', _Codec.encodeLocationPermission(permission));
    return _Codec.decodeResult(response);
  }

  Future<GeolocationResult> requestLocationPermission(
      LocationPermission permission) async {
    final response = await _invokeChannelMethod(
        'location',
        _channel,
        'requestLocationPermission',
        _Codec.encodeLocationPermission(permission));
    return _Codec.decodeResult(response);
  }

  Future<LocationResult> lastKnownLocation(
      LocationPermission permission) async {
    final response = await _invokeChannelMethod('location', _channel,
        'lastKnownLocation', _Codec.encodeLocationPermission(permission));
    return _Codec.decodeLocationResult(response);
  }

  Stream<LocationResult> locationUpdates(_LocationUpdatesRequest request) {
    final json = _Codec.encodeLocationUpdatesRequest(request);
    _log('request: $json', tag: 'location updates');
    return _updatesChannel.receiveBroadcastStream(json).map((data) {
      _log('receive: $json', tag: 'location updates');
      return _Codec.decodeLocationResult(data);
    });
  }
}
