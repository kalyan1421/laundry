import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'dart:convert';

class QRScannerService {
  final Logger _logger = Logger();
  MobileScannerController? _controller;
  bool _isScanning = false;
  String? _lastScannedCode;
  DateTime? _lastScanTime;

  // Getters
  MobileScannerController? get controller => _controller;
  bool get isScanning => _isScanning;
  String? get lastScannedCode => _lastScannedCode;
  DateTime? get lastScanTime => _lastScanTime;

  // Initialize QR scanner
  void initializeScanner() {
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    _logger.i('QR scanner initialized');
  }

  // Start scanning
  Future<void> startScanning() async {
    try {
      if (_controller != null && !_isScanning) {
        await _controller!.start();
        _isScanning = true;
        _logger.i('QR scanning started');
      }
    } catch (e) {
      _logger.e('Error starting QR scanning: $e');
      throw Exception('Failed to start QR scanning: $e');
    }
  }

  // Stop scanning
  Future<void> stopScanning() async {
    try {
      if (_controller != null && _isScanning) {
        await _controller!.stop();
        _isScanning = false;
        _logger.i('QR scanning stopped');
      }
    } catch (e) {
      _logger.e('Error stopping QR scanning: $e');
      throw Exception('Failed to stop QR scanning: $e');
    }
  }

  // Toggle flash
  Future<void> toggleFlash() async {
    try {
      if (_controller != null) {
        await _controller!.toggleTorch();
        _logger.i('Flash toggled');
      }
    } catch (e) {
      _logger.e('Error toggling flash: $e');
      throw Exception('Failed to toggle flash: $e');
    }
  }

  // Switch camera
  Future<void> switchCamera() async {
    try {
      if (_controller != null) {
        await _controller!.switchCamera();
        _logger.i('Camera switched');
      }
    } catch (e) {
      _logger.e('Error switching camera: $e');
      throw Exception('Failed to switch camera: $e');
    }
  }

  // Process scan result
  Future<Map<String, dynamic>?> processScanResult(BarcodeCapture capture) async {
    try {
      if (capture.barcodes.isEmpty) return null;
      
      final barcode = capture.barcodes.first;
      final code = barcode.rawValue;
      
      if (code == null || code.isEmpty) return null;
      
      // Avoid duplicate scans
      if (_lastScannedCode == code && 
          _lastScanTime != null && 
          DateTime.now().difference(_lastScanTime!).inSeconds < 2) {
        return null;
      }
      
      _lastScannedCode = code;
      _lastScanTime = DateTime.now();
      
      _logger.i('Processing QR code: $code');
      
      // Parse QR code data
      final parsedData = parseQRCode(code);
      
      if (parsedData != null) {
        _logger.i('QR code parsed successfully: ${parsedData['type']}');
        return parsedData;
      }
      
      _logger.w('Failed to parse QR code');
      return null;
    } catch (e) {
      _logger.e('Error processing scan result: $e');
      return null;
    }
  }

  // Parse QR code data
  Map<String, dynamic>? parseQRCode(String qrData) {
    try {
      _logger.i('Parsing QR code: $qrData');
      
      // Try to parse as JSON first
      if (qrData.startsWith('{') && qrData.endsWith('}')) {
        try {
          final data = jsonDecode(qrData) as Map<String, dynamic>;
          _logger.i('QR code parsed as JSON successfully');
          return data;
        } catch (e) {
          _logger.w('Failed to parse QR code as JSON: $e');
        }
      }
      
      // Try to parse as URL with parameters
      if (qrData.startsWith('http')) {
        try {
          final uri = Uri.parse(qrData);
          final data = <String, dynamic>{
            'type': 'url',
            'url': qrData,
            'scheme': uri.scheme,
            'host': uri.host,
            'path': uri.path,
            'queryParameters': uri.queryParameters,
          };
          
          // Check if it's an order URL
          if (uri.queryParameters.containsKey('orderId')) {
            data['type'] = 'order';
            data['orderId'] = uri.queryParameters['orderId'];
          }
          
          // Check if it's a customer URL
          if (uri.queryParameters.containsKey('customerId')) {
            data['type'] = 'customer';
            data['customerId'] = uri.queryParameters['customerId'];
          }
          
          _logger.i('QR code parsed as URL successfully');
          return data;
        } catch (e) {
          _logger.w('Failed to parse QR code as URL: $e');
        }
      }
      
      // Try to parse as delimited string (e.g., "ORDER:12345:CUSTOMER:67890")
      if (qrData.contains(':')) {
        try {
          final parts = qrData.split(':');
          if (parts.length >= 2) {
            final data = <String, dynamic>{
              'type': parts[0].toLowerCase(),
              'raw': qrData,
              'parts': parts,
            };
            
            // Handle order format: ORDER:orderId:customerId
            if (parts[0].toUpperCase() == 'ORDER' && parts.length >= 2) {
              data['orderId'] = parts[1];
              if (parts.length >= 3) {
                data['customerId'] = parts[2];
              }
            }
            
            // Handle customer format: CUSTOMER:customerId
            if (parts[0].toUpperCase() == 'CUSTOMER' && parts.length >= 2) {
              data['customerId'] = parts[1];
            }
            
            _logger.i('QR code parsed as delimited string successfully');
            return data;
          }
        } catch (e) {
          _logger.w('Failed to parse QR code as delimited string: $e');
        }
      }
      
      // Return as raw text if no specific format is detected
      final data = <String, dynamic>{
        'type': 'text',
        'raw': qrData,
        'text': qrData,
      };
      
      _logger.i('QR code parsed as raw text');
      return data;
    } catch (e) {
      _logger.e('Error parsing QR code: $e');
      return null;
    }
  }

  // Validate QR code format
  bool isValidQRCode(String qrData) {
    try {
      // Check for minimum length
      if (qrData.length < 3) return false;
      
      // Check for valid formats
      if (qrData.startsWith('{') && qrData.endsWith('}')) return true;
      if (qrData.startsWith('http')) return true;
      if (qrData.contains(':')) return true;
      
      // Allow plain text QR codes
      return true;
    } catch (e) {
      _logger.e('Error validating QR code: $e');
      return false;
    }
  }

  // Get QR code type
  String getQRCodeType(String qrData) {
    try {
      final parsedData = parseQRCode(qrData);
      return parsedData?['type'] ?? 'unknown';
    } catch (e) {
      _logger.e('Error getting QR code type: $e');
      return 'unknown';
    }
  }

  // Dispose scanner
  Future<void> dispose() async {
    try {
      if (_controller != null) {
        await _controller!.dispose();
        _controller = null;
        _isScanning = false;
        _logger.i('QR scanner disposed');
      }
    } catch (e) {
      _logger.e('Error disposing QR scanner: $e');
    }
  }

  // Reset scanner state
  void reset() {
    _lastScannedCode = null;
    _lastScanTime = null;
    _logger.i('QR scanner state reset');
  }

  // Get scanner info
  Map<String, dynamic> getScannerInfo() {
    return {
      'isScanning': _isScanning,
      'lastScannedCode': _lastScannedCode,
      'lastScanTime': _lastScanTime?.toIso8601String(),
      'hasController': _controller != null,
    };
  }
}