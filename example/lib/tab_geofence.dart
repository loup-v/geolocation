//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocation/geolocation.dart';

class TabGeofence extends StatefulWidget {
  @override
  _TabGeofenceState createState() => new _TabGeofenceState();
}

class _TabGeofenceState extends State<TabGeofence> {
  List<GeofenceEventResult> _geofenceEventResults = [];
  StreamSubscription<GeofenceEventResult> _subscription;
  bool _isTracking = false;
  List<GeofenceRegion> _geofenceRegions = [];

  @override
  void initState() {
    super.initState();
    _updateRegionsList();
  }

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
    } else {
      setState(() {
        _isTracking = true;
      });

      _subscription = Geolocation.geofenceUpdates.listen((result) {
        setState(() {
          _geofenceEventResults.insert(0, result);
        });
      });

      _subscription.onDone(() {
        setState(() {
          _isTracking = false;
        });
      });
    }
  }

  _onAddPressed() async {
    final region = GeofenceRegion(
        id: "MyHome",
        notifyOnExit: true,
        notifyOnEntry: true,
        region: Region(
            center: Location(longitude: 10.0, latitude: 10.0), radius: 10.0));
    Geolocation.addGeofenceRegion(region);
    _updateRegionsList();
  }

  _onRemovePressed() async {
    final region = GeofenceRegion(
        id: "MyHome",
        notifyOnExit: true,
        notifyOnEntry: true,
        region: Region(
            center: Location(longitude: 10.0, latitude: 10.0), radius: 10.0));
    Geolocation.removeGeofenceRegion(region);
    final regions = await Geolocation.geofenceRegions();
    print(regions);
    _updateRegionsList();
  }

  _updateRegionsList() async {
    _geofenceRegions = await Geolocation.geofenceRegions();
    setState(() {
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      new _Header(
        isRunning: _isTracking,
        onTogglePressed: _onTogglePressed,
        onAddPressed: _onAddPressed,
        onRemovePressed: _onRemovePressed,
      )
    ];
    
    if (_geofenceRegions.length != 0) {
      children.add(ListTile(
        title: Text(
          "Active Geofence regions:",
          style: Theme.of(context).textTheme.subhead,
        ),
      ));

      children.addAll(ListTile.divideTiles(
        context: context,
        tiles: _geofenceRegions.map((geofenceRegion) {
          return ListTile(
            title: new Text("${geofenceRegion.id}"),
            subtitle: Text("Latitude: ${geofenceRegion.region.center
                .latitude}\nLongitude: ${geofenceRegion.region.center
                .longitude}"),
          );
        }).toList(),
      ));
      children.add(Divider(height: 32.0,));
    }

    children.addAll(ListTile.divideTiles(
      context: context,
      tiles:
          _geofenceEventResults.map((event) => new _Item(data: event)).toList(),
    ));

    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Geofence updates'),
      ),
      body: new ListView(
        children: children,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  _Header(
      {@required this.isRunning,
      @required this.onTogglePressed,
      @required this.onAddPressed,
      @required this.onRemovePressed});

  final bool isRunning;
  final VoidCallback onTogglePressed;
  final VoidCallback onAddPressed;
  final VoidCallback onRemovePressed;

  @override
  Widget build(BuildContext context) {
    return new Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: new Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          new Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              new _HeaderButton(
                title: isRunning ? 'Stop' : 'Start',
                color: isRunning ? Colors.deepOrange : Colors.teal,
                onTap: onTogglePressed,
              ),
              new _HeaderButton(
                title: 'Add Region',
                color: Colors.lightGreen,
                onTap: onAddPressed,
              ),
              new _HeaderButton(
                title: 'Remove Region',
                color: Colors.deepOrange,
                onTap: onRemovePressed,
              ),
            ],
          ),
        ],
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

  final GeofenceEventResult data;

  @override
  Widget build(BuildContext context) {
    String text;
    String status;
    Color color;

    if (data.isSuccessful) {
      String locationName = data.geofenceEvent.geofenceRegion.id;
      String event = data.geofenceEvent.type == GeofenceEventType.entered
          ? "Entered"
          : "Exited";

      text = '$event: $locationName';
      status = 'success';
      color = Colors.green;
    } else {
      switch (data.error.type) {
        case GeolocationResultErrorType.runtime:
          text = 'Failure: ${data.error.message}';
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
          text = 'Play services unavailable: ${data.error.additionalInfo}';
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
      )
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
