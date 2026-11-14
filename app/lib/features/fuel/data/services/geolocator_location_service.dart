import 'package:geolocator/geolocator.dart';
import 'package:mitlio/features/fuel/data/services/location_service.dart';

/// Device position through `geolocator`, coarse only: low accuracy, no
/// background access. The permission dialog appears inside [current], which
/// is only called after the user tapped "in meiner Nähe".
class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  bool get isSupported => true;

  @override
  Future<LocationResult> current() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      switch (permission) {
        case LocationPermission.deniedForever:
          return const LocationDeniedForever();
        case LocationPermission.denied:
        case LocationPermission.unableToDetermine:
          return const LocationDenied();
        case LocationPermission.whileInUse:
        case LocationPermission.always:
          break;
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationUnavailable();
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return LocationFound(lat: position.latitude, lng: position.longitude);
    } on Object {
      return const LocationUnavailable();
    }
  }
}
