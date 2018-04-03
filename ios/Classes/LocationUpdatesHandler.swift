//
//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0
//

import Foundation

class LocationUpdatesHandler : NSObject, FlutterStreamHandler {
  let locationClient: LocationClient
  
  init(locationClient: LocationClient) {
    self.locationClient = locationClient
    super.init()
  }
  
  func register(with registrar: FlutterPluginRegistrar) {
    let stream = FlutterEventChannel(name: "io.intheloup.geolocation/locationUpdatesStream", binaryMessenger: registrar.messenger())
    stream.setStreamHandler(self)
  }
  
  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    let param = Codec.decodeLocationUpdateParam(from: arguments)
    
    let callback: (Result<Location>) -> Void = { result in
      events(Codec.encode(result: result))
      
      if !result.isSuccessful || param.strategy != .continuous {
        events(FlutterEndOfEventStream)
      }
    }
    
    locationClient.locationUpdates(param: param, on: callback)
    return nil
  }
  
  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    locationClient.stopLocationUpdates()
    return nil
  }
}
