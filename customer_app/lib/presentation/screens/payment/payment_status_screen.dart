import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../data/models/transaction_model.dart';
import '../../providers/payment_provider.dart';

/// Payment Status Screen - Shows transaction results
class PaymentStatusScreen extends StatefulWidget {
  final TransactionModel transaction;
  final bool isSuccess;

  const PaymentStatusScreen({
    Key? key,
    required this.transaction,
    required this.isSuccess,
  }) : super(key: key);

  @override
  State<PaymentStatusScreen> createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends State<PaymentStatusScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Status'),
        backgroundColor: _getStatusColor(),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatusHeader(),
                  const SizedBox(height: 24),
                  _buildTransactionDetails(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                  if (widget.transaction.isFailed) ...[
                    const SizedBox(height: 16),
                    _buildRetrySection(),
                  ],
                  if (widget.transaction.isSuccessful) ...[
                    const SizedBox(height: 16),
                    _buildSuccessActions(),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusHeader() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: _getStatusColor(),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              _getStatusIcon(),
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              _getStatusTitle(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _getStatusMessage(),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.transaction.formattedAmount,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transaction Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Transaction ID', widget.transaction.id),
            _buildDetailRow('Order ID', widget.transaction.orderId),
            _buildDetailRow('Amount', widget.transaction.formattedAmount),
            _buildDetailRow('Description', widget.transaction.description),
            _buildDetailRow('Payer Name', widget.transaction.payerName),
            _buildDetailRow('UPI ID', widget.transaction.upiId),
            if (widget.transaction.upiApp != null)
              _buildDetailRow('UPI App', widget.transaction.upiApp!),
            _buildDetailRow('Status', widget.transaction.statusDisplayText),
            _buildDetailRow('Date & Time', widget.transaction.formattedDateTime),
            if (widget.transaction.transactionRefId != null)
              _buildDetailRow('Reference ID', widget.transaction.transactionRefId!),
            if (widget.transaction.errorMessage != null)
              _buildDetailRow('Error', widget.transaction.errorMessage!, isError: true),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _copyToClipboard(value),
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isError
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () => _shareTransaction(),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          icon: const Icon(Icons.share),
          label: const Text('Share Receipt'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _copyTransactionDetails(),
          icon: const Icon(Icons.copy),
          label: const Text('Copy Details'),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          icon: const Icon(Icons.home),
          label: const Text('Back to Home'),
        ),
      ],
    );
  }

  Widget _buildRetrySection() {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.refresh,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'Retry Payment',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'The payment failed. You can try again with a different UPI app or check your internet connection.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 16),
            Consumer<PaymentProvider>(
              builder: (context, paymentProvider, child) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: paymentProvider.isLoading
                        ? null
                        : () => _retryPayment(paymentProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    ),
                    icon: paymentProvider.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(
                      paymentProvider.isLoading ? 'Retrying...' : 'Retry Payment',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessActions() {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.celebration,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'Payment Successful!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Your payment has been processed successfully. You will receive a confirmation message shortly.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _downloadReceipt(),
                    icon: const Icon(Icons.download),
                    label: const Text('Download Receipt'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _viewTransactionHistory(),
                    icon: const Icon(Icons.history),
                    label: const Text('View History'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (widget.transaction.status) {
      case TransactionStatus.success:
        return Colors.green;
      case TransactionStatus.failed:
        return Colors.red;
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.cancelled:
        return Colors.grey;
      case TransactionStatus.timeout:
        return Colors.deepOrange;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.transaction.status) {
      case TransactionStatus.success:
        return Icons.check_circle;
      case TransactionStatus.failed:
        return Icons.error;
      case TransactionStatus.pending:
        return Icons.access_time;
      case TransactionStatus.cancelled:
        return Icons.cancel;
      case TransactionStatus.timeout:
        return Icons.timer_off;
    }
  }

  String _getStatusTitle() {
    switch (widget.transaction.status) {
      case TransactionStatus.success:
        return 'Payment Successful!';
      case TransactionStatus.failed:
        return 'Payment Failed';
      case TransactionStatus.pending:
        return 'Payment Pending';
      case TransactionStatus.cancelled:
        return 'Payment Cancelled';
      case TransactionStatus.timeout:
        return 'Payment Timed Out';
    }
  }

  String _getStatusMessage() {
    switch (widget.transaction.status) {
      case TransactionStatus.success:
        return 'Your payment has been processed successfully.';
      case TransactionStatus.failed:
        return 'Payment could not be completed. Please try again.';
      case TransactionStatus.pending:
        return 'Your payment is being processed. Please wait.';
      case TransactionStatus.cancelled:
        return 'Payment was cancelled by user.';
      case TransactionStatus.timeout:
        return 'Payment timed out. Please try again.';
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  void _shareTransaction() {
    final text = '''
🧾 Payment Receipt - Cloud Ironing Factory

Transaction ID: ${widget.transaction.id}
Order ID: ${widget.transaction.orderId}
Amount: ${widget.transaction.formattedAmount}
Status: ${widget.transaction.statusDisplayText}
Date: ${widget.transaction.formattedDateTime}
Payer: ${widget.transaction.payerName}

Thank you for your business!
    ''';

    _shareText(text);
  }

  void _copyTransactionDetails() {
    final text = '''
Transaction ID: ${widget.transaction.id}
Order ID: ${widget.transaction.orderId}
Amount: ${widget.transaction.formattedAmount}
Status: ${widget.transaction.statusDisplayText}
Date: ${widget.transaction.formattedDateTime}
Payer: ${widget.transaction.payerName}
UPI ID: ${widget.transaction.upiId}
${widget.transaction.transactionRefId != null ? 'Reference ID: ${widget.transaction.transactionRefId}' : ''}
    ''';

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction details copied to clipboard')),
    );
  }

  void _shareText(String text) {
    // Note: You'll need to add share_plus package for this to work
    // For now, we'll copy to clipboard
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Receipt copied to clipboard')),
    );
  }

  Future<void> _retryPayment(PaymentProvider paymentProvider) async {
    try {
      final success = await paymentProvider.retryTransaction(widget.transaction.id);
      
      if (mounted) {
        if (success) {
          setState(() {
            // Refresh the transaction data
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Retry failed. Please try again later.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Retry failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _downloadReceipt() {
    // Implement receipt download functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Receipt download functionality coming soon')),
    );
  }

  void _viewTransactionHistory() {
    // Navigate to transaction history screen
    Navigator.of(context).pushNamed('/transaction-history');
  }
} 