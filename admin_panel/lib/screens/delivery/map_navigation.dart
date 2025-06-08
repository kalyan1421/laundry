// screens/delivery/map_navigation.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // No longer directly using GeoPoint from Firestore here
import 'package:url_launcher/url_launcher.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
// import '../../services/location_service.dart'; // Assuming LocationService might not be needed if we geocode here

class MapNavigation extends StatefulWidget {
  // Changed to accept string addresses
  final String? pickupAddress;
  final String? deliveryAddress;

  const MapNavigation({
    super.key,
    required this.pickupAddress,
    required this.deliveryAddress,
  });

  @override
  State<MapNavigation> createState() => _MapNavigationState();
}

class _MapNavigationState extends State<MapNavigation> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _showingPickup = true;

  LatLng? _pickupLatLng;
  LatLng? _deliveryLatLng;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _geocodeAddresses();
  }

  Future<void> _geocodeAddresses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      if (widget.pickupAddress != null && widget.pickupAddress!.isNotEmpty) {
        List<geocoding.Location> pickupLocations = await geocoding.locationFromAddress(widget.pickupAddress!);
        if (pickupLocations.isNotEmpty) {
          _pickupLatLng = LatLng(pickupLocations.first.latitude, pickupLocations.first.longitude);
        }
      }

      if (widget.deliveryAddress != null && widget.deliveryAddress!.isNotEmpty) {
        List<geocoding.Location> deliveryLocations = await geocoding.locationFromAddress(widget.deliveryAddress!);
        if (deliveryLocations.isNotEmpty) {
          _deliveryLatLng = LatLng(deliveryLocations.first.latitude, deliveryLocations.first.longitude);
        }
      }

      if (_pickupLatLng == null && _deliveryLatLng == null) {
        _errorMessage = 'Could not find coordinates for pickup or delivery address.';
      } else if (_pickupLatLng == null) {
        _errorMessage = 'Could not find coordinates for pickup address.';
      } else if (_deliveryLatLng == null) {
        _errorMessage = 'Could not find coordinates for delivery address.';
      }

      if (_errorMessage == null) {
        _setMarkersAndPolylines();
      }

    } catch (e) {
      print("Geocoding error: $e");
      _errorMessage = "Failed to geocode addresses. Please try again.";
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _setMarkersAndPolylines() {
    _markers.clear();
    _polylines.clear();

    if (_pickupLatLng != null) {
      _markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: _pickupLatLng!,
        infoWindow: InfoWindow(title: 'Pickup: ${widget.pickupAddress ?? "N/A"}'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ));
    }

    if (_deliveryLatLng != null) {
      _markers.add(Marker(
        markerId: const MarkerId('delivery'),
        position: _deliveryLatLng!,
        infoWindow: InfoWindow(title: 'Delivery: ${widget.deliveryAddress ?? "N/A"}'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
    }

    if (_pickupLatLng != null && _deliveryLatLng != null) {
      _polylines.add(Polyline(
        polylineId: const PolylineId('route'),
        points: [_pickupLatLng!, _deliveryLatLng!],
        color: Colors.blue,
        width: 3,
      ));
    }
    // Determine initial camera target
    // If only one point is available, target that. If both, target pickup. If none, target a default.
    _initialCameraTarget = _pickupLatLng ?? _deliveryLatLng ?? const LatLng(20.5937, 78.9629); // Default to India center

    setState(() {}); // Update UI with markers and polylines
  }
  
  LatLng _initialCameraTarget = const LatLng(20.5937, 78.9629); // Default center of India

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading Map...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Navigation Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(_errorMessage!, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation'),
        actions: [
          if (_pickupLatLng != null || _deliveryLatLng != null) // Only show if we have a point to navigate to
            IconButton(
              icon: const Icon(Icons.navigation),
              onPressed: _openGoogleMaps,
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialCameraTarget, // Use the determined initial target
              zoom: 14,
            ),
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (controller) {
              _mapController = controller;
               // Animate to bounds if both points are available
              if (_pickupLatLng != null && _deliveryLatLng != null) {
                LatLngBounds bounds = LatLngBounds(
                  southwest: LatLng(
                    _pickupLatLng!.latitude < _deliveryLatLng!.latitude ? _pickupLatLng!.latitude : _deliveryLatLng!.latitude,
                    _pickupLatLng!.longitude < _deliveryLatLng!.longitude ? _pickupLatLng!.longitude : _deliveryLatLng!.longitude,
                  ),
                  northeast: LatLng(
                    _pickupLatLng!.latitude > _deliveryLatLng!.latitude ? _pickupLatLng!.latitude : _deliveryLatLng!.latitude,
                    _pickupLatLng!.longitude > _deliveryLatLng!.longitude ? _pickupLatLng!.longitude : _deliveryLatLng!.longitude,
                  ),
                );
                _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50)); // 50 is padding
              } else if (_pickupLatLng != null) {
                 _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_pickupLatLng!, 15));
              } else if (_deliveryLatLng != null) {
                 _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_deliveryLatLng!, 15));
              }
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          if (_pickupLatLng != null || _deliveryLatLng != null) // Show buttons only if points are valid
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Card(
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (_pickupLatLng != null)
                            ElevatedButton.icon(
                              onPressed: () {
                                _showingPickup = true;
                                _animateToLocation(_pickupLatLng!);
                              },
                              icon: const Icon(Icons.location_on),
                              label: const Text('Pickup'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _showingPickup ? Colors.blue : Colors.grey,
                              ),
                            ),
                          if (_deliveryLatLng != null)
                            ElevatedButton.icon(
                              onPressed: () {
                                _showingPickup = false;
                                _animateToLocation(_deliveryLatLng!);
                              },
                              icon: const Icon(Icons.flag),
                              label: const Text('Delivery'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: !_showingPickup && _pickupLatLng != null ? Colors.green : (_pickupLatLng == null ? Colors.green : Colors.grey) ,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _openGoogleMaps,
                          icon: const Icon(Icons.directions),
                          label: const Text('Open in Google Maps'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _animateToLocation(LatLng location) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(location, 16),
    );
  }

  Future<void> _openGoogleMaps() async {
    LatLng? targetLocation;
    if (_showingPickup && _pickupLatLng != null) {
      targetLocation = _pickupLatLng;
    } else if (!_showingPickup && _deliveryLatLng != null) {
      targetLocation = _deliveryLatLng;
    } else {
      // Fallback if current selection is null but other exists
      targetLocation = _pickupLatLng ?? _deliveryLatLng;
    }

    if (targetLocation == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No location selected or available to navigate.')),
        );
      }
      return;
    }

    final url = 'https://www.google.com/maps/dir/?api=1&destination=${targetLocation.latitude},${targetLocation.longitude}';
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
        );
      }
    }
  }
}