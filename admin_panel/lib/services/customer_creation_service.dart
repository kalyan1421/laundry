import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';
import '../utils/phone_formatter.dart';

class CustomerCreationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Creates a new customer with address and QR code
  Future<Map<String, dynamic>> createCustomerWithAddress({
    required Map<String, String> customerData,
    required Map<String, dynamic> addressData,
  }) async {
    try {
      print('🔧 Starting customer creation process...');
      
      // Generate temporary customer ID
      final tempCustomerId = _firestore.collection('customer').doc().id;
      final phoneNumber = customerData['phoneNumber']!;
      final clientId = PhoneFormatter.getClientId(phoneNumber);
      
      print('🔧 Generated temp customer ID: $tempCustomerId');
      print('🔧 Client ID: $clientId');

      // Generate QR code
      String? qrCodeUrl;
      try {
        qrCodeUrl = await generateQRCode(tempCustomerId, clientId);
        print('🔧 QR code generated: $qrCodeUrl');
      } catch (e) {
        print('⚠️ QR code generation failed: $e');
        // Continue without QR code - not critical for customer creation
      }

      // Prepare customer document data
      final customerDocData = {
        'uid': tempCustomerId, // Temporary ID, will be replaced when user logs in
        'tempId': tempCustomerId, // Store temp ID for later linking
        'name': customerData['name']!,
        'email': customerData['email'] ?? '',
        'phoneNumber': phoneNumber,
        'role': 'customer',
        'isProfileComplete': true,
        'isAdminCreated': true, // Flag to identify admin-created customers
        'authLinked': false, // Flag to track if Firebase Auth is linked
        'clientId': clientId,
        'qrCodeUrl': qrCodeUrl,
        'profileImageUrl': null,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSignIn': null,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': 'admin', // Track who created this customer
      };

      // Create customer document
      await _firestore.collection('customer').doc(tempCustomerId).set(customerDocData);
      print('🔧 Customer document created');

      // Create address subcollection
      await _createCustomerAddress(tempCustomerId, addressData);
      print('🔧 Customer address created');

      return {
        'success': true,
        'customerId': tempCustomerId,
        'clientId': clientId,
        'qrCodeUrl': qrCodeUrl,
      };

    } catch (e, stackTrace) {
      print('❌ Error creating customer: $e');
      print('❌ Stack trace: $stackTrace');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Creates address document in customer's addresses subcollection
  Future<void> _createCustomerAddress(String customerId, Map<String, dynamic> addressData) async {
    try {
      // Generate address document ID
      final addressDocRef = _firestore
          .collection('customer')
          .doc(customerId)
          .collection('addresses')
          .doc();

      // Build complete addressLine1 with door and floor info if available
      List<String> addressParts = [];
      
      final doorNumber = addressData['doorNumber'] as String? ?? '';
      final floorNumber = addressData['floorNumber'] as String? ?? '';
      final addressLine1 = addressData['addressLine1'] as String? ?? '';
      
      if (doorNumber.isNotEmpty) {
        addressParts.add('Door: $doorNumber');
      }
      if (floorNumber.isNotEmpty) {
        addressParts.add('Floor: $floorNumber');
      }
      if (addressLine1.isNotEmpty) {
        addressParts.add(addressLine1);
      }
      
      final completeAddressLine1 = addressParts.join(', ');

      // Prepare address document data
      final addressDocData = {
        'type': addressData['type'] ?? 'home',
        'addressType': addressData['type'] ?? 'home', // For backward compatibility
        'doorNumber': doorNumber,
        'floorNumber': floorNumber,
        'apartmentName': addressData['apartmentName'] ?? '',
        'addressLine1': completeAddressLine1,
        'addressLine2': addressData['addressLine2'] ?? '',
        'city': addressData['city'] ?? '',
        'state': addressData['state'] ?? '',
        'pincode': addressData['pincode'] ?? '',
        'landmark': addressData['landmark'] ?? '',
        'nearbyLandmark': addressData['landmark'] ?? '', // For backward compatibility
        'country': addressData['country'] ?? 'India',
        'latitude': null, // Will be set later if needed
        'longitude': null, // Will be set later if needed
        'isPrimary': addressData['isPrimary'] ?? true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Create the address document
      await addressDocRef.set(addressDocData);
      print('🔧 Address document created with ID: ${addressDocRef.id}');

    } catch (e) {
      print('❌ Error creating customer address: $e');
      throw e;
    }
  }

  /// Generates QR code for customer
  Future<String?> generateQRCode(String customerId, String clientId) async {
    try {
      // Create QR code data with customer information
      Map<String, dynamic> qrData = {
        'type': 'user_profile',
        'customerId': customerId,
        'clientId': clientId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'version': '1.0'
      };

      // Convert to simple string format for QR code
      String qrCodeData = _encodeQRData(qrData);
      
      // Generate QR code image
      Uint8List? qrImageBytes = await _generateQRCodeImage(qrCodeData);
      
      if (qrImageBytes == null) {
        throw Exception('Failed to generate QR code image');
      }

      // Upload to Firebase Storage
      String fileName = 'qr_codes/customer_$customerId.png';
      UploadTask uploadTask = _storage.ref(fileName).putData(
        qrImageBytes,
        SettableMetadata(contentType: 'image/png'),
      );
      
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('❌ Error generating QR code: $e');
      return null;
    }
  }

  /// Generates QR code image from data
  Future<Uint8List?> _generateQRCodeImage(String data) async {
    try {
      final qrValidationResult = QrValidator.validate(
        data: data,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      );

      if (qrValidationResult.status == QrValidationStatus.valid) {
        final qrCode = qrValidationResult.qrCode!;
        
        final painter = QrPainter(
          data: data,
          version: qrCode.typeNumber,
          eyeStyle: const QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: Color(0xFF1E3A8A),
          ),
          dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: Color(0xFF1E3A8A),
          ),
          color: const Color(0xFF1E3A8A),
          gapless: false,
        );

        const picSize = 300.0;
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        
        // Add white background
        final paint = Paint()..color = Colors.white;
        canvas.drawRect(const Rect.fromLTWH(0, 0, picSize, picSize), paint);
        
        // Draw QR code
        painter.paint(canvas, const Size(picSize, picSize));
        
        final picture = recorder.endRecording();
        final img = await picture.toImage(picSize.toInt(), picSize.toInt());
        final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
        
        return byteData?.buffer.asUint8List();
      }
      return null;
    } catch (e) {
      print('❌ Error generating QR code image: $e');
      return null;
    }
  }

  /// Encodes QR data map to string
  String _encodeQRData(Map<String, dynamic> data) {
    // Simple encoding - in production, consider encryption
    return data.entries.map((e) => '${e.key}:${e.value}').join('|');
  }

  /// Links admin-created customer with Firebase Auth when they login
  Future<Map<String, dynamic>> linkCustomerWithAuth({
    required String phoneNumber,
    required String firebaseUid,
  }) async {
    try {
      print('🔗 Starting customer auth linking process...');
      print('🔗 Phone: $phoneNumber, Firebase UID: $firebaseUid');

      // Find customer by phone number
      final customerQuery = await _firestore
          .collection('customer')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .where('isAdminCreated', isEqualTo: true)
          .where('authLinked', isEqualTo: false)
          .get();

      if (customerQuery.docs.isEmpty) {
        return {
          'success': false,
          'error': 'No admin-created customer found for this phone number',
        };
      }

      final customerDoc = customerQuery.docs.first;
      final tempCustomerId = customerDoc.id;
      final customerData = customerDoc.data();

      print('🔗 Found customer with temp ID: $tempCustomerId');

      // Create new customer document with Firebase UID
      final newCustomerData = Map<String, dynamic>.from(customerData);
      newCustomerData['uid'] = firebaseUid;
      newCustomerData['authLinked'] = true;
      newCustomerData['linkedAt'] = FieldValue.serverTimestamp();
      newCustomerData['updatedAt'] = FieldValue.serverTimestamp();
      newCustomerData['lastSignIn'] = FieldValue.serverTimestamp();

      // Create customer document with Firebase UID
      await _firestore.collection('customer').doc(firebaseUid).set(newCustomerData);
      print('🔗 Created new customer document with Firebase UID');

      // Copy addresses to new customer document
      await _copyCustomerAddresses(tempCustomerId, firebaseUid);
      print('🔗 Copied customer addresses');

      // Copy orders to new customer document (if any)
      await _copyCustomerOrders(tempCustomerId, firebaseUid);
      print('🔗 Copied customer orders');

      // Delete the temporary customer document and its subcollections
      await _deleteTemporaryCustomer(tempCustomerId);
      print('🔗 Deleted temporary customer document');

      return {
        'success': true,
        'message': 'Customer successfully linked with Firebase Auth',
        'customerId': firebaseUid,
      };

    } catch (e, stackTrace) {
      print('❌ Error linking customer with auth: $e');
      print('❌ Stack trace: $stackTrace');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Copies addresses from temp customer to Firebase Auth customer
  Future<void> _copyCustomerAddresses(String fromCustomerId, String toCustomerId) async {
    try {
      final addressesSnapshot = await _firestore
          .collection('customer')
          .doc(fromCustomerId)
          .collection('addresses')
          .get();

      final batch = _firestore.batch();

      for (final addressDoc in addressesSnapshot.docs) {
        final newAddressRef = _firestore
            .collection('customer')
            .doc(toCustomerId)
            .collection('addresses')
            .doc(addressDoc.id);

        batch.set(newAddressRef, addressDoc.data());
      }

      await batch.commit();
      print('🔗 Copied ${addressesSnapshot.docs.length} addresses');
    } catch (e) {
      print('❌ Error copying addresses: $e');
      throw e;
    }
  }

  /// Copies orders from temp customer to Firebase Auth customer
  Future<void> _copyCustomerOrders(String fromCustomerId, String toCustomerId) async {
    try {
      // Update orders where customerId matches the temp ID
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('customerId', isEqualTo: fromCustomerId)
          .get();

      if (ordersSnapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();

        for (final orderDoc in ordersSnapshot.docs) {
          final orderData = orderDoc.data();
          orderData['customerId'] = toCustomerId;
          orderData['userId'] = toCustomerId; // Also update userId if present
          orderData['updatedAt'] = FieldValue.serverTimestamp();

          batch.update(orderDoc.reference, orderData);
        }

        await batch.commit();
        print('🔗 Updated ${ordersSnapshot.docs.length} orders');
      }
    } catch (e) {
      print('❌ Error copying orders: $e');
      throw e;
    }
  }

  /// Deletes temporary customer document and subcollections
  Future<void> _deleteTemporaryCustomer(String tempCustomerId) async {
    try {
      // Delete addresses subcollection
      final addressesSnapshot = await _firestore
          .collection('customer')
          .doc(tempCustomerId)
          .collection('addresses')
          .get();

      final batch = _firestore.batch();

      for (final addressDoc in addressesSnapshot.docs) {
        batch.delete(addressDoc.reference);
      }

      // Delete the main customer document
      batch.delete(_firestore.collection('customer').doc(tempCustomerId));

      await batch.commit();
      print('🔗 Deleted temporary customer and ${addressesSnapshot.docs.length} addresses');
    } catch (e) {
      print('❌ Error deleting temporary customer: $e');
      throw e;
    }
  }

  /// Checks if a phone number belongs to an admin-created customer
  Future<bool> isAdminCreatedCustomer(String phoneNumber) async {
    try {
      final customerQuery = await _firestore
          .collection('customer')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .where('isAdminCreated', isEqualTo: true)
          .where('authLinked', isEqualTo: false)
          .get();

      return customerQuery.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error checking admin-created customer: $e');
      return false;
    }
  }
}
