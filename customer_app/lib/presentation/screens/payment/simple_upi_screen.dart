import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/simple_upi_service.dart';

class SimpleUpiScreen extends StatefulWidget {
  final double amount;
  final String description;
  final String? orderId;

  const SimpleUpiScreen({
    Key? key,
    required this.amount,
    required this.description,
    this.orderId,
  }) : super(key: key);

  @override
  State<SimpleUpiScreen> createState() => _SimpleUpiScreenState();
}

class _SimpleUpiScreenState extends State<SimpleUpiScreen> {
  final SimpleUpiService _upiService = SimpleUpiService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'UPI Payment',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Amount Card
            _buildAmountCard(),
            const SizedBox(height: 24),
            
            // UPI Details Card
            _buildUpiDetailsCard(),
            const SizedBox(height: 24),
            
            // Instructions Card
            _buildInstructionsCard(),
            
            const Spacer(),
            
            // Payment Button
            _buildPaymentButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.currency_rupee,
            size: 32,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          Text(
            '₹${widget.amount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUpiDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Merchant Name
          Row(
            children: [
              const Icon(Icons.store, color: Colors.blue, size: 20),
              const SizedBox(width: 12),
              Text(
                _upiService.merchantName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // UPI ID with copy button
          Row(
            children: [
              const Icon(Icons.account_balance_wallet, color: Colors.orange, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _upiService.merchantUpiId,
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              IconButton(
                onPressed: () async {
                  await _upiService.copyUpiId();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('UPI ID copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.copy, size: 18),
                tooltip: 'Copy UPI ID',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Payment Instructions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '1. Click "Pay Now" to open your UPI app\n'
            '2. Complete the payment in your UPI app\n'
            '3. Return to this app to confirm payment\n'
            '4. Keep the transaction reference for your records',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue,
              height: 1.5,
            ),
          ),
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
                const Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'UPI App Issues?',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'If UPI apps show errors, use "Pay Manually" option',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                // Test UPI ID button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showUpiTestDialog(),
                    icon: const Icon(Icons.science, size: 16),
                    label: const Text('Test UPI ID'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUpiTestDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.science, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Test UPI ID'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick way to verify if UPI ID is working:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '1. Open Google Pay or PhonePe',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  const Text('2. Tap "Send Money"'),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('3. Enter: '),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _upiService.merchantUpiId,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          await _upiService.copyUpiId();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('UPI ID copied!'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        tooltip: 'Copy UPI ID',
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('4. Enter ₹1 as amount'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '✅ If name shows up → UPI ID is working\n❌ If error appears → UPI ID is inactive',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _initiatePayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payment, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Pay Now',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _initiatePayment() async {
    setState(() => _isLoading = true);

    try {
      final result = await _upiService.initiatePayment(
        amount: widget.amount,
        description: widget.description,
        orderId: widget.orderId,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (result['success'] == true) {
          // Show payment confirmation dialog
          _showPaymentConfirmationDialog(result['transactionId']);
        } else {
          // Show error dialog
          _showErrorDialog(result['message'] ?? 'Payment failed');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog('Failed to initiate payment: $e');
      }
    }
  }

  void _showPaymentConfirmationDialog(String transactionId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Confirm Payment'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Have you completed the payment in your UPI app?',
              style: TextStyle(fontSize: 16),
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
                  Text('Transaction ID: $transactionId'),
                  const SizedBox(height: 4),
                  Text('Amount: ₹${widget.amount.toStringAsFixed(2)}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Manual payment option
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Having issues? Pay manually:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'UPI ID: ${_upiService.merchantUpiId}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          await _upiService.copyUpiId();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('UPI ID copied!'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        tooltip: 'Copy UPI ID',
                      ),
                    ],
                  ),
                  Text(
                    'Amount: ₹${widget.amount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    'Note: ${widget.description}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, {'success': false, 'message': 'Payment cancelled'});
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showManualPaymentDialog(transactionId);
            },
            child: const Text('Pay Manually'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, {
                'success': true,
                'transactionId': transactionId,
                'amount': widget.amount,
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Yes, Completed', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showManualPaymentDialog(String transactionId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.phone_android, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Manual Payment'),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Follow these steps to complete payment:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildManualStep('1', 'Open any UPI app (Google Pay, PhonePe, Paytm)', Icons.apps),
              _buildManualStep('2', 'Tap "Send Money" or "Pay"', Icons.send),
              _buildManualStep('3', 'Enter UPI ID: ${_upiService.merchantUpiId}', Icons.account_balance_wallet),
              _buildManualStep('4', 'Amount: ₹${widget.amount.toStringAsFixed(2)}', Icons.currency_rupee),
              _buildManualStep('5', 'Note: ${widget.description}', Icons.note),
              _buildManualStep('6', 'Reference: $transactionId', Icons.receipt),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.copy, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _upiService.merchantUpiId,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await _upiService.copyUpiId();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('UPI ID copied to clipboard!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: const Text('COPY'),
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
              Navigator.pop(context, {'success': false, 'message': 'Payment cancelled'});
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, {
                'success': true,
                'transactionId': transactionId,
                'amount': widget.amount,
                'paymentMethod': 'manual',
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Payment Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildManualStep(String step, String instruction, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              instruction,
              style: const TextStyle(fontSize: 14),
            ),
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
            Text('UPI Payment Issue'),
          ],
        ),
        content: Column(
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
                  const Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.orange, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Quick Solutions:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Check if UPI ID 7396674546@axl is active\n'
                    '• Try Google Pay instead of PhonePe\n'
                    '• Use "Pay Manually" option below\n'
                    '• Ensure stable internet connection',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.phone_android, color: Colors.blue, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Manual Payment Option:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'UPI ID: ${_upiService.merchantUpiId}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await _upiService.copyUpiId();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('UPI ID copied!'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                        child: const Text('COPY'),
                      ),
                    ],
                  ),
                  Text(
                    'Amount: ₹${widget.amount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Try Again'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final transactionId = 'ORDER_${DateTime.now().millisecondsSinceEpoch}';
              _showManualPaymentDialog(transactionId);
            },
            child: const Text('Pay Manually'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, {'success': false, 'message': message});
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
} 