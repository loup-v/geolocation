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
  
  static func decodeLocationUpdateParam(from arugments: Any?) -> LocationUpdateParam {
    return try! jsonDecoder.decode(LocationUpdateParam.self, from: (arugments as! String).data(using: .utf8)!)
  }
}
