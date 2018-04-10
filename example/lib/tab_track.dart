//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocation/geolocation.dart';

class TabTrack extends StatefulWidget {
  @override
  _TabTrackState createState() => new _TabTrackState();
}

class _TabTrackState extends State<TabTrack> {
  List<_LocationData> _locations = [];
  StreamSubscription<LocationResult> _subscription;
  int _subscriptionStartedTimestamp;
  bool _isTracking = false;

  @override
  dispose() {
    super.dispose();
    _subscription.cancel();
  }

  _onTogglePressed() {
    if (_isTracking) {
      setState(() {
        _isTracking = false;
      });

      _subscription.cancel();
      _subscription = null;
      _subscriptionStartedTimestamp = null;
    } else {
      setState(() {
        _isTracking = true;
      });

      _subscriptionStartedTimestamp = new DateTime.now().millisecondsSinceEpoch;
      _subscription = Geolocation
          .locationUpdates(accuracy: LocationAccuracy.best)
          .listen((result) {
        final location = new _LocationData(
          result: result,
          elapsedTimeSeconds: (new DateTime.now().millisecondsSinceEpoch -
                  _subscriptionStartedTimestamp) ~/
              1000,
        );

        setState(() {
          _locations.insert(0, location);
        });
      });

      _subscription.onDone(() {
        setState(() {
          _isTracking = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      new _Header(
        isRunning: _isTracking,
        onTogglePressed: _onTogglePressed,
      )
    ];

    children.addAll(ListTile.divideTiles(
      context: context,
      tiles: _locations.map((location) => new _Item(data: location)).toList(),
    ));

    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Location updates'),
      ),
      body: new ListView(
        children: children,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  _Header({@required this.isRunning, this.onTogglePressed});

  final bool isRunning;
  final VoidCallback onTogglePressed;

  @override
  Widget build(BuildContext context) {
    return new Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: new Center(
        child: new _HeaderButton(
          title: isRunning ? 'Stop' : 'Start',
          color: isRunning ? Colors.deepOrange : Colors.teal,
          onTap: onTogglePressed,
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  _HeaderButton(
      {@required this.title, @required this.color, @required this.onTap});

  final String title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return new Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: new GestureDetector(
        onTap: onTap,
        child: new Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15.0),
          decoration: new BoxDecoration(
            color: color,
            borderRadius: new BorderRadius.all(
              new Radius.circular(6.0),
            ),
          ),
          child: new Text(
            title,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  _Item({@required this.data});

  final _LocationData data;

  @override
  Widget build(BuildContext context) {
    String text;
    String status;
    Color color;

    if (data.result.isSuccessful) {
      text =
          'Lat: ${data.result.location.latitude} - Lng: ${data.result.location
          .longitude}';
      status = 'success';
      color = Colors.green;
    } else {
      switch (data.result.error.type) {
        case GeolocationResultErrorType.runtime:
          text = 'Failure: ${data.result.error.message}';
          break;
        case GeolocationResultErrorType.locationNotFound:
          text = 'Location not found';
          break;
        case GeolocationResultErrorType.serviceDisabled:
          text = 'Service disabled';
          break;
        case GeolocationResultErrorType.permissionDenied:
          text = 'Permission denied';
          break;
        case GeolocationResultErrorType.playServicesUnavailable:
          text =
              'Play services unavailable: ${data.result.error.additionalInfo}';
          break;
      }

      status = 'failure';
      color = Colors.red;
    }

    final List<Widget> content = <Widget>[
      new Text(
        text,
        style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      new SizedBox(
        height: 3.0,
      ),
      new Text(
        'Elapsed time: ${data.elapsedTimeSeconds == 0 ? '< 1' : data
            .elapsedTimeSeconds}s',
        style: const TextStyle(fontSize: 12.0, color: Colors.grey),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ];

    return new Container(
      color: Colors.white,
      child: new SizedBox(
        height: 56.0,
        child: new Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: new Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              new Expanded(
                child: new Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: content,
                ),
              ),
              new Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                decoration: new BoxDecoration(
                  color: color,
                  borderRadius: new BorderRadius.circular(6.0),
                ),
                child: new Text(
                  status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.0,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationData {
  _LocationData({
    @required this.result,
    @required this.elapsedTimeSeconds,
  });

  final LocationResult result;
  final int elapsedTimeSeconds;
}
