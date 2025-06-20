import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer_app/presentation/providers/auth_provider.dart';
import 'package:customer_app/presentation/providers/address_provider.dart';
import 'package:customer_app/data/models/address_model.dart';
import 'package:customer_app/core/theme/app_colors.dart';
import 'package:customer_app/core/theme/app_text_theme.dart';

class ManageAddressesScreen extends StatefulWidget {
  const ManageAddressesScreen({super.key});

  @override
  State<ManageAddressesScreen> createState() => _ManageAddressesScreenState();
}

class _ManageAddressesScreenState extends State<ManageAddressesScreen> {
  List<DocumentSnapshot> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.userModel != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('customer')
            .doc(authProvider.userModel!.uid)
            .collection('addresses')
            .orderBy('createdAt', descending: true)
            .get();

        setState(() {
          _addresses = snapshot.docs;
        });
      }
    } catch (e) {
      print('Error loading addresses: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading addresses: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testCoordinateSaving() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    try {
      // Test coordinates - San Francisco coordinates
      const double testLat = 37.7749;
      const double testLng = -122.4194;
      
      print('🧪 TEST: Saving test coordinates...');
      print('🧪 TEST: Latitude: $testLat (Type: ${testLat.runtimeType})');
      print('🧪 TEST: Longitude: $testLng (Type: ${testLng.runtimeType})');

      final testAddressData = {
        'type': 'test',
        'addressLine1': 'Test Address Line 1',
        'addressLine2': 'Test Address Line 2',
        'city': 'Test City',
        'state': 'Test State',
        'pincode': '123456',
        'landmark': 'Test Landmark',
        'latitude': testLat,
        'longitude': testLng,
        'isPrimary': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isTestData': true, // Flag to identify test data
      };

      print('🧪 TEST: Saving to Firestore...');
      final docRef = await FirebaseFirestore.instance
          .collection('customer')
          .doc(authProvider.userModel!.uid)
          .collection('addresses')
          .add(testAddressData);

      print('🧪 TEST: Document saved with ID: ${docRef.id}');

      // Verify the saved data
      final savedDoc = await docRef.get();
      if (savedDoc.exists) {
        final savedData = savedDoc.data() as Map<String, dynamic>;
        print('🧪 TEST: Verification - Saved latitude: ${savedData['latitude']} (Type: ${savedData['latitude'].runtimeType})');
        print('🧪 TEST: Verification - Saved longitude: ${savedData['longitude']} (Type: ${savedData['longitude'].runtimeType})');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test coordinates saved successfully!\nLat: ${savedData['latitude']}\nLng: ${savedData['longitude']}'),
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        print('🧪 TEST: ERROR - Document not found after saving');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Document not found after saving')),
        );
      }

      // Refresh the address list
      _loadAddresses();

    } catch (e) {
      print('🧪 TEST: ERROR - Exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving test coordinates: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Addresses'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _testCoordinateSaving,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAddresses,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No addresses found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Complete your profile setup to add addresses',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _addresses.length,
                  itemBuilder: (context, index) {
                    final addressDoc = _addresses[index];
                    final addressData = addressDoc.data() as Map<String, dynamic>;
                    return _buildAddressCard(addressData, addressDoc.id);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add-address').then((_) {
            _loadAddresses();
          });
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAddressCard(Map<String, dynamic> addressData, String addressId) {
    final latitude = addressData['latitude'];
    final longitude = addressData['longitude'];
    final hasCoordinates = latitude != null && longitude != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Address Type and Primary Status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    addressData['type']?.toString().toUpperCase() ?? 'HOME',
                    style: AppTextTheme.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (addressData['isPrimary'] == true) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'PRIMARY',
                      style: AppTextTheme.bodySmall.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                if (addressData['isTestData'] == true) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'TEST',
                      style: AppTextTheme.bodySmall.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Address Lines
            if (addressData['addressLine1']?.toString().isNotEmpty == true)
              Text(
                addressData['addressLine1'].toString(),
                style: AppTextTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500),
              ),
            if (addressData['addressLine2']?.toString().isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                addressData['addressLine2'].toString(),
                style: AppTextTheme.bodySmall.copyWith(color: Colors.grey[600]),
              ),
            ],

            // City, State, Pincode
            const SizedBox(height: 8),
            Row(
              children: [
                if (addressData['city']?.toString().isNotEmpty == true)
                  Text(
                    addressData['city'].toString(),
                    style: AppTextTheme.bodySmall.copyWith(fontWeight: FontWeight.w500),
                  ),
                if (addressData['state']?.toString().isNotEmpty == true) ...[
                  const Text(', '),
                  Text(
                    addressData['state'].toString(),
                    style: AppTextTheme.bodySmall.copyWith(fontWeight: FontWeight.w500),
                  ),
                ],
                if (addressData['pincode']?.toString().isNotEmpty == true) ...[
                  const Text(' - '),
                  Text(
                    addressData['pincode'].toString(),
                    style: AppTextTheme.bodySmall.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),

            // Landmark
            if (addressData['landmark']?.toString().isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                'Near: ${addressData['landmark']}',
                style: AppTextTheme.bodySmall.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            // Coordinates Debug Info
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hasCoordinates ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: hasCoordinates ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        hasCoordinates ? Icons.location_on : Icons.location_off,
                        size: 16,
                        color: hasCoordinates ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'GPS Coordinates',
                        style: AppTextTheme.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: hasCoordinates ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (hasCoordinates) ...[
                    Text(
                      'Lat: ${latitude.toString()}',
                      style: AppTextTheme.bodySmall.copyWith(fontFamily: 'monospace'),
                    ),
                    Text(
                      'Lng: ${longitude.toString()}',
                      style: AppTextTheme.bodySmall.copyWith(fontFamily: 'monospace'),
                    ),
                    Text(
                      'Type: ${latitude.runtimeType} / ${longitude.runtimeType}',
                      style: AppTextTheme.bodySmall.copyWith(
                        fontFamily: 'monospace',
                        color: Colors.grey[600],
                      ),
                    ),
                  ] else
                    Text(
                      'No coordinates saved',
                      style: AppTextTheme.bodySmall.copyWith(color: Colors.red),
                    ),
                ],
              ),
            ),

            // Timestamps
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Created: ${_formatTimestamp(addressData['createdAt'])}',
                  style: AppTextTheme.bodySmall.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    
    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else {
        return timestamp.toString();
      }
      
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }
} 