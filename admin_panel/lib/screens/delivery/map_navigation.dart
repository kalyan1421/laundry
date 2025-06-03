// screens/delivery/map_navigation.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/location_service.dart';

class MapNavigation extends StatefulWidget {
  final GeoPoint pickupLocation;
  final GeoPoint deliveryLocation;

  const MapNavigation({
    super.key,
    required this.pickupLocation,
    required this.deliveryLocation,
  });

  @override
  State<MapNavigation> createState() => _MapNavigationState();
}

class _MapNavigationState extends State<MapNavigation> {
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _showingPickup = true;

  @override
  void initState() {
    super.initState();
    _setMarkers();
  }

  void _setMarkers() {
    _markers = {
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(
          widget.pickupLocation.latitude,
          widget.pickupLocation.longitude,
        ),
        infoWindow: const InfoWindow(title: 'Pickup Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
      Marker(
        markerId: const MarkerId('delivery'),
        position: LatLng(
          widget.deliveryLocation.latitude,
          widget.deliveryLocation.longitude,
        ),
        infoWindow: const InfoWindow(title: 'Delivery Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    };

    // Add polyline between pickup and delivery
    _polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: [
          LatLng(widget.pickupLocation.latitude, widget.pickupLocation.longitude),
          LatLng(widget.deliveryLocation.latitude, widget.deliveryLocation.longitude),
        ],
        color: Colors.blue,
        width: 3,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation'),
        actions: [
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
              target: LatLng(
                widget.pickupLocation.latitude,
                widget.pickupLocation.longitude,
              ),
              zoom: 14,
            ),
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
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
                        ElevatedButton.icon(
                          onPressed: () {
                            _showingPickup = true;
                            _animateToLocation(widget.pickupLocation);
                          },
                          icon: const Icon(Icons.location_on),
                          label: const Text('Pickup'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _showingPickup ? Colors.blue : Colors.grey,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            _showingPickup = false;
                            _animateToLocation(widget.deliveryLocation);
                          },
                          icon: const Icon(Icons.flag),
                          label: const Text('Delivery'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: !_showingPickup ? Colors.green : Colors.grey,
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

  void _animateToLocation(GeoPoint location) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(location.latitude, location.longitude),
        16,
      ),
    );
  }

  Future<void> _openGoogleMaps() async {
    final location = _showingPickup ? widget.pickupLocation : widget.deliveryLocation;
    final url = 'https://www.google.com/maps/dir/?api=1&destination=${location.latitude},${location.longitude}';
    
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