# Geolocation

[![pub package](https://img.shields.io/pub/v/geolocation.svg)](https://pub.dartlang.org/packages/geolocation)

Flutter [geolocation plugin](https://pub.dartlang.org/packages/geolocation/) for Android API 16+ and iOS 9+.  

Features:

* Manual and automatic location permission management
* Current one-shot location
* Continuous location updates with foreground and background options

The plugin is under active development and the following features are planned soon:

* Geocode
* Geofences
* Place suggestions
* Activity recognition
* Exposition of iOS/Android specific APIs (like significant location updates on iOS)


Android | iOS
:---: | :---:
![](https://github.com/loup-v/geolocation/blob/master/doc/android_screenshot.jpg?raw=true) | ![](https://github.com/loup-v/geolocation/blob/master/doc/ios_screenshot.jpg?raw=true)


## Installation

Add geolocation to your pubspec.yaml:

```yaml
dependencies:
  geolocation: ^0.2.1
```

**Note:** There is a known issue for integrating swift written plugin into Flutter project created with Objective-C template.
See issue [Flutter#16049](https://github.com/flutter/flutter/issues/16049) for help on integration.


### Permission

Android and iOS require to declare the location permission in a configuration file.

#### For iOS

There are two kinds of location permission available in iOS: "when in use" and "always".

If you don't know what permission to choose for your usage, see:
https://developer.apple.com/documentation/corelocation/choosing_the_authorization_level_for_location_services

You need to declare the description for the desired permission in `ios/Runner/Info.plist`:

```xml
<dict>
  <!-- for iOS 11 + -->
  <key>NSLocationWhenInUseUsageDescription</key>
  <string>Reason why app needs location</string>
  <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
  <string>Reason why app needs location</string>

  <!-- additionally for iOS 9/10, if you need always permission -->
  <key>NSLocationAlwaysUsageDescription</key>
  <string>Reason why app needs location</string>
  ...
</dict>
```


#### For Android

There are two kinds of location permission in Android: "coarse" and "fine".
Coarse location will allow to get approximate location based on sensors like the Wifi, while fine location returns the most accurate location using GPS (in addition to coarse).

You need to declare one of the two permissions in `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
  <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
  <!-- or -->
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
</manifest>
```

Note that `ACCESS_FINE_LOCATION` permission includes `ACCESS_COARSE_LOCATION`.


## API

For more complete documentation on all usage, check the API documentation:  
https://pub.dartlang.org/documentation/geolocation/0.2.1/geolocation/geolocation-library.html

You can also check the example project that showcase a comprehensive usage of Geolocation plugin.

### Check if location service is operational

API documentation: https://pub.dartlang.org/documentation/geolocation/0.2.1/geolocation/Geolocation/isLocationOperational.html

```dart
final GeolocationResult result = await Geolocation.isLocationOperational();
if(result.isSuccessful) {
  // location service is enabled, and location permission is granted
} else {
  // location service is not enabled, restricted, or location permission is denied
}
```

### Request location permission

On Android (api 23+) and iOS, geolocation needs to request permission at runtime.

_Note: You are not required to request permission manually.
Geolocation plugin will request permission automatically if it's needed, when you make a location request._

API documentation: https://pub.dartlang.org/documentation/geolocation/0.2.1/geolocation/Geolocation/requestLocationPermission.html

```dart
final GeolocationResult result = await Geolocation.requestLocationPermission(const LocationPermission(
  android: LocationPermissionAndroid.fine,
  ios: LocationPermissionIOS.always,
));

if(result.isSuccessful) {
  // location permission is granted (or was already granted before making the request)
} else {
  // location permission is not granted
  // user might have denied, but it's also possible that location service is not enabled, restricted, and user never saw the permission request dialog
}
```


### Get the current one-shot location

Geolocation offers three methods:

* Last known location (best on Android):  
https://pub.dartlang.org/documentation/geolocation/0.2.1/geolocation/Geolocation/lastKnownLocation.html
* Single location update (best on iOS):   
https://pub.dartlang.org/documentation/geolocation/0.2.1/geolocation/Geolocation/singleLocationUpdate.html
* Current location (best of both worlds, tries to retrieve last known location on Android, otherwise requests a single location update):   
https://pub.dartlang.org/documentation/geolocation/0.2.1/geolocation/Geolocation/currentLocation.html


```dart
// best option for most cases
StreamSubscription<LocationResult> subscription = Geolocation.currentLocation(accuracy: LocationAccuracy.best).listen((result) {
  if(result.isSuccessful) {
    Double latitude = result.location.latitude;
    // todo with result
  }
});

// force a single location update
StreamSubscription<LocationResult> subscription = Geolocation.currentLocation(accuracy: LocationAccuracy.best).listen((result) {
  // todo with result
});

// get last known location, which is a future rather than a stream
LocationResult result = await Geolocation.lastKnownLocation();
```


### Continuous location updates

API documentation: https://pub.dartlang.org/documentation/geolocation/0.2.1/geolocation/Geolocation/locationUpdates.html

```dart
StreamSubscription<LocationResult> subscription = Geolocation.locationUpdates(
    accuracy: LocationAccuracy.best,
    displacementFilter: 10.0, // in meters
    inBackground: true, // by default, location updates will pause when app is inactive (in background). Set to `true` to continue updates in background.
  )
  .listen((result) {
    if(result.isSuccessful) {
      // todo with result
    }
  });


// cancelling subscription will also stop the ongoing location request
subscription.cancel();
```


### Handle location result

Location request return either a `LocationResult` future or a stream of `LocationResult`.

API documentation: https://pub.dartlang.org/documentation/geolocation/0.2.1/geolocation/LocationResult-class.html

```dart
LocationResult result = await Geolocation.lastKnownLocation();

if (result.isSuccessful) {
  // location request successful, location is guaranteed to not be null
  double lat = result.location.latitude;
  double lng = result.location.longitude;
} else {
  switch (result.error.type) {
    case GeolocationResultErrorType.runtime:
      // runtime error, check result.error.message
      break;
    case GeolocationResultErrorType.locationNotFound:
      // location request did not return any result
      break;
    case GeolocationResultErrorType.serviceDisabled:
      // location services disabled on device
      // might be that GPS is turned off, or parental control (android)
      break;
    case GeolocationResultErrorType.permissionDenied:
      // user denied location permission request
      // rejection is final on iOS, and can be on Android
      // user will need to manually allow the app from the settings
      break;
    case GeolocationResultErrorType.playServicesUnavailable:
      // android only
      // result.error.additionalInfo contains more details on the play services error
      switch(result.error.additionalInfo as GeolocationAndroidPlayServices) {
        // do something, like showing a dialog inviting the user to install/update play services
        case GeolocationAndroidPlayServices.missing:
        case GeolocationAndroidPlayServices.updating:
        case GeolocationAndroidPlayServices.versionUpdateRequired:
        case GeolocationAndroidPlayServices.disabled:
        case GeolocationAndroidPlayServices.invalid:
      }
    break;
  }
}
```


## Author

Geolocation plugin is developed by Loup, a mobile development studio based in Montreal and Paris.  
You can contact us at <hello@intheloup.io>


## License

Apache License 2.0
