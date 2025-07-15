import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/phone_formatter.dart';

class PdfGenerationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch customer's primary address or first address
  static Future<Map<String, dynamic>?> _fetchCustomerAddress(String customerId) async {
    try {
      final addressesSnapshot = await _firestore
          .collection('customer')
          .doc(customerId)
          .collection('addresses')
          .get();

      if (addressesSnapshot.docs.isEmpty) {
        return null;
      }

      // Find primary address first
      for (var doc in addressesSnapshot.docs) {
        final addressData = doc.data();
        if (addressData['isPrimary'] == true) {
          return {
            'id': doc.id,
            ...addressData,
          };
        }
      }

      // If no primary address found, return first address
      final firstAddress = addressesSnapshot.docs.first.data();
      return {
        'id': addressesSnapshot.docs.first.id,
        ...firstAddress,
      };
    } catch (e) {
      print('Error fetching customer address: $e');
      return null;
    }
  }

  // Format address for display
  static String _formatAddress(Map<String, dynamic>? address) {
    if (address == null) return 'No address available';

    List<String> addressParts = [];
    
    if (address['doorNumber'] != null && address['doorNumber'].toString().isNotEmpty) {
      addressParts.add('Door: ${address['doorNumber']}');
    }
    
    if (address['floorNumber'] != null && address['floorNumber'].toString().isNotEmpty) {
      addressParts.add('Floor: ${address['floorNumber']}');
    }
    
    if (address['apartmentName'] != null && address['apartmentName'].toString().isNotEmpty) {
      addressParts.add(address['apartmentName']);
    }
    
    if (address['addressLine1'] != null && address['addressLine1'].toString().isNotEmpty) {
      addressParts.add(address['addressLine1']);
    }
    
    if (address['addressLine2'] != null && address['addressLine2'].toString().isNotEmpty) {
      addressParts.add(address['addressLine2']);
    }
    
    if (address['nearbyLandmark'] != null && address['nearbyLandmark'].toString().isNotEmpty) {
      addressParts.add('Near ${address['nearbyLandmark']}');
    }
    
    if (address['city'] != null && address['city'].toString().isNotEmpty) {
      addressParts.add(address['city']);
    }
    
    if (address['state'] != null && address['state'].toString().isNotEmpty) {
      addressParts.add(address['state']);
    }
    
    if (address['pincode'] != null && address['pincode'].toString().isNotEmpty) {
      addressParts.add(address['pincode']);
    }

    return addressParts.join(', ');
  }

  static Future<Uint8List> generateCustomerDetailsPdf(UserModel customer) async {
    final pdf = pw.Document();

    // Fetch customer address
    final customerAddress = await _fetchCustomerAddress(customer.uid);
    final formattedAddress = _formatAddress(customerAddress);

    // Generate QR code data (with address)
    final qrData = {
      'id': customer.uid,
      'name': customer.name,
      'clientId': PhoneFormatter.getClientId(customer.phoneNumber),
      'email': customer.email,
      'address': formattedAddress,
    };
    final qrCodeData = qrData.entries.map((e) => '${e.key}: ${e.value}').join('\n');

    // Create QR code image
    final qrValidationResult = QrValidator.validate(
      data: qrCodeData,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );

    if (qrValidationResult.status != QrValidationStatus.valid) {
      throw Exception('Failed to generate QR code');
    }

    final qrCode = qrValidationResult.qrCode!;
    final painter = QrPainter.withQr(
      qr: qrCode,
      color: const Color(0xFF000000),
      emptyColor: const Color(0xFFFFFFFF),
      gapless: false,
    );

    // Convert QR code to image bytes
    final picData = await painter.toImageData(200);
    final qrImageBytes = picData?.buffer.asUint8List();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue700,
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Cloud Ironing Factory',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 30),
                
                // Customer Information
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Customer Details
                    pw.Expanded(
                      flex: 2,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Customer Information',
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue700,
                            ),
                          ),
                          pw.SizedBox(height: 15),
                          
                          _buildDetailRow('Name:', customer.name),
                          _buildDetailRow('Client ID:', PhoneFormatter.getClientId(customer.phoneNumber)),
                          _buildDetailRow('Email:', customer.email),
                          _buildDetailRow('Address:', formattedAddress),
                          
                          if (customer.createdAt != null)
                            _buildDetailRow(
                              'Member Since:',
                              '${customer.createdAt!.toDate().day}/${customer.createdAt!.toDate().month}/${customer.createdAt!.toDate().year}',
                            ),
                            
                          pw.SizedBox(height: 20),
                          
                          // Profile Status
                          pw.Container(
                            padding: const pw.EdgeInsets.all(10),
                            decoration: pw.BoxDecoration(
                              color: customer.isProfileComplete == true ? PdfColors.green100 : PdfColors.orange100,
                              borderRadius: pw.BorderRadius.circular(5),
                            ),
                            child: pw.Text(
                              'Profile Status: ${customer.isProfileComplete == true ? "Complete" : "Incomplete"}',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: customer.isProfileComplete == true ? PdfColors.green700 : PdfColors.orange700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    pw.SizedBox(width: 30),
                    
                    // QR Code
                    pw.Expanded(
                      flex: 1,
                      child: pw.Column(
                        children: [
                          pw.Text(
                            'Customer QR Code',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue700,
                            ),
                          ),
                          pw.SizedBox(height: 15),
                          
                          if (qrImageBytes != null)
                            pw.Container(
                              width: 150,
                              height: 150,
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(color: PdfColors.grey300),
                                borderRadius: pw.BorderRadius.circular(10),
                              ),
                              child: pw.Center(
                                child: pw.Image(
                                  pw.MemoryImage(qrImageBytes),
                                  width: 130,
                                  height: 130,
                                ),
                              ),
                            ),
                          
                          pw.SizedBox(height: 10),
                          pw.Text(
                            'Scan for quick customer lookup',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey600,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                pw.SizedBox(height: 40),
                
                // Footer
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Generated on: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Cloud Ironing Factory - Premium Laundry Services',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value.isNotEmpty ? value : 'Not provided',
              style: const pw.TextStyle(color: PdfColors.black),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> downloadCustomerPdf(UserModel customer) async {
    try {
      final pdfBytes = await generateCustomerDetailsPdf(customer);
      
      // Get temporary directory
      final directory = await getTemporaryDirectory();
      
      // Format filename: phone_number_without_+91_customer_name.pdf
      final clientId = PhoneFormatter.getClientId(customer.phoneNumber);
      final customerName = customer.name.replaceAll(' ', '_');
      final fileName = '${clientId}_${customerName}.pdf';
      
      final file = File('${directory.path}/$fileName');
      
      // Write PDF to file
      await file.writeAsBytes(pdfBytes);
      
      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Customer Details: ${customer.name}',
        subject: 'Customer Information - ${customer.name}',
      );
      
    } catch (e) {
      throw Exception('Failed to generate PDF: $e');
    }
  }
} 