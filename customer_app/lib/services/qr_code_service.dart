import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';

class QRCodeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Auto-generates QR code if not exists, returns existing if available
  static Future<String?> ensureUserQRCodeExists(String userId, String userName, String phoneNumber) async {
    try {
      // First check if QR code already exists
      String? existingUrl = await getQRCodeUrl(userId);
      if (existingUrl != null) {
        print('QR code already exists for user: $userId');
        return existingUrl;
      }
      
      // Generate new QR code if none exists
      return await generateAndSaveUserQRCode(userId, userName, phoneNumber);
    } catch (e) {
      print('Error ensuring QR code exists: $e');
      return null;
    }
  }

  /// Generates a unique QR code for a user and saves it to Firebase
  static Future<String?> generateAndSaveUserQRCode(String userId, String userName, String phoneNumber) async {
    try {
      // Create QR code data with user information
      Map<String, dynamic> qrData = {
        'type': 'user_profile',
        'userId': userId,
        'userName': userName,
        'phoneNumber': phoneNumber,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'version': '1.0'
      };

      // Convert to JSON string for QR code
      String qrCodeData = _encodeQRData(qrData);
      
      // Generate QR code image
      Uint8List? qrImageBytes = await _generateQRCodeImage(qrCodeData);
      
      if (qrImageBytes == null) {
        throw Exception('Failed to generate QR code image');
      }

      // Upload to Firebase Storage
      String fileName = 'qr_codes/user_$userId.png';
      UploadTask uploadTask = _storage.ref(fileName).putData(qrImageBytes);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      // Save QR code info to Firestore
      await _firestore.collection('customer').doc(userId).update({
        'qrCodeUrl': downloadUrl,
        'qrCodeData': qrCodeData,
        'qrCodeGenerated': FieldValue.serverTimestamp(),
      });

      return downloadUrl;
    } catch (e) {
      print('Error generating and saving QR code: $e');
      return null;
    }
  }

  /// Generates QR code image from data
  static Future<Uint8List?> _generateQRCodeImage(String data) async {
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

        final picSize = 300.0;
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        
        // Add white background
        final paint = Paint()..color = Colors.white;
        canvas.drawRect(Rect.fromLTWH(0, 0, picSize, picSize), paint);
        
        // Draw QR code
        painter.paint(canvas, Size(picSize, picSize));
        
        final picture = recorder.endRecording();
        final img = await picture.toImage(picSize.toInt(), picSize.toInt());
        final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
        
        return byteData?.buffer.asUint8List();
      }
      return null;
    } catch (e) {
      print('Error generating QR code image: $e');
      return null;
    }
  }

  /// Encodes QR data map to string
  static String _encodeQRData(Map<String, dynamic> data) {
    // Simple encoding - in production, consider encryption
    return data.entries.map((e) => '${e.key}:${e.value}').join('|');
  }

  /// Decodes QR data string to map
  static Map<String, dynamic>? decodeQRData(String qrData) {
    try {
      Map<String, dynamic> data = {};
      List<String> pairs = qrData.split('|');
      
      for (String pair in pairs) {
        List<String> keyValue = pair.split(':');
        if (keyValue.length == 2) {
          String key = keyValue[0];
          String value = keyValue[1];
          
          // Parse specific fields
          if (key == 'timestamp') {
            data[key] = int.tryParse(value) ?? 0;
          } else {
            data[key] = value;
          }
        }
      }
      
      return data.isEmpty ? null : data;
    } catch (e) {
      print('Error decoding QR data: $e');
      return null;
    }
  }

  /// Gets user details from QR code scan
  static Future<Map<String, dynamic>?> getUserDetailsFromQR(String qrData) async {
    try {
      Map<String, dynamic>? decodedData = decodeQRData(qrData);
      
      if (decodedData == null || decodedData['type'] != 'user_profile') {
        return null;
      }

      String userId = decodedData['userId'] ?? '';
      if (userId.isEmpty) return null;

      // Get user details from Firestore
      DocumentSnapshot userDoc = await _firestore.collection('customer').doc(userId).get();
      
      if (!userDoc.exists) return null;

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      
      // Get user's recent orders
      QuerySnapshot ordersSnapshot = await _firestore
          .collection('orders')
          .where('customerId', isEqualTo: userId)
          .orderBy('orderTimestamp', descending: true)
          .limit(5)
          .get();

      List<Map<String, dynamic>> recentOrders = ordersSnapshot.docs
          .map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return {
                  'id': doc.id,
                  'orderNumber': data['orderNumber'] ?? doc.id,
                  'status': data['status'] ?? 'Unknown',
                  'totalAmount': data['totalAmount'] ?? 0,
                  'orderTimestamp': data['orderTimestamp'],
                  'items': data['items'] ?? [],
                };
              })
          .toList();

      return {
        'user': {
          'id': userId,
          'name': userData['name'] ?? 'Unknown',
          'phoneNumber': userData['phoneNumber'] ?? '',
          'email': userData['email'] ?? '',
          'clientId': userData['clientId'] ?? '',
        },
        'recentOrders': recentOrders,
        'qrCodeData': decodedData,
      };
    } catch (e) {
      print('Error getting user details from QR: $e');
      return null;
    }
  }

  /// Checks if user has a QR code generated
  static Future<bool> hasQRCode(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('customer').doc(userId).get();
      
      if (!userDoc.exists) return false;

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      return userData['qrCodeUrl'] != null && userData['qrCodeUrl'].toString().isNotEmpty;
    } catch (e) {
      print('Error checking QR code existence: $e');
      return false;
    }
  }

  /// Gets existing QR code URL for user
  static Future<String?> getQRCodeUrl(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('customer').doc(userId).get();
      
      if (!userDoc.exists) return null;

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      return userData['qrCodeUrl'] as String?;
    } catch (e) {
      print('Error getting QR code URL: $e');
      return null;
    }
  }

  /// Regenerates QR code for user (if needed)
  static Future<String?> regenerateQRCode(String userId, String userName, String phoneNumber) async {
    try {
      // Delete old QR code from storage if it exists
      String fileName = 'qr_codes/user_$userId.png';
      await _storage.ref(fileName).delete().catchError((e) {
        print('Old QR code not found or could not be deleted: $e');
      });

      // Generate new QR code
      return await generateAndSaveUserQRCode(userId, userName, phoneNumber);
    } catch (e) {
      print('Error regenerating QR code: $e');
      return null;
    }
  }
} 