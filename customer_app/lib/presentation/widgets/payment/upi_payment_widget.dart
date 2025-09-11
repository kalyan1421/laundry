import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import 'upi_troubleshooting_guide.dart';

class UPIPaymentWidget extends StatefulWidget {
  final double amount;
  final String description;
  final String orderId;
  final Function(Map<String, dynamic>) onPaymentResult;
  final VoidCallback? onCancel;

  const UPIPaymentWidget({
    Key? key,
    required this.amount,
    required this.description,
    required this.orderId,
    required this.onPaymentResult,
    this.onCancel,
  }) : super(key: key);

  @override
  State<UPIPaymentWidget> createState() => _UPIPaymentWidgetState();
}

class _UPIPaymentWidgetState extends State<UPIPaymentWidget> {
  static const String _merchantUpiId = '7396674546-3@ybl';
  static const String _merchantName = 'Cloud Ironing Factory';
  
  bool _isProcessing = false;
  int _selectedMethodIndex = 0; // 0: Deep Link, 1: QR Code, 2: Manual
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildAmountCard(),
          const SizedBox(height: 20),
          _buildPaymentMethodSelector(),
          const SizedBox(height: 20),
          _buildSelectedPaymentMethod(),
          const SizedBox(height: 20),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.payment,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'UPI Payment',
                style: AppTextTheme.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Choose your preferred payment method',
                style: AppTextTheme.bodySmall.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => UpiTroubleshootingGuide.showTroubleshootingDialog(context),
          icon: const Icon(Icons.help_outline),
          style: IconButton.styleFrom(
            backgroundColor: Colors.blue.withOpacity(0.1),
            foregroundColor: Colors.blue,
          ),
          tooltip: 'Payment Help',
        ),
        if (widget.onCancel != null) ...[
          const SizedBox(width: 8),
          IconButton(
            onPressed: widget.onCancel,
            icon: const Icon(Icons.close),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[100],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAmountCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.currency_rupee,
                color: AppColors.primary,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.amount.toStringAsFixed(0)}',
                style: AppTextTheme.headlineMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.description,
            style: AppTextTheme.bodyMedium.copyWith(
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Order ID: ${widget.orderId}',
              style: AppTextTheme.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    final methods = [
      {'title': 'UPI Apps', 'subtitle': 'Pay with any UPI app', 'icon': Icons.apps},
      {'title': 'QR Code', 'subtitle': 'Scan and pay', 'icon': Icons.qr_code},
      {'title': 'UPI ID', 'subtitle': 'Copy and pay manually', 'icon': Icons.copy},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: AppTextTheme.titleSmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: methods.asMap().entries.map((entry) {
              final index = entry.key;
              final method = entry.value;
              final isSelected = index == _selectedMethodIndex;
              
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedMethodIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.all(4),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          method['icon'] as IconData,
                          color: isSelected ? Colors.white : Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          method['title'] as String,
                          style: AppTextTheme.bodySmall.copyWith(
                            color: isSelected ? Colors.white : Colors.grey[800],
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedPaymentMethod() {
    switch (_selectedMethodIndex) {
      case 0:
        return _buildUpiAppsMethod();
      case 1:
        return _buildQRCodeMethod();
      case 2:
        return _buildManualUpiMethod();
      default:
        return _buildUpiAppsMethod();
    }
  }

  Widget _buildUpiAppsMethod() {
    final upiApps = [
      {
        'name': 'Google Pay', 
        'icon': '💳', 
        'color': Colors.blue, 
        'package': 'com.google.android.apps.nbu.paisa.user',
        'scheme': 'upi://pay'
      },
      {
        'name': 'PhonePe', 
        'icon': '📱', 
        'color': Colors.purple, 
        'package': 'com.phonepe.app',
        'scheme': 'upi://pay'
      },
      {
        'name': 'Paytm', 
        'icon': '💰', 
        'color': Colors.indigo, 
        'package': 'net.one97.paytm',
        'scheme': 'upi://pay'
      },
      {
        'name': 'BHIM UPI', 
        'icon': '🏛️', 
        'color': Colors.orange, 
        'package': 'in.org.npci.upiapp',
        'scheme': 'upi://pay'
      },
      {
        'name': 'Amazon Pay', 
        'icon': '📦', 
        'color': Colors.amber, 
        'package': 'in.amazon.mShop.android.shopping',
        'scheme': 'upi://pay'
      },
      {
        'name': 'Any UPI App', 
        'icon': '💳', 
        'color': Colors.green, 
        'package': '',
        'scheme': 'upi://pay'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select UPI App',
          style: AppTextTheme.titleSmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'UPI Payment Instructions',
                      style: AppTextTheme.bodySmall.copyWith(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '• Tap any UPI app below to open it for payment\n'
                '• If app doesn\'t open payment, try QR Code method\n'
                '• Amount: ₹${widget.amount.toStringAsFixed(0)} | UPI ID: $_merchantUpiId',
                style: AppTextTheme.bodySmall.copyWith(
                  color: Colors.blue[600],
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: upiApps.length,
          itemBuilder: (context, index) {
            final app = upiApps[index];
            return GestureDetector(
              onTap: () => _initiateUpiPaymentWithApp(app),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (app['color'] as Color).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        app['icon'] as String,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      app['name'] as String,
                      style: AppTextTheme.bodySmall.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQRCodeMethod() {
    final upiUrl = _createUpiUrl();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Scan QR Code',
          style: AppTextTheme.titleSmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: upiUrl,
                  version: QrVersions.auto,
                  size: 180.0,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.qr_code_scanner, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'How to pay using QR Code:',
                            style: AppTextTheme.bodySmall.copyWith(
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Open any UPI app (GPay, PhonePe, Paytm, etc.)\n'
                      '2. Tap on "Scan QR Code" or camera icon\n'
                      '3. Scan this QR code\n'
                      '4. Verify amount and complete payment',
                      style: AppTextTheme.bodySmall.copyWith(
                        color: Colors.green[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildManualUpiMethod() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Manual UPI Payment',
          style: AppTextTheme.titleSmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCopyableField(
                'UPI ID',
                _merchantUpiId,
                Icons.account_balance,
              ),
              const SizedBox(height: 12),
              _buildCopyableField(
                'Amount',
                '₹${widget.amount.toStringAsFixed(2)}',
                Icons.currency_rupee,
              ),
              const SizedBox(height: 12),
              _buildCopyableField(
                'Note',
                widget.description,
                Icons.note,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber[700], size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Payment Instructions:',
                          style: AppTextTheme.bodySmall.copyWith(
                            color: Colors.amber[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Open any UPI app\n'
                      '2. Choose "Send Money" or "Pay"\n'
                      '3. Enter the UPI ID above\n'
                      '4. Enter the exact amount\n'
                      '5. Add the note for reference\n'
                      '6. Complete the payment',
                      style: AppTextTheme.bodySmall.copyWith(
                        color: Colors.amber[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCopyableField(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextTheme.bodySmall.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  value,
                  style: AppTextTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => _copyToClipboard(value, label),
          icon: const Icon(Icons.copy, size: 18),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.primary.withOpacity(0.1),
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.all(8),
          ),
          tooltip: 'Copy $label',
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_selectedMethodIndex == 0)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : () => _initiateGenericUpiPayment(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.payment, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Open UPI App',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          )
        else if (_selectedMethodIndex == 1)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Scan the QR code above with any UPI app to complete payment',
                    style: AppTextTheme.bodySmall.copyWith(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => _showPaymentCompletionDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'I have completed the payment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        const SizedBox(height: 12),
        
        // Alternative payment confirmation button for QR code
        if (_selectedMethodIndex == 1)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => _showPaymentCompletionDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'I have completed the payment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _createUpiUrl() {
    final transactionRef = widget.orderId;
    
    // Ensure amount has proper format (minimum 1.00)
    final formattedAmount = widget.amount < 1.0 ? 1.0 : widget.amount;
    
    // Simplified UPI URL format that works better with most apps
    final Map<String, String> params = {
      'pa': _merchantUpiId.trim(), // Payee Address (UPI ID)
      'pn': _merchantName.trim(),  // Payee Name
      'am': formattedAmount.toStringAsFixed(2), // Amount
      'cu': 'INR', // Currency
      'tn': widget.description.trim(), // Transaction Note
    };

    // Validate required fields
    if (params['pa']!.isEmpty || params['pn']!.isEmpty) {
      throw Exception('Invalid merchant details');
    }
    
    // Validate UPI ID format
    if (!_isValidUpiId(params['pa']!)) {
      throw Exception('Invalid UPI ID format');
    }

    final queryString = params.entries
        .where((entry) => entry.value.isNotEmpty)
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final upiUrl = 'upi://pay?$queryString';
    
    // Log for debugging
    print('🔧 Standard UPI URL Components:');
    print('   UPI ID: ${params['pa']}');
    print('   Merchant: ${params['pn']}');
    print('   Amount: ${params['am']}');
    print('   Note: ${params['tn']}');
    print('   Final URL: $upiUrl');
    
    return upiUrl;
  }

  String _createAppSpecificUpiUrl(String baseScheme) {
    final formattedAmount = widget.amount < 1.0 ? 1.0 : widget.amount;
    
    // Use standard UPI format for all apps
    final Map<String, String> params = {
      'pa': _merchantUpiId.trim(),
      'pn': _merchantName.trim(),
      'am': formattedAmount.toStringAsFixed(2),
      'cu': 'INR',
      'tn': widget.description.trim(),
    };

    final queryString = params.entries
        .where((entry) => entry.value.isNotEmpty)
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '$baseScheme?$queryString';
  }

  bool _isValidUpiId(String upiId) {
    // UPI ID format: username@bank
    final upiRegex = RegExp(r'^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z]{2,64}$');
    return upiRegex.hasMatch(upiId);
  }

  Future<void> _initiateUpiPaymentWithApp(Map<String, dynamic> app) async {
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);

    try {
      final appName = app['name'] as String;
      final scheme = app['scheme'] as String;
      
      // Create UPI URL based on app scheme
      String upiUrl;
      if (scheme == 'upi://pay') {
        // Generic UPI scheme
        upiUrl = _createUpiUrl();
      } else {
        // App-specific scheme (try first, fallback to generic)
        upiUrl = _createAppSpecificUpiUrl(scheme);
      }
      
      print('🔗 Trying $appName with URL: $upiUrl');
      
      final uri = Uri.parse(upiUrl);
      
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(
          uri, 
          mode: LaunchMode.externalApplication,
        );
        
        print('🚀 $appName Launch Result: $launched');
        
        if (mounted) {
          setState(() => _isProcessing = false);
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (mounted) {
            _showPaymentCompletionDialog();
          }
        }
      } else {
        // If app-specific scheme fails, try generic UPI scheme
        if (scheme != 'upi://pay') {
          print('⚠️ $appName specific scheme failed, trying generic UPI...');
          await _initiateUpiPayment(appName);
          return;
        }
        
        print('❌ Cannot launch UPI with $appName');
        if (mounted) {
          setState(() => _isProcessing = false);
          _showErrorDialog(
            'Could not open $appName. Please ensure it\'s installed or try another UPI app.'
          );
        }
      }
    } catch (e) {
      print('❌ Error launching UPI with ${app['name']}: $e');
      if (mounted) {
        setState(() => _isProcessing = false);
        _showErrorDialog('Failed to open ${app['name']}: $e\n\nPlease try another payment method.');
      }
    }
  }

  Future<void> _initiateUpiPayment(String appName) async {
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);

    try {
      final upiUrl = _createUpiUrl();
      print('🔗 UPI Payment URL: $upiUrl'); // Debug log
      
      final uri = Uri.parse(upiUrl);
      
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(
          uri, 
          mode: LaunchMode.externalApplication,
        );
        
        print('🚀 UPI App Launch Result: $launched'); // Debug log
        
        if (mounted) {
          setState(() => _isProcessing = false);
          
          // Small delay to let the UPI app open, then show confirmation
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (mounted) {
            _showPaymentCompletionDialog();
          }
        }
      } else {
        print('❌ Cannot launch UPI URL: $upiUrl'); // Debug log
        if (mounted) {
          setState(() => _isProcessing = false);
          _showErrorDialog(
            'Could not open UPI app. Please ensure you have a UPI app installed or try the QR Code method.'
          );
        }
      }
    } catch (e) {
      print('❌ Error launching UPI: $e'); // Debug log
      if (mounted) {
        setState(() => _isProcessing = false);
        _showErrorDialog('Failed to initiate payment: $e\n\nPlease try the QR Code or Manual method.');
      }
    }
  }

  Future<void> _initiateGenericUpiPayment() async {
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);

    try {
      final upiUrl = _createUpiUrl();
      print('🔗 Generic UPI Payment URL: $upiUrl');
      
      final uri = Uri.parse(upiUrl);
      
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(
          uri, 
          mode: LaunchMode.externalApplication,
        );
        
        print('🚀 Generic UPI Launch Result: $launched');
        
        if (mounted) {
          setState(() => _isProcessing = false);
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (mounted) {
            _showPaymentCompletionDialog();
          }
        }
      } else {
        print('❌ Cannot launch generic UPI');
        if (mounted) {
          setState(() => _isProcessing = false);
          _showErrorDialog(
            'No UPI app found. Please install a UPI app like Google Pay, PhonePe, or Paytm, then try again.'
          );
        }
      }
    } catch (e) {
      print('❌ Error launching generic UPI: $e');
      if (mounted) {
        setState(() => _isProcessing = false);
        _showErrorDialog('Failed to open UPI payment: $e\n\nPlease try the QR Code or Manual method.');
      }
    }
  }

  Future<void> _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label copied to clipboard'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _showPaymentCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.help_outline, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            const Text('Confirm Payment'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Have you completed the UPI payment of ₹${widget.amount.toStringAsFixed(0)}?',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text('Order ID: ${widget.orderId}'),
                  const SizedBox(height: 4),
                  Text('Amount: ₹${widget.amount.toStringAsFixed(2)}'),
                  const SizedBox(height: 4),
                  Text('UPI ID: $_merchantUpiId'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onPaymentResult({
                'success': false,
                'message': 'Payment cancelled by user'
              });
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onPaymentResult({
                'success': true,
                'transactionId': widget.orderId,
                'amount': widget.amount,
                'method': 'UPI',
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Yes, Completed', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Payment Error'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline, color: Colors.orange, size: 16),
                        const SizedBox(width: 8),
                        const Text(
                          'Quick Fixes:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Try the QR Code method instead\n'
                      '• Use manual UPI ID: 7396674546-3@ybl\n'
                      '• Update your UPI app to latest version\n'
                      '• Check your internet connection\n'
                      '• Try a different UPI app',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Switch to QR code method
              setState(() {
                _selectedMethodIndex = 1;
              });
            },
            child: const Text('Try QR Code'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
