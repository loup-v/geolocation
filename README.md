# Geolocation

Flutter geolocation plugin working on Android API 16+ and iOS 9+.  

Features:

* Automatically request location permission
* Retrieve current device location
* Listen to location changes
* Common API with different logic under the hood for iOS and Android, in order to follow best practices on both platforms 

The plugin is under active development and the following features are planned soon:

* Foreground and background strategies for location changes
* Geocode
* Geofences
* Place suggestions
* Activity recognition


Android | iOS
:---: | :---:
![](https://github.com/loup-v/geolocation/blob/master/doc/android_screenshot.jpg?raw=true) | ![](https://github.com/loup-v/geolocation/blob/master/doc/ios_screenshot.jpg?raw=true)


## Installation

Add geolocation to your pubspec.yaml:

```yaml
dependencies:
  geolocation: ^0.1.1
```

**Note:** There is a known issue for integrating swift written plugin into Flutter project created with Objective-C template.
See [#16049](https://github.com/flutter/flutter/issues/16049) for help on integration. 


## Permission

Apps need to declare the location usage in configuration file and request it at runtime.
Geolocation plugin automatically checks at runtime if the configuration is correct.
In case you forget, the plugin will throw a shiny exception to get you notified ASAP. 

### iOS configuration

There are two kinds of location permission in iOS: "when in use" and "always".
You will request one or another depending if the app requires to use location while being in background.
You need to specify the description for the desired permission in `Infos.plist`.

**When targeting iOS 9/10**: `NSLocationWhenInUseUsageDescription` or `NSLocationAlwaysUsageDescription`

**When targeting iOS 11+**: `NSLocationAlwaysAndWhenInUseUsageDescription` or `NSLocationWhenInUseUsageDescription`

Geolocation automatically requests the associated permission at runtime, based on the content of `Infos.plist`.

### Android configuration

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

See api documentation: [link]

```dart
LocationResult result = await Geolocation.currentLocation(LocationAccuracy.best);
```


### Get a single location update

See api documentation: [link]

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
