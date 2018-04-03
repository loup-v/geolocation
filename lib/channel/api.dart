//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

part of geolocation;

class _Api {
  static const MethodChannel _channel =
      const MethodChannel('io.intheloup.geolocation');

  Future<LocationResult> lastKnownLocation() async {
    final response = await _channel.invokeMethod('lastKnownLocation');
    return _Codec.decodeLocation(response);
  }

  Future<LocationResult> currentLocation(LocationAccuracy accuracy) async {
    final response = await _channel.invokeMethod(
      'currentLocation',
      _Codec.encodeSingleLocation(accuracy),
    );
    return _Codec.decodeLocation(response);
  }

  Future<LocationResult> singleLocationUpdate(LocationAccuracy accuracy) async {
    final response = await _channel.invokeMethod(
      'singleLocationUpdate',
      _Codec.encodeSingleLocation(accuracy),
    );
    return _Codec.decodeLocation(response);
  }
}
