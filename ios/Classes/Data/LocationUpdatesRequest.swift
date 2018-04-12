//
//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0
//

import Foundation

struct LocationUpdatesRequest: Codable {
  let id: Int
  
  let strategy: Strategy
  let permission: Permission
  let accuracy: Accuracy
  let displacementFilter: Double
  let inBackground: Bool
  
  enum Strategy: String, Codable {
    case current = "current"
    case single = "single"
    case continuous = "continuous"
  }
}
