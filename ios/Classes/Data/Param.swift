//
//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0
//

import Foundation

struct LocationUpdateParam: Codable {
  let strategy: Strategy
  let accuracy: Facet
  
  struct Facet: Codable {
    let ios: Accuracy
  }
  
  enum Strategy: String, Codable {
    case current = "current"
    case single = "single"
    case continuous = "continuous"
  }
}
