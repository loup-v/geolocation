//
//  Param.swift
//  geolocation
//
//  Created by Lukasz on 31/03/2018.
//

import Foundation

struct SingleLocationParam: Codable {
  let accuracy: Facet
  
  struct Facet: Codable {
    let ios: Accuracy
  }
}
