//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

part of geolocation;

class _LocationChannel {
  static const MethodChannel _channel =
      const MethodChannel('io.intheloup.geolocation/location');

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
      new _CustomEventChannel('io.intheloup.geolocation/locationUpdates');

  static const String _loggingTag = 'location result';

  // Active subscriptions to channel event stream of location updates
  // Every data from channel stream will be forwarded to the subscriptions
  List<StreamSubscription<LocationResult>> _locationUpdatesSubscriptions = [];

  Future<GeolocationResult> isLocationOperational() async {
    final response = await _invokeChannelMethod(
        _loggingTag, _channel, 'isLocationOperational');
    return _Codec.decodeResult(response);
  }

  Future<GeolocationResult> requestLocationPermission() async {
    final response = await _invokeChannelMethod(
        _loggingTag, _channel, 'requestLocationPermission');
    return _Codec.decodeResult(response);
  }

  Future<LocationResult> lastKnownLocation() async {
    final response =
        await _invokeChannelMethod(_loggingTag, _channel, 'lastKnownLocation');
    return _Codec.decodeLocationResult(response);
  }

  // Creates a new subscription to the channel stream and notifies
  // the platform about the desired params (accuracy, frequency, strategy) so the platform
  // can start the location request if it's the first subscription or update ongoing request with new params if needed
  Stream<LocationResult> locationUpdates(_LocationUpdatesRequest request) {
    // The stream that will be returned for the current location request
    StreamController<LocationResult> controller;

    // Subscribe and listen to channel stream of location results
    // ignore: cancel_subscriptions
    StreamSubscription<LocationResult> subscription;
    subscription = _locationUpdatesChannel.stream.map((data) {
      _log(data, tag: _loggingTag);
      return _Codec.decodeLocationResult(data);
    }).listen((LocationResult result) {
      // forward channel stream location result to subscription
      controller.add(result);

      // [_LocationUpdateStrategy.current] and [_LocationUpdateStrategy.single] only get a single result, then close
      if (request.strategy != _LocationUpdateStrategy.continuous) {
        subscription.cancel();
        _locationUpdatesSubscriptions.remove(subscription);
        controller.close();
      }
    });

    subscription.onDone(() {
      _locationUpdatesSubscriptions.remove(subscription);
    });

    _locationUpdatesSubscriptions.add(subscription);

    controller = new StreamController<LocationResult>.broadcast(onListen: () {
      _invokeChannelMethod(_loggingTag, _channel, 'startLocationUpdates',
          _Codec.encodeLocationUpdatesRequest(request));
    }, onCancel: () {
      subscription.cancel();
      _locationUpdatesSubscriptions.remove(subscription);
    });

    return controller.stream;
  }
}



// Custom event channel that manages a single instance of the stream and exposes.
class _CustomEventChannel extends EventChannel {
  _CustomEventChannel(name, [codec = const StandardMethodCodec()])
      : super(name, codec);

  StreamController<dynamic> controller;
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


// Adds an onUnsubscribe callback that gets triggered on cancel and on done.
// Warning: Wrapper does not handle "unsubscribe on error" behaviour.
//class _StreamSubscriptionWrapper<T> extends StreamSubscription<T> {
//  _StreamSubscriptionWrapper(this._target) {
//    _target.onDone(() {
//      _callUnsubscribe();
//    });
//  }
//
//  final StreamSubscription<T> _target;
//  VoidCallback _onUnsubscribe;
//
//  onUnsubscribe(VoidCallback onUnsubscribe) {
//    this._onUnsubscribe = onUnsubscribe;
//  }
//
//  _callUnsubscribe() {
//    if (_onUnsubscribe != null) {
//      _onUnsubscribe();
//    }
//  }
//
//  @override
//  Future cancel() {
//    _callUnsubscribe();
//    return _target.cancel();
//  }
//
//  @override
//  void onData(void handleData(T data)) {
//    _target.onData(handleData);
//  }
//
//  @override
//  void onError(Function handleError) {
//    _target.onError(handleError);
//  }
//
//  @override
//  void onDone(void handleDone()) {
//    _target.onDone(() {
//      _callUnsubscribe();
//      handleDone();
//    });
//  }
//
//  @override
//  void pause([Future resumeSignal]) {
//    _target.pause(resumeSignal);
//  }
//
//  @override
//  void resume() {
//    _target.resume();
//  }
//
//  @override
//  bool get isPaused {
//    return _target.isPaused;
//  }
//
//  @override
//  Future<E> asFuture<E>([E futureValue]) {
//    return _target.asFuture(futureValue);
//  }
//}