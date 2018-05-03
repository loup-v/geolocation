//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

part of geolocation;

class _LocationChannel {
  static const MethodChannel _channel =
      const MethodChannel('geolocation/location');

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
  static final _CustomEventChannel _locationUpdatesChannel =
      new _CustomEventChannel('geolocation/locationUpdates');
  static final _CustomEventChannel _geoFenceUpdatesChannel =
      new _CustomEventChannel('geolocation/geoFenceUpdates');
  static const String _loggingTag = 'location result';

  // Active subscriptions to channel event stream of location updates
  // Every data from channel stream will be forwarded to the subscriptions
  List<_LocationUpdatesSubscription> _locationUpdatesSubscriptions = [];
  List<_GeoFenceUpdatesSubscription> _geoFenceUpdatesSubscriptions = [];

  Future<GeolocationResult> isLocationOperational(
      LocationPermission permission) async {
    final response = await _invokeChannelMethod(_loggingTag, _channel,
        'isLocationOperational', _Codec.encodeLocationPermission(permission));
    return _Codec.decodeResult(response);
  }

  Future<GeolocationResult> requestLocationPermission(
      LocationPermission permission) async {
    final response = await _invokeChannelMethod(
        _loggingTag,
        _channel,
        'requestLocationPermission',
        _Codec.encodeLocationPermission(permission));
    return _Codec.decodeResult(response);
  }

  Future<LocationResult> lastKnownLocation(
      LocationPermission permission) async {
    final response = await _invokeChannelMethod(_loggingTag, _channel,
        'lastKnownLocation', _Codec.encodeLocationPermission(permission));
    return _Codec.decodeLocationResult(response);
  }

  // Creates a new subscription to the channel stream and notifies
  // the platform about the desired params (accuracy, frequency, strategy) so the platform
  // can start the location request if it's the first subscription or update ongoing request with new params if needed
  Stream<LocationResult> locationUpdates(_LocationUpdatesRequest request) {
    // The stream that will be returned for the current location request
    StreamController<LocationResult> controller;

    _LocationUpdatesSubscription subscriptionWithRequest;

    // Subscribe and listen to channel stream of location results
    final StreamSubscription<LocationResult> subscription =
        _locationUpdatesChannel.stream.map((data) {
      _log(data, tag: _loggingTag);
      return _Codec.decodeLocationResult(data);
    }).listen((LocationResult result) {
      // Forward channel stream location result to subscription
      controller.add(result);

      // [_LocationUpdateStrategy.current] and [_LocationUpdateStrategy.single] only get a single result, then close
      if (request.strategy != _LocationUpdateStrategy.continuous) {
        subscriptionWithRequest.subscription.cancel();
        _locationUpdatesSubscriptions.remove(subscriptionWithRequest);
        controller.close();
      }
    });

    subscription.onDone(() {
      _locationUpdatesSubscriptions.remove(subscriptionWithRequest);
    });

    subscriptionWithRequest =
        new _LocationUpdatesSubscription(request, subscription);

    // Add unique id for each request, in order to be able to remove them on platform side afterwards
    subscriptionWithRequest.request.id =
        (_locationUpdatesSubscriptions.isNotEmpty
                ? _locationUpdatesSubscriptions
                    .map((it) => it.request.id)
                    .reduce(math.max)
                : 0) +
            1;

    _log('create location updates request [id=${subscriptionWithRequest.request
        .id}]');
    _locationUpdatesSubscriptions.add(subscriptionWithRequest);

    controller = new StreamController<LocationResult>.broadcast(
      onListen: () {
        _log('add location updates request [id=${subscriptionWithRequest.request
            .id}]');
        _invokeChannelMethod(_loggingTag, _channel, 'addLocationUpdatesRequest',
            _Codec.encodeLocationUpdatesRequest(request));
      },
      onCancel: () async {
        _log('remove location updates request [id=${subscriptionWithRequest
            .request
            .id}]');
        subscriptionWithRequest.subscription.cancel();

        await _invokeChannelMethod(
            _loggingTag,
            _channel,
            'removeLocationUpdatesRequest',
            _Codec.encodeLocationUpdatesRequest(request));
        _locationUpdatesSubscriptions.remove(subscriptionWithRequest);
      },
    );

    return controller.stream;
  }

  // Creates a new subscription to the channel stream and notifies
