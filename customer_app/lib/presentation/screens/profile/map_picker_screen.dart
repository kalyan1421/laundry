// lib/presentation/screens/profile/map_picker_screen.dart
import 'dart:async';
import 'package:customer_app/services/location_service.dart';
import 'package:customer_app/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class MapPickerScreen extends StatefulWidget {
  final Position? initialPosition;

  const MapPickerScreen({super.key, this.initialPosition});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  late GoogleMapController _mapController;
  final TextEditingController _searchController = TextEditingController();

  late LatLng _centerPosition;
  bool _isLoading = false;
  bool _isGettingLocation = false;
  String _currentAddress = 'Move the map to select location';

  @override
  void initState() {
    super.initState();
    _centerPosition = (widget.initialPosition != null)
        ? LatLng(
            widget.initialPosition!.latitude, widget.initialPosition!.longitude)
        : const LatLng(13.0827, 80.2707); // Default to Chennai if null
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
    _mapController = controller;
  }

  void _onCameraMove(CameraPosition position) {
    _centerPosition = position.target;
  }

  Future<void> _onCameraIdle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _centerPosition.latitude,
        _centerPosition.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        setState(() {
          _currentAddress =
              '${placemark.name}, ${placemark.street}, ${placemark.locality}, ${placemark.postalCode}';
        });
      }
    } catch (e) {
      print("Error getting address: $e");
      setState(() {
        _currentAddress = "Could not get address for this location";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _confirmSelection() async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _centerPosition.latitude,
        _centerPosition.longitude,
      );
      if (placemarks.isNotEmpty && mounted) {
        Navigator.of(context).pop({
          'placemark': placemarks.first,
          'position': _centerPosition,
        });
      }
    } catch (e) {
      print("Error on confirm: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not confirm location. Please try again.')),
        );
      }
    }
  }

  Future<void> _goToCurrentUserLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      final Position position = await LocationService.getCurrentLocation();
      _mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 17.0,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not get current location: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  Future<void> _showLocationSelection(List<Location> locations) async {
    final List<Placemark> placemarks = [];
    for (final location in locations) {
      try {
        final p = await placemarkFromCoordinates(
            location.latitude, location.longitude);
        if (p.isNotEmpty) {
          placemarks.add(p.first);
        }
      } catch (e) {
        print('Error reverse geocoding: $e');
      }
    }

    if (!mounted || placemarks.isEmpty) return;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount: placemarks.length,
          itemBuilder: (context, index) {
            final placemark = placemarks[index];
            final address =
                '${placemark.name}, ${placemark.street}, ${placemark.locality}, ${placemark.postalCode}';
            return ListTile(
              title: Text(placemark.name ?? 'Unknown Location'),
              subtitle: Text(address),
              onTap: () {
                Navigator.pop(context);
                _animateToLocation(
                  LatLng(locations[index].latitude, locations[index].longitude),
                );
              },
            );
          },
        );
      },
    );
  }

  void _animateToLocation(LatLng latLng) {
    _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: latLng,
          zoom: 17.0,
        ),
      ),
    );
  }

  Future<void> _searchLocation(String address) async {
    if (address.isEmpty) return;

    FocusScope.of(context).unfocus(); // Hide keyboard
    setState(() {
      _isLoading = true;
    });

    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty && mounted) {
        if (locations.length == 1) {
          _animateToLocation(
              LatLng(locations.first.latitude, locations.first.longitude));
        } else {
          _showLocationSelection(locations);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location not found.')),
          );
        }
      }
    } catch (e) {
      print("Error searching location: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching for location: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location on Map'),
        elevation: 1,
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 150.0),
        child: FloatingActionButton(
          onPressed: _goToCurrentUserLocation,
          backgroundColor: context.surfaceColor,
          child: _isGettingLocation
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 3),
                )
              : Icon(Icons.my_location, color: context.onSurfaceColor),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _centerPosition,
              zoom: 16.0,
            ),
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            myLocationEnabled: true, // Keeps the blue dot visible
            myLocationButtonEnabled: false, // We use our own button
            zoomControlsEnabled: false,
          ),
          Center(
            child: Transform.translate(
              offset: const Offset(0, -25), // Move icon up by half its height
              child: const Icon(
                Icons.location_pin,
                size: 50,
                color: Colors.red,
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Material(
              borderRadius: BorderRadius.circular(30),
              elevation: 4,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search for a location...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      FocusScope.of(context).unfocus();
                    },
                  ),
                  filled: true,
                  fillColor: context.surfaceColor,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: context.primaryColor),
                  ),
                ),
                onSubmitted: _searchLocation,
                textInputAction: TextInputAction.search,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1), blurRadius: 10)
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _isLoading
                      ? const LinearProgressIndicator()
                      : Text(_currentAddress, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _confirmSelection,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryColor,
                        foregroundColor: context.onPrimaryContainer,
                        minimumSize: const Size(double.infinity, 50)),
                    child: const Text('Confirm Location'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
