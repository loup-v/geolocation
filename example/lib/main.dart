//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocation/geolocation.dart';
import 'tab_location.dart';
import 'tab_track.dart';
import 'tab_settings.dart';
import 'tab_geofence.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  MyApp() {
    Geolocation.loggingEnabled = true;
  }

  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new CupertinoTabScaffold(
        tabBar: new CupertinoTabBar(
          items: <BottomNavigationBarItem>[
            new BottomNavigationBarItem(
              title: new Text('Current'),
              icon: new Icon(Icons.location_on),
            ),
            new BottomNavigationBarItem(
              title: new Text('Track'),
              icon: new Icon(Icons.location_searching),
            ),
            new BottomNavigationBarItem(
              title: new Text('GeoFence'),
              icon: new Icon(Icons.layers),
            ),
            new BottomNavigationBarItem(
              title: new Text('Settings'),
              icon: new Icon(Icons.settings_input_antenna),
            ),
          ],
        ),
        tabBuilder: (BuildContext context, int index) {
          return new CupertinoTabView(
            builder: (BuildContext context) {
              switch (index) {
                case 0:
                  return new TabLocation();
                case 1:
                  return new TabTrack();
                case 2:
                  return new TabGeoFence();
                case 3:
                  return new TabSettings();
                default:
                  return new Container(
                    child: new Center(
                      child: new Text('TBD'),
                    ),
                  );
              }
            },
          );
        },
      ),
    );
  }
}
