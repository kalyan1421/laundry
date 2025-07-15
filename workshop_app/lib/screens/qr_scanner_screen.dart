import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../providers/auth_provider.dart';
import '../services/qr_scanner_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/loading_widget.dart';
import '../models/order.dart' as workshop_order;

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final QRScannerService _scannerService = QRScannerService();
  MobileScannerController? _controller;
  bool _isProcessing = false;
  bool _flashOn = false;
  String? _lastScannedCode;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  void _initializeScanner() {
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    _scannerService.initializeScanner();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _scannerService.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || capture.barcodes.isEmpty) return;
    
    final barcode = capture.barcodes.first;
    final code = barcode.rawValue;
    
    if (code == null || code == _lastScannedCode) return;
    
    setState(() {
      _isProcessing = true;
      _lastScannedCode = code;
    });

    await _processScanResult(capture);
    
    // Reset processing state after a delay
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isProcessing = false;
        _lastScannedCode = null;
      });
    }
  }

  Future<void> _processScanResult(BarcodeCapture capture) async {
    try {
      // Process scan result using the scanner service
      final parsedData = await _scannerService.processScanResult(capture);
      
      if (parsedData == null) {
        _showErrorDialog('Invalid QR Code', 'The scanned QR code is not valid or readable.');
        return;
      }

      // Check if it contains order or customer information
      final orderId = parsedData['orderId'] as String?;
      final customerId = parsedData['customerId'] as String?;
      
      if (orderId == null && customerId == null) {
        _showErrorDialog('Invalid QR Code', 'This QR code does not contain valid order or customer information.');
        return;
      }

      // Show order details and processing options
      if (orderId != null) {
        await _showOrderProcessingDialog(orderId, parsedData);
      } else if (customerId != null) {
        await _showCustomerOrdersDialog(customerId, parsedData);
      }
      
    } catch (e) {
      _showErrorDialog('Scan Error', 'Failed to process QR code: $e');
    }
  }

  Future<void> _showOrderProcessingDialog(String orderId, Map<String, dynamic> qrData) async {
    final orderProvider = context.read<OrderProvider>();
    
    try {
      // Fetch order details
      final order = await _getOrderById(orderId);
      
      if (order == null) {
        _showErrorDialog('Order Not Found', 'Order with ID $orderId was not found.');
        return;
      }

      if (!mounted) return;

      // Show order processing dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.receipt_long,
                color: AppColors.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Order Details',
                style: AppTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOrderInfo('Order ID', '#${order.id.substring(0, 8)}'),
                _buildOrderInfo('Customer', order.customerName),
                _buildOrderInfo('Status', order.status.toUpperCase()),
                _buildOrderInfo('Total Items', '${order.items.length}'),
                _buildOrderInfo('Total Amount', '₹${order.totalAmount.toStringAsFixed(2)}'),
                
                const SizedBox(height: 16),
                Text(
                  'Items:',
                  style: AppTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• ${item.name} (${item.quantity}x) - ₹${item.price.toStringAsFixed(2)}',
                    style: AppTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                )).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: AppTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            if (order.status == 'pending') ...[
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _processOrder(order, 'processing');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.infoColor,
                ),
                child: Text(
                  'Start Processing',
                  style: AppTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ] else if (order.status == 'processing') ...[
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _processOrder(order, 'completed');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.successColor,
                ),
                child: Text(
                  'Mark Complete',
                  style: AppTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ] else ...[
              Text(
                'Order already ${order.status}',
                style: AppTheme.bodyMedium?.copyWith(
                  color: AppColors.successColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      );
      
    } catch (e) {
      _showErrorDialog('Error', 'Failed to fetch order details: $e');
    }
  }

  Future<void> _showCustomerOrdersDialog(String customerId, Map<String, dynamic> qrData) async {
    _showErrorDialog('Customer QR Scanned', 'Customer QR codes are not yet supported. Please scan an order QR code.');
  }

  Future<workshop_order.WorkshopOrder?> _getOrderById(String orderId) async {
    // This is a placeholder - you'll need to implement this in OrderProvider
    // For now, return null
    return null;
  }

  Future<void> _processOrder(workshop_order.WorkshopOrder order, String newStatus) async {
    try {
      setState(() => _isProcessing = true);
      
      final authProvider = context.read<AuthProvider>();
      final orderProvider = context.read<OrderProvider>();
      final member = authProvider.currentMember;
      
      if (member == null) {
        _showErrorDialog('Authentication Error', 'Please log in again.');
        return;
      }

      bool success = false;
      if (newStatus == 'processing') {
        success = await orderProvider.startProcessingOrder(order.id, member);
      } else if (newStatus == 'completed') {
        // Calculate earnings (you can customize this logic)
        final earnings = order.totalAmount * 0.1; // 10% commission
        success = await orderProvider.completeOrder(order.id, member, earnings);
      }

      if (success) {
        _showSuccessDialog('Success', 'Order status updated to $newStatus');
      } else {
        _showErrorDialog('Update Failed', 'Failed to update order status. Please try again.');
      }
      
    } catch (e) {
      _showErrorDialog('Error', 'Failed to process order: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Widget _buildOrderInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: AppTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.errorColor,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTheme.titleMedium?.copyWith(
                color: AppColors.errorColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: AppTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: AppTheme.bodyMedium?.copyWith(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String title, String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: AppColors.successColor,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTheme.titleMedium?.copyWith(
                color: AppColors.successColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: AppTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: AppTheme.bodyMedium?.copyWith(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Scan QR Code',
          style: AppTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        leading: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),
        actions: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleFlash,
              child: Icon(
                _flashOn ? Icons.flash_on : Icons.flash_off,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // QR Scanner View
          if (_controller != null)
            MobileScanner(
              controller: _controller!,
              onDetect: _onDetect,
            ),
          
          // Overlay UI
          _buildOverlay(),
          
          // Processing indicator
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: LoadingWidget(
                  message: 'Processing QR Code...',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return Column(
      children: [
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.black54,
            child: Center(
              child: Text(
                'Position QR code within the frame',
                style: AppTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.primaryColor,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.black54,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Scan a customer QR code to process their order',
                  style: AppTheme.bodySmall?.copyWith(
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      icon: Icons.flash_off,
                      label: 'Flash',
                      onTap: _toggleFlash,
                      isActive: _flashOn,
                    ),
                    _buildControlButton(
                      icon: Icons.switch_camera,
                      label: 'Switch',
                      onTap: _switchCamera,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Material(
      color: isActive ? AppColors.primaryColor : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTheme.bodySmall?.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleFlash() async {
    try {
      await _controller?.toggleTorch();
      setState(() {
        _flashOn = !_flashOn;
      });
    } catch (e) {
      _showErrorDialog('Flash Error', 'Failed to toggle flash: $e');
    }
  }

  Future<void> _switchCamera() async {
    try {
      await _controller?.switchCamera();
    } catch (e) {
      _showErrorDialog('Camera Error', 'Failed to switch camera: $e');
    }
  }
} 