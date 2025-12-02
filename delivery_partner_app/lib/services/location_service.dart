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

  // 1. Initialize and Check Permissions
  Future<bool> initialize() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('📍 LocationService: Location services are disabled');
        // Try to open location settings
        await Geolocator.openLocationSettings();
        return false;
      }

      // Check and request permissions
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
        await Geolocator.openAppSettings();
        return false;
      }

      print('📍 LocationService: Permissions granted');
      return true;
    } catch (e) {
      print('📍 LocationService: Error initializing: $e');
      return false;
    }
  }

  // 2. Start "Work Mode" (Online)
  Future<void> goOnline(String driverId) async {
    if (_isTracking) {
      print('📍 LocationService: Already tracking location');
      return;
    }

    try {
      // Set Database Status to ONLINE
      await _firestore.collection('delivery').doc(driverId).update({
        'isOnline': true,
        'isAvailable': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });

      // Get initial position
      try {
        final Position initialPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        
        // Update initial location
        await _firestore.collection('delivery').doc(driverId).update({
          'currentLocation': GeoPoint(initialPosition.latitude, initialPosition.longitude),
          'heading': initialPosition.heading,
          'speed': initialPosition.speed,
          'lastLocationUpdate': FieldValue.serverTimestamp(),
        });
        print('📍 LocationService: Initial location updated');
      } catch (e) {
        print('📍 LocationService: Error getting initial position: $e');
      }

      // Configure location settings for continuous updates
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // Update every 50 meters
      );

      // Start Streaming Location to Firestore
      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          print("📍 Updating Location: ${position.latitude}, ${position.longitude}");
          
          _firestore.collection('delivery').doc(driverId).update({
            'currentLocation': GeoPoint(position.latitude, position.longitude),
            'heading': position.heading,
            'speed': position.speed,
            'lastLocationUpdate': FieldValue.serverTimestamp(),
          }).catchError((e) => print("📍 LocationService: Error updating location: $e"));
        },
        onError: (error) {
          print('📍 LocationService: Error in location stream: $error');
        },
      );

      _isTracking = true;
      print('📍 LocationService: Started tracking for driver: $driverId');
    } catch (e) {
      print('📍 LocationService: Error going online: $e');
      rethrow;
    }
  }

  // 3. Stop "Work Mode" (Offline)
  Future<void> goOffline(String driverId) async {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _isTracking = false;
    
    // Set Database Status to OFFLINE
    await _firestore.collection('delivery').doc(driverId).update({
      'isOnline': false,
      'isAvailable': false,
      'lastSeen': FieldValue.serverTimestamp(),
    });

    print('📍 LocationService: Stopped tracking - driver is offline');
  }

  /// Check Firebase for current online status
  Future<bool> checkCurrentStatus(String driverId) async {
    try {
      final doc = await _firestore.collection('delivery').doc(driverId).get();
      if (doc.exists) {
        return doc.data()?['isOnline'] ?? false;
      }
    } catch (e) {
      print("📍 LocationService: Error checking status: $e");
    }
    return false;
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
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _isTracking = false;
  }
}
