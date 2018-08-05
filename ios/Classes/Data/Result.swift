//
//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0
//

import Foundation

struct Result : Encodable {
  let isSuccessful: Bool
  let data: AnyEncodable?
  let error: ResultError?
  let additionalInfo: AnyEncodable?
  
  static func success (with data: AnyEncodable) -> Result {
    return Result(isSuccessful: true, data: data, error: nil)
  }
  
  static func failure (of type: ResultError.Kind, message: String? = nil, fatal: Bool? = nil) -> Result {
    return Result(isSuccessful: false, data: nil, error: ResultError(type: type, message: message, fatal: fatal))
  }
}

struct ResultError: Codable {
  let type: Kind
  let message: String?
  let fatal: Bool?
  
  enum Kind: String, Codable {
    case runtime = "runtime"
    case locationNotFound = "locationNotFound"
    case permissionDenied = "permissionDenied"
    case serviceDisabled = "serviceDisabled"
  }
}


