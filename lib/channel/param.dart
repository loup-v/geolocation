//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

part of geolocation;

class _LocationUpdateParam {
  _LocationUpdateParam({
    @required this.strategy,
    @required this.accuracy,
  });

  final _LocationUpdateStrategy strategy;
  final LocationAccuracy accuracy;

  Map<String, dynamic> toJson() => {
        'strategy': _Codec.encodeEnum(strategy),
        'accuracy': {
          'ios': _Codec.encodeEnum(accuracy.ios),
          'android': _Codec.encodeEnum(accuracy.android),
        },
      };
}

enum _LocationUpdateStrategy { current, single, continuous }
