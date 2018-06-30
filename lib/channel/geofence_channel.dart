//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

part of geolocation;

class _GeofenceChannel {
  final MethodChannel _channel;

  static const EventChannel _updatesChannel =
      const EventChannel('geolocation/geofenceUpdates');

  static const String _loggingTag = 'geofence result';

  final Stream<GeofenceEventResult> _geofenceUpdates =
      _updatesChannel.receiveBroadcastStream().map((data) {
    _log(data, tag: _loggingTag);
    return _Codec.decodeGeofenceEventResult(data);
  });

  _GeofenceChannel(this._channel);

  void addGeofenceRegion(GeofenceRegion region) {
    _invokeChannelMethod(_loggingTag, _channel, 'addGeofenceRegion',
        _Codec.encodeGeofenceRegion(region));
  }

  void removeGeofenceRegion(GeofenceRegion region) {
    _invokeChannelMethod(_loggingTag, _channel, 'removeGeofenceRegion',
        _Codec.encodeGeofenceRegion(region));
  }

  Future<List<GeofenceRegion>> geofenceRegions() async {
    final data = await _invokeChannelMethod(_loggingTag, _channel, 'geofenceRegions');
    return _Codec.decodeGeofenceRegions(data);
  }
}
