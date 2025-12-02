// services/location_service.dart - Background Location Tracking for Delivery Partners
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart';

class LocationService {
  final Location _location = Location();
  StreamSubscription<LocationData>? _locationSubscription;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isTracking = false;

  /// Check if location tracking is currently active
  bool get isTracking => _isTracking;

  // 1. Initialize and Check Permissions
  Future<bool> initialize() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return false;
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return false;
    }
    
    // CRITICAL: Enable background mode so it works when app is closed
    try {
      await _location.enableBackgroundMode(enable: true);
      _location.changeNotificationOptions(
        title: 'You are Online',
        subtitle: 'Searching for nearby orders...',
        iconName: 'ic_launcher', // Ensure this icon exists in android/app/src/main/res/mipmap
      );
    } catch (e) {
      print("📍 LocationService: Error enabling background mode: $e");
    }

    return true;
  }

  // 2. Start "Work Mode" (Online)
  Future<void> goOnline(String driverId) async {
    if (_isTracking) {
      print('📍 LocationService: Already tracking location');
      return;
    }

    // Set Database Status to ONLINE
    await _firestore.collection('delivery').doc(driverId).update({
      'isOnline': true,
      'isAvailable': true,
      'lastSeen': FieldValue.serverTimestamp(),
    });

    // Configure for battery efficiency + accuracy
    await _location.changeSettings(
      accuracy: LocationAccuracy.navigation,
      interval: 10000, // Update every 10 seconds
      distanceFilter: 50, // Update every 50 meters
    );

    // Start Streaming Location to Firestore
    _locationSubscription = _location.onLocationChanged.listen((LocationData currentLocation) {
      if (currentLocation.latitude != null && currentLocation.longitude != null) {
        print("📍 Updating Location: ${currentLocation.latitude}, ${currentLocation.longitude}");
        
        _firestore.collection('delivery').doc(driverId).update({
          'currentLocation': GeoPoint(currentLocation.latitude!, currentLocation.longitude!),
          'heading': currentLocation.heading,
          'speed': currentLocation.speed,
          'lastLocationUpdate': FieldValue.serverTimestamp(),
        }).catchError((e) => print("📍 LocationService: Error updating location: $e"));
      }
    });

    _isTracking = true;
    print('📍 LocationService: Started tracking for driver: $driverId');
  }

  // 3. Stop "Work Mode" (Offline)
  Future<void> goOffline(String driverId) async {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _isTracking = false;
    
    // Disable background mode
    try {
      await _location.enableBackgroundMode(enable: false);
    } catch (e) {
      print("📍 LocationService: Error disabling background mode: $e");
    }
    
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

  /// Dispose of resources
  void dispose() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _isTracking = false;
  }
}
