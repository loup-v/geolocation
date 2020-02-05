//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

part of geolocation;

class _LocationUpdatesRequest {
  _LocationUpdatesRequest(
    this.strategy,
    this.permission,
    this.accuracy,
    this.inBackground,
    this.androidOptions,
    this.iosOptions, [
    this.displacementFilter = 0.0,
  ]) {
    assert(displacementFilter >= 0.0);
  }

  int id;
  final _LocationUpdateStrategy strategy;
  final LocationPermission permission;
  final LocationAccuracy accuracy;
  final bool inBackground;
  final double displacementFilter;
  final LocationOptionsAndroid androidOptions;
  final LocationOptionsIOS iosOptions;
}

enum _LocationUpdateStrategy { current, single, continuous }

class _PermissionRequest {
  _PermissionRequest(
    this.value, {
    @required this.openSettingsIfDenied,
  });
  final LocationPermission value;
  final bool openSettingsIfDenied;
}
