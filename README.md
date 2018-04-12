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
  geolocation: ^0.2.0
```

**Note:** There is a known issue for integrating swift written plugin into Flutter project created with Objective-C template.
See issue [Flutter#16049](https://github.com/flutter/flutter/issues/16049) for help on integration. 


### Permission

Android and iOS require to declare the location permission in a configuration file. 

#### For iOS

There are two kinds of location permission available in iOS: "when in use" (only when app is in foreground) and "always" (foreground and background).
You must specify the description for the desired permission in `Info.plist`.

**For iOS 9/10**: `NSLocationWhenInUseUsageDescription` or `NSLocationAlwaysUsageDescription`

**For iOS 11+**: `NSLocationAlwaysAndWhenInUseUsageDescription` or `NSLocationWhenInUseUsageDescription`

Geolocation automatically requests the associated permission at runtime, based on the content of `Infos.plist`.

### For Android

There are two kinds of location permission in Android: "coarse" and "fine".
Coarse location will allow to get approximate location based on sensors like the Wifi, while fine location returns the most accurate location using GPS (in addition to coarse).

You need to declare one of the two permissions in `AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
  <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
  <!-- or -->
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
</manifest>
``` 
  
Note that `ACCESS_FINE_LOCATION` permission includes `ACCESS_COARSE_LOCATION`.

### Runtime request

On Android (api 23+) and iOS, apps need to request permission at runtime.
Geolocation plugin handles this automatically. 
If the user denies location permission, location result will return an error of type `GeolocationResultErrorType.permissionDenied`.

Alternatively you can also manually check and request location permission.
This might be useful if you want to ask the location permission beforehand, during an onboarding flow for instance.

### Check if location service is operational

```dart
final GeolocationResult result = await Geolocation.isLocationOperational;
if(result.isSuccessful) {
  // location service is enabled, and location permission is granted
} else {
  // location service is not enabled, restricted, or location permission is denied
}
``` 

### Request location permission

_Note: You are not required to request permission manually. 
Geolocation plugin will request permission automatically if it's necessarily, when you make a location request._   

```dart
final GeolocationResult result = await Geolocation.requestLocationPermission();
if(result.isSuccessful) {
  // location permission is granted (or was already granted before making the request)
} else {
  // location permission is not granted
  // user might have denied, but it's also possible that location service is not enabled, restricted, and user never saw the permission request dialog 
}
``` 


## Location API

### Get the last known location

See api documentation: [link]

```dart
final LocationResult result = await Geolocation.lastKnownLocation;
if(result.isSuccessful) {
  print('lat: ${result.location.latitude}');
}
```


### Get the current location

See api documentation: https://pub.dartlang.org/documentation/geolocation/

```dart
LocationResult result = await Geolocation.currentLocation(LocationAccuracy.best);
```


### Get a single location update

See api documentation: https://pub.dartlang.org/documentation/geolocation/

```dart
LocationResult result = await Geolocation.singleLocationUpdate(LocationAccuracy.best);
```


### Result

All location API return a `LocationResult` future.

```dart
final LocationResult result = await Geolocation.lastKnownLocation;

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
