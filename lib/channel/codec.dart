//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

part of geolocation;

class _Codec {
  static LocationResult decodeLocation(String data) =>
      LocationResult._fromJson(json.decode(data));

  static String encodeSingleLocation(LocationAccuracy accuracy) => json.encode({
        'accuracy': {
          'ios': accuracy.ios.toString().split('.').last,
          'android': accuracy.android.toString().split('.').last,
        }
      });

  // see: https://stackoverflow.com/questions/49611724/dart-how-to-json-decode-0-as-double
  static double parseJsonNumber(dynamic value) {
    return value.runtimeType == int ? (value as int).toDouble() : value;
  }
}
