//
//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0
//

import Foundation

struct Codec {
  private static let jsonEncoder = JSONEncoder()
  private static let jsonDecoder = JSONDecoder()
  
  static func encode<T>(result: Result<T>) -> String {
    return String(data: try! jsonEncoder.encode(result), encoding: .utf8)!
  }
  
  static func decodeInt(from arguments: Any?) -> Int {
    return arguments as! Int
  }
  
  static func decodePermission(from arguments: Any?) -> Permission {
    return Permission(rawValue: arguments! as! String)!
  }
  
  static func decodeLocationUpdatesRequest(from arguments: Any?) -> LocationUpdatesRequest {
    return try! jsonDecoder.decode(LocationUpdatesRequest.self, from: (arguments as! String).data(using: .utf8)!)
  }
}
