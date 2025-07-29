// lib/services/location_service.dart
import 'package:geolocator/geolocator.dart';
import '../core/errors/app_exceptions.dart';
import '../data/models/address_model.dart';

class LocationService {
  // Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Check location permission status
  static Future<LocationPermission> checkLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  // Request location permission
  static Future<LocationPermission> requestLocationPermission() async {
    return await Geolocator.requestPermission();
  }

  // Get current location
  static Future<Position> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw LocationException('Location services are disabled. Please enable location services in settings.');
      }

      // Check location permission
      LocationPermission permission = await checkLocationPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestLocationPermission();
        if (permission == LocationPermission.denied) {
          throw LocationException('Location permission denied. Please grant location permission to continue.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw LocationException('Location permissions are permanently denied. Please enable them in app settings.');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      if (e is LocationException) {
        rethrow;
      }
      throw LocationException('Failed to get current location: ${e.toString()}');
    }
  }



  // Calculate distance between two points
  static double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  // Check if location is within service area
  static bool isWithinServiceArea(Position userLocation, List<Position> serviceAreas, double radiusInMeters) {
    for (Position serviceArea in serviceAreas) {
      double distance = calculateDistance(
        userLocation.latitude,
        userLocation.longitude,
        serviceArea.latitude,
        serviceArea.longitude,
      );
      
      if (distance <= radiusInMeters) {
        return true;
      }
    }
    return false;
  }
}