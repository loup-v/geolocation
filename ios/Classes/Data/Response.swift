//
//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0
//

import Foundation

struct Response<T: Codable> : Codable {
  let isSuccessful: Bool
  let data: T?
  let error: Error?
  
  struct Error: Codable {
    let type: ErrorType
    let message: String?
    let fatal: Bool?
    
    enum ErrorType: String, Codable {
      case runtime = "runtime"
      case locationNotFound = "locationNotFound"
      case permissionDenied = "permissionDenied"
      case serviceDisabled = "serviceDisabled"
    }
  }
}

struct Responses {
  static func success <T:Codable> (with data: T) -> Response<T> {
    return Response<T>(isSuccessful: true, data: data, error: nil)
  }
  
  static func failure(of type: Response<String>.Error.ErrorType, message: String? = nil, fatal: Bool? = nil) -> Response<String> {
    return Response<String>(isSuccessful: false, data: nil, error: Response.Error(type: type, message: message, fatal: fatal))
  }
}
