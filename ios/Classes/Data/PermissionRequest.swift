//
//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0
//

import Foundation

struct PermissionRequest: Codable {
  let value: Permission
  let openSettingsIfDenied: Bool
}
