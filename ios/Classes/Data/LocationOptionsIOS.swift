import Foundation

struct LocationOptionsIOS : Codable {
  let showsBackgroundLocationIndicator: Bool
  let activityType: LocationActivityIOS

  enum LocationActivityIOS: String, Codable {
    case other = "other"
    case automotiveNavigation = "automotiveNavigation"
    case fitness = "fitness"
    case otherNavigation = "otherNavigation"
  }
}
