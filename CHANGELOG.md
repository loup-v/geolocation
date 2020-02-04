## [1.1.0]

- **Breaking change :** `Geolocation.requestLocationPermission` now takes a named parameter for permission
- **Breaking change :** New `GeolocationResultErrorType.permissionNotGranted` type. Previous meaning for `permissionDenied` is now divided in two different states:
  - `permissionNotGranted`: User didn't accept nor decline the locationn permission request yet
  - `permissionDenied`: User specifically declined the permission request
- Ability to open settings when requesting permission, and user already declined the permission previously: `Geolocation.requestLocationPermission(openSettingsIfDenied: true)` (opening the settings as fallback is now the default behaviour).
- Fix background pause/resume on iOS
- Refactor iOS internal structure

## [1.0.2]

- Fix `Accuracy.nearestTenMeters` on iOS

## [1.0.1]

- Update to streams_channel 0.2.3

## [1.0.0] (thanks @alfanhui)

- Updated Kotlin to 1.3.41
- Updated Kotlin experimental coroutines to Kotlinx
- Updated Android packages to Androidx (hence major release increment)

## [0.2.3] (thanks @alfanhui)

- Added updated pubspec description
- Flutter format on number of files

## [0.2.2] (thanks @alfanhui)

- Better encoding of 'options' on LocationUpdatesRequest [hoggetaylor]
- Fix argument of type string can not be assigned to DiagnosticsNode [osamagamal65]
- Adding support for new method to request enabling location services [shehabic]
- Updated Readme [shehabic]
- Various fixes for XCode 10, and Cocoa Pods 1.5.3 [shehabic]
- Updated Google Play Services Version [shehabic]
- Fixed serialization from dart to native platforms [shehabic]
- Updated kotlin version [shehabic]

## [0.2.1]

- Replace `requestPermission(permission)` named parameter by positional

## [0.2.0]

- Refactor single one-shot location
- Refactor permission management
- Add continuous location updates support
- Add in background support for location updates
- Add request location permission manually
- Add pause/resume location updates automatically when app goes to background/foreground
- Add Stream API
- Fix: Match play-services version to Flutter's firebase plugins
- Fix: Dart 1.x compatibility

## [0.1.1]

- Pubspec and documentation fixes

## [0.1.0] - Initial release

- New feature: Last known location
- New feature: Current location
- New feature: Location updates
