//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocation/geolocation.dart';

class TabSettings extends StatefulWidget {
  @override
  _TabSettingsState createState() => new _TabSettingsState();
}

class _TabSettingsState extends State<TabSettings> {
  GeolocationResult _locationOperationalResult;
  GeolocationResult _requestPermissionResult;

  @override
  initState() {
    super.initState();
    _isLocationOperationalPressed();
  }

  _isLocationOperationalPressed() async {
    final GeolocationResult result = await Geolocation.isLocationOperational();
    if (mounted) {
      setState(() {
        _locationOperationalResult = result;
      });
    }
  }

  _requestLocationPermissionPressed() async {
    final GeolocationResult result =
        await Geolocation.requestLocationPermission();
    if (mounted) {
      setState(() {
        _requestPermissionResult = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Settings'),
      ),
      body: new ListView(
        children: ListTile.divideTiles(context: context, tiles: [
          new _Item(
            isPermissionRequest: false,
            result: _locationOperationalResult,
            onPressed: _isLocationOperationalPressed,
          ),
          new _Item(
            isPermissionRequest: true,
            result: _requestPermissionResult,
            onPressed: _requestLocationPermissionPressed,
          ),
        ]).toList(),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  _Item({@required this.isPermissionRequest, this.result, this.onPressed});

  final bool isPermissionRequest;
  final GeolocationResult result;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    String text;
    String status;
    Color color;

    if (result != null) {
      if (result.isSuccessful) {
        text = isPermissionRequest
            ? 'Location permission granted'
            : 'Location is operational';

        status = 'success';
        color = Colors.green;
      } else {
        switch (result.error.type) {
          case GeolocationResultErrorType.runtime:
            text = 'Failure: ${result.error.message}';
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
            text = 'Play services unavailable: ${result.error.additionalInfo}';
            break;
        }

        status = 'failure';
        color = Colors.red;
      }
    } else {
      text = 'Is ${isPermissionRequest
          ? 'permission granted'
          : 'location operational'}?';

      status = 'undefined';
      color = Colors.blueGrey;
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
        'Tap to request',
        style: const TextStyle(fontSize: 12.0, color: Colors.grey),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ];

    return new GestureDetector(
      onTap: onPressed,
      child: new Container(
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
      ),
    );
  }
}
