//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

part of geolocation;

class _LocationUpdatesRequest {
  _LocationUpdatesRequest(
      this.strategy, this.accuracy, this.inBackground, [this.displacementFilter = 0.0]);

  int id;
  final _LocationUpdateStrategy strategy;
  final LocationAccuracy accuracy;
  final bool inBackground;
  final double displacementFilter;

  Map<String, dynamic> toJson() => {
        'id': id,
        'strategy': _Codec.encodeEnum(strategy),
        'accuracy': {
          'ios': _Codec.encodeEnum(accuracy.ios),
          'android': _Codec.encodeEnum(accuracy.android),
        },
        'displacementFilter': displacementFilter,
        'inBackground': inBackground,
      };
}

enum _LocationUpdateStrategy { current, single, continuous }