// the platform about the desired params (accuracy, frequency, strategy) so the platform
// can start the location request if it's the first subscription or update ongoing request with new params if needed
Stream<GeoFenceResult> geoFenceUpdates(_GeoFenceUpdatesRequest request, bool singleUpdate) {
    // The stream that will be returned for the current geofence request
    StreamController<GeoFenceResult> controller;

    _GeoFenceUpdatesSubscription subscriptionWithRequest;

    // Subscribe and listen to channel stream of geofence results
    final StreamSubscription<GeoFenceResult> subscription =
        _geoFenceUpdatesChannel.stream.map((data) {
      _log(data, tag: _loggingTag);
      var resultObject = _Codec.decodeGeoFenceResult(data);
      return resultObject;
    }).listen((GeoFenceResult result) {
      // Forward channel stream geofence result to subscription
      controller.add(result);
    });

    subscription.onDone(() {
      _geoFenceUpdatesSubscriptions.remove(subscriptionWithRequest);
          if (singleUpdate) {
            controller.close();
            subscription.cancel();
          }
    });

    subscriptionWithRequest =
        new _GeoFenceUpdatesSubscription(request, subscription);

    // Add unique id for each request, in order to be able to remove them on platform side afterwards
    subscriptionWithRequest.request.id =
        (_geoFenceUpdatesSubscriptions.isNotEmpty
                ? _geoFenceUpdatesSubscriptions
                    .map((it) => it.request.id)
                    .reduce(math.max)
                : 0) +
            1;

    _log('create geofence updates request [id=${subscriptionWithRequest.request
        .id}]');
    _geoFenceUpdatesSubscriptions.add(subscriptionWithRequest);

    controller = new StreamController<GeoFenceResult>.broadcast(
      onListen: () {
        _log('add geofence updates request [id=${subscriptionWithRequest.request
            .id}]');
        _invokeChannelMethod('geofence result', _channel, 'addGeoFencingRequest',
            _Codec.encodeGeoFenceUpdatesRequest(request));
      },
      onCancel: () async {
        _log('remove geofence updates request [id=${subscriptionWithRequest
            .request
            .id}]');
        subscriptionWithRequest.subscription.cancel();

        await _invokeChannelMethod(
            'geofence result',
            _channel,
            'removeGeoFencingRequest',
            _Codec.encodeGeoFenceUpdatesRequest(request));
        _geoFenceUpdatesSubscriptions.remove(subscriptionWithRequest);
      },
    );

    return controller.stream;
  }
}

class _LocationUpdatesSubscription {
  _LocationUpdatesSubscription(this.request, this.subscription);

  final _LocationUpdatesRequest request;
  final StreamSubscription<LocationResult> subscription;
}

class _GeoFenceUpdatesSubscription {
  _GeoFenceUpdatesSubscription(this.request, this.subscription);

  final _GeoFenceUpdatesRequest request;
  final StreamSubscription<GeoFenceResult> subscription;
}

// Custom event channel that manages a single instance of the stream and exposes.
class _CustomEventChannel extends EventChannel {
  _CustomEventChannel(name, [codec = const StandardMethodCodec()])
      : super(name, codec);

  Stream<dynamic> _stream;

  Stream<dynamic> get stream {
    if (_stream == null) {
      _stream = receiveBroadcastStream();
    }
    return _stream;
  }

  @override
  Stream<dynamic> receiveBroadcastStream([dynamic arguments]) {
    final MethodChannel methodChannel = new MethodChannel(name, codec);
    StreamController<dynamic> controller;
    controller = new StreamController<dynamic>.broadcast(onListen: () async {
      BinaryMessages.setMessageHandler(name, (ByteData reply) async {
        if (reply == null) {
          controller.close();
        } else {
          try {
            controller.add(codec.decodeEnvelope(reply));
          } on PlatformException catch (e) {
            controller.addError(e);
          }
        }
      });
      try {
        await methodChannel.invokeMethod('listen', arguments);
      } catch (exception, stack) {
        FlutterError.reportError(new FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'services library',
          context: 'while activating platform stream on channel $name',
        ));
      }
    }, onCancel: () async {
      BinaryMessages.setMessageHandler(name, null);
      try {
        await methodChannel.invokeMethod('cancel', arguments);
      } catch (exception, stack) {
        FlutterError.reportError(new FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'services library',
          context: 'while de-activating platform stream on channel $name',
        ));
      }
    });

    return controller.stream;
  }
}
