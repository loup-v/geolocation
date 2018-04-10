//
//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0
//

import Foundation

struct LocationUpdatesRequest: Codable {
  let id: Int
  let strategy: Strategy
  let accuracy: Facet
  let displacementFilter: Float
  let inBackground: Bool
  
  struct Facet: Codable {
    let ios: Accuracy
  }
  
  enum Strategy: String, Codable {
    case current = "current"
    case single = "single"
    case continuous = "continuous"
  }
}
