//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

part of geolocation;

// Location updates communicate with platform plugin through a mix of [EventChannel] and [MethodChannel].
// Reasons:
//
//  * [EventChannel] does not allow to pass arguments for each subscription, only the first one.
//    Not all location requests are equal, and requests with higher accuracy, frequency or longer lifespan should
//    take precedence over previous requests (while still not stoping previous request subscriptions).
//
//  * Concurrent location updates request are not allowed on iOS and Android, so we need a system
//    where the first subscription starts location updates, and the next ones will only attach their
//    callback to already running request.
//
//  * Subscriptions share a single location request on the platform but each subscriptions must be independent.
//    A single location subscription should be closed after a single result was listened to while a continuous update subscription will continue
//    until owner cancels it.
class _LocationChannel {
  static const MethodChannel _channel =
      const MethodChannel('geolocation/location');

  static const EventChannel _updatesChannel =
      const EventChannel('geolocation/locationUpdates');

  static const String _loggingTag = 'location result';

  final Stream<LocationResult> _updatesStream =
      _updatesChannel.receiveBroadcastStream().map((data) {
    _log(data, tag: _loggingTag);
    return _Codec.decodeLocationResult(data);
  });

  final List<_LocationUpdatesSubscription> _updatesSubscriptions = [];

  Future<GeolocationResult> isLocationOperational(
      LocationPermission permission) async {
    final response = await _invokeChannelMethod(
      _loggingTag,
      _channel,
      'isLocationOperational',
      _Codec.encodeLocationPermission(permission),
    );
    return _Codec.decodeResult(response);
  }

  Future<GeolocationResult> requestLocationPermission(
      _PermissionRequest request) async {
    final response = await _invokeChannelMethod(
      _loggingTag,
      _channel,
      'requestLocationPermission',
      _Codec.encodePermissionRequest(request),
    );
    return _Codec.decodeResult(response);
  }

  Future<GeolocationResult> enableLocationServices() async {
    final response = await _invokeChannelMethod(
        _loggingTag, _channel, 'enableLocationServices', '');
    return _Codec.decodeResult(response);
  }

  Future<LocationResult> lastKnownLocation(
      LocationPermission permission) async {
    final response = await _invokeChannelMethod(
      _loggingTag,
      _channel,
      'lastKnownLocation',
      _Codec.encodeLocationPermission(permission),
    );
    return _Codec.decodeLocationResult(response);
  }

  // Creates a new subscription to the channel stream and notifies
  // the platform about the desired params (accuracy, frequency, strategy) so the platform
  // can start the location request if it's the first subscription or update ongoing request with new params if needed
  Stream<LocationResult> locationUpdates(_LocationUpdatesRequest request) {
    // The stream that will be returned for the current updates request
    StreamController<LocationResult> controller;
    _LocationUpdatesSubscription subscription;

    final StreamSubscription<LocationResult> updatesSubscription =
        _updatesStream.listen((LocationResult result) {
      // Forward channel stream location result to subscription
      controller.add(result);

      // [_LocationUpdateStrategy.current] and [_LocationUpdateStrategy.single] only get a single result, then closes
      if (request.strategy != _LocationUpdateStrategy.continuous) {
        subscription.subscription.cancel();
        _updatesSubscriptions.remove(subscription);
        controller.close();
      }
    });

    updatesSubscription.onDone(() {
      _updatesSubscriptions.remove(subscription);
    });

    // Uniquely identify each request, in order to be able to manipulate each request of platform side
    request.id = (_updatesSubscriptions.isNotEmpty
            ? _updatesSubscriptions.map((it) => it.requestId).reduce(math.max)
            : 0) +
        1;

    subscription = new _LocationUpdatesSubscription(
      request.id,
      updatesSubscription,
    );
    _updatesSubscriptions.add(subscription);

    controller = new StreamController<LocationResult>.broadcast(
      onListen: () {
        _log('add location updates [id=${subscription.requestId}]');
        _invokeChannelMethod(
          _loggingTag,
          _channel,
          'addLocationUpdatesRequest',
          _Codec.encodeLocationUpdatesRequest(request),
        );
      },
      onCancel: () {
        _log('remove location updates [id=${subscription.requestId}]');
        subscription.subscription.cancel();
        _updatesSubscriptions.remove(subscription);

        _invokeChannelMethod(
          _loggingTag,
          _channel,
          'removeLocationUpdatesRequest',
          subscription.requestId,
        );
      },
    );

    return controller.stream;
  }
}

class _LocationUpdatesSubscription {
  _LocationUpdatesSubscription(this.requestId, this.subscription);

  final int requestId;
  final StreamSubscription<LocationResult> subscription;
}
