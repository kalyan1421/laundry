// services/location_service.dart - Background Location Tracking for Delivery Partners
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  StreamSubscription<Position>? _locationSubscription;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isTracking = false;

  /// Check if location tracking is currently active
  bool get isTracking => _isTracking;

  /// Start tracking and updating Firestore with driver's location
  Future<bool> startLocationTracking(String driverId) async {
    if (_isTracking) {
      print('📍 LocationService: Already tracking location');
      return true;
    }

    try {
      // 1. Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('📍 LocationService: Location services are disabled');
        // Prompt user to enable location services
        return false;
      }

      // 2. Check and request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('📍 LocationService: Location permission denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('📍 LocationService: Location permission permanently denied');
        // User needs to enable permissions from settings
        return false;
      }

      // 3. Configure location settings (Battery efficient)
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // Update every 50 meters
      );

      // 4. Get initial position and update Firestore
      try {
        final Position initialPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        await _updateLocationInFirestore(driverId, initialPosition);
        print('📍 LocationService: Initial location updated');
      } catch (e) {
        print('📍 LocationService: Error getting initial position: $e');
      }

      // 5. Listen to location changes and update Firestore
      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          _updateLocationInFirestore(driverId, position);
        },
        onError: (error) {
          print('📍 LocationService: Error in location stream: $error');
        },
      );

      _isTracking = true;
      print('📍 LocationService: Started tracking for driver: $driverId');
      return true;
    } catch (e) {
      print('📍 LocationService: Error starting location tracking: $e');
      return false;
    }
  }

  /// Update driver's location in Firestore
  Future<void> _updateLocationInFirestore(String driverId, Position position) async {
    try {
      await _firestore.collection('delivery').doc(driverId).update({
        'currentLocation': GeoPoint(position.latitude, position.longitude),
        'lastLocationUpdate': FieldValue.serverTimestamp(),
        'isOnline': true,
        'isAvailable': true, // Required for order assignment
        'locationAccuracy': position.accuracy,
        'locationSpeed': position.speed,
        'locationHeading': position.heading,
      });
      print('📍 LocationService: Updated location - Lat: ${position.latitude}, Lng: ${position.longitude}');
    } catch (e) {
      print('📍 LocationService: Error updating location in Firestore: $e');
    }
  }

  /// Stop location tracking
  void stopLocationTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _isTracking = false;
    print('📍 LocationService: Stopped tracking');
  }

  /// Mark driver as offline when app closes
  Future<void> markDriverOffline(String driverId) async {
    try {
      await _firestore.collection('delivery').doc(driverId).update({
        'isOnline': false,
        'isAvailable': false, // Not available for orders when offline
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });
      print('📍 LocationService: Marked driver as offline');
    } catch (e) {
      print('📍 LocationService: Error marking driver offline: $e');
    }
  }

  /// Open app settings (for users who permanently denied permission)
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Open location settings (for users who disabled location services)
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Dispose of resources
  void dispose() {
    stopLocationTracking();
  }
}


