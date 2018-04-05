//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

part of geolocation;

class _Codec {
  static GeolocationResult decodeResult(String data) =>
      GeolocationResult._fromJson(json.decode(data));

  static LocationResult decodeLocationResult(String data) =>
      LocationResult._fromJson(json.decode(data));

  static String encodeLocationUpdatesRequest(_LocationUpdatesRequest request) =>
      json.encode(request.toJson());

  // see: https://stackoverflow.com/questions/49611724/dart-how-to-json-decode-0-as-double
  static double parseJsonNumber(dynamic value) {
    return value.runtimeType == int ? (value as int).toDouble() : value;
  }

  static String encodeEnum(dynamic value) {
    return value.toString().split('.').last;
  }
}
