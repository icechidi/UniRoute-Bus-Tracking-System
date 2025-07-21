# uniroute home_screen setup
1. Firstly the required dependencies to the pubspec.yaml file

   dependencies:
    flutter:
        sdk: flutter
    google_maps_flutter: ^2.5.3  # Or latest version
    location: ^5.0.3
    geolocator: ^11.0.0
    http: ^1.2.1
    flutter_map: ^6.1.0 # For using OpenStreetMap or other tile providers
    latlong2: ^0.9.0  # For handling latitude and longitude
    device_preview: ^1.3.1 # For device preview functionality
2. run the command -> flutter pub get <- to download the required dependencies