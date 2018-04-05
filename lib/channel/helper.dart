//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

part of geolocation;

Future<String> _invokeChannelMethod(
    String tag, MethodChannel channel, String method,
    [dynamic arguments]) async {
  String data;
  try {
    data = await channel.invokeMethod(method, arguments);
  } catch (exception, stack) {
    FlutterError.reportError(new FlutterErrorDetails(
      exception: exception,
      stack: stack,
      library: 'geolocation',
      context: 'while invoking ${channel.name}/$method',
    ));
  }

  _log(data, tag: tag);
  return data;
}
