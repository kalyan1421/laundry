import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/auth_provider.dart';
import 'payment_status_screen.dart';

/// Comprehensive UPI Payment Screen
class PaymentScreen extends StatefulWidget {
  final String orderId;
  final double? initialAmount;
  final String? initialDescription;

  const PaymentScreen({
    Key? key,
    required this.orderId,
    this.initialAmount,
    this.initialDescription,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _upiIdController = TextEditingController();
  final _payerNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _initializePaymentProvider();
  }

  void _initializeForm() {
    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount!.toStringAsFixed(2);
    }
    if (widget.initialDescription != null) {
      _descriptionController.text = widget.initialDescription!;
    }
  }

  void _initializePaymentProvider() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
      paymentProvider.initialize();

      // Set initial values
      if (widget.initialAmount != null) {
        paymentProvider.setAmount(widget.initialAmount!);
      }
      if (widget.initialDescription != null) {
        paymentProvider.setDescription(widget.initialDescription!);
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _upiIdController.dispose();
    _payerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UPI Payment'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
      ),
      body: Consumer<PaymentProvider>(
        builder: (context, paymentProvider, child) {
          if (!paymentProvider.isInitialized) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing payment system...'),
                ],
              ),
            );
          }

          if (!paymentProvider.isUpiSupported) {
            return _buildUpiNotSupportedView();
          }

          return _buildPaymentForm(paymentProvider);
        },
      ),
    );
  }

  Widget _buildUpiNotSupportedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.payment_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'UPI Not Available',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'No UPI apps found on your device. Please install a UPI app like PhonePe, GPay, or Paytm to make payments.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentForm(PaymentProvider paymentProvider) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildOrderInfoCard(),
            const SizedBox(height: 16),
            _buildAmountSection(paymentProvider),
            const SizedBox(height: 16),
            _buildPayerDetailsSection(paymentProvider),
            const SizedBox(height: 16),
            _buildUpiAppsSection(paymentProvider),
            const SizedBox(height: 16),
            _buildPaymentSummary(paymentProvider),
            const SizedBox(height: 24),
            _buildPayButton(paymentProvider),
            if (paymentProvider.errorMessage != null) ...[
              const SizedBox(height: 16),
              _buildErrorCard(paymentProvider.errorMessage!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Order Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order ID:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  widget.orderId,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Service:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Cloud Ironing Factory',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountSection(PaymentProvider paymentProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Amount *',
                prefixText: '₹ ',
                prefixIcon: const Icon(Icons.currency_rupee),
                border: const OutlineInputBorder(),
                helperText: 'Enter amount between ₹1 and ₹1,00,000',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: paymentProvider.validateAmount,
              onChanged: (value) {
                final amount = double.tryParse(value) ?? 0.0;
                paymentProvider.setAmount(amount);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Payment Description *',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
                helperText: 'Describe what this payment is for',
              ),
              maxLines: 2,
              validator: paymentProvider.validateDescription,
              onChanged: paymentProvider.setDescription,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayerDetailsSection(PaymentProvider paymentProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payer Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _payerNameController,
              decoration: const InputDecoration(
                labelText: 'Your Name *',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
                helperText: 'Enter your full name',
              ),
              textCapitalization: TextCapitalization.words,
              validator: paymentProvider.validatePayerName,
              onChanged: paymentProvider.setPayerName,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _upiIdController,
              decoration: const InputDecoration(
                labelText: 'Your UPI ID *',
                prefixIcon: Icon(Icons.account_balance_wallet),
                border: OutlineInputBorder(),
                helperText: 'e.g., yourname@paytm, 9876543210@upi',
              ),
              keyboardType: TextInputType.text,
              validator: paymentProvider.validateUpiId,
              onChanged: paymentProvider.setUpiId,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpiAppsSection(PaymentProvider paymentProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select UPI App',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (paymentProvider.availableUpiApps.isEmpty)
              const Text('Loading UPI apps...')
            else
              _buildUpiAppGrid(paymentProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildUpiAppGrid(PaymentProvider paymentProvider) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.2,
      ),
      itemCount: paymentProvider.availableUpiApps.length,
      itemBuilder: (context, index) {
        final appMeta = paymentProvider.availableUpiApps[index];
        final isSelected = paymentProvider.selectedUpiApp?.upiApplication.toString() == 
            appMeta.upiApplication.toString();

        return GestureDetector(
          onTap: () => paymentProvider.selectUpiApp(appMeta),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                appMeta.iconImage(32),
                const SizedBox(height: 4),
                Text(
                  appMeta.upiApplication.getAppName(),
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentSummary(PaymentProvider paymentProvider) {
    if (!paymentProvider.isFormValid) return const SizedBox.shrink();

    final summary = paymentProvider.getPaymentSummary();

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow('Amount:', summary['formattedAmount']),
            _buildSummaryRow('Payer:', summary['payerName']),
            _buildSummaryRow('UPI ID:', summary['upiId']),
            _buildSummaryRow('App:', summary['selectedApp'] ?? 'Not selected'),
            _buildSummaryRow('Description:', summary['description']),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton(PaymentProvider paymentProvider) {
    return ElevatedButton.icon(
      onPressed: paymentProvider.isLoading || !paymentProvider.isFormValid
          ? null
          : () => _handlePayment(paymentProvider),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      icon: paymentProvider.isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.payment),
      label: Text(
        paymentProvider.isLoading ? 'Processing...' : 'Pay Now',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildErrorCard(String errorMessage) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                errorMessage,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePayment(PaymentProvider paymentProvider) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final customerId = authProvider.userModel?.uid ?? 'unknown';

      final success = await paymentProvider.initiatePayment(
        orderId: widget.orderId,
        customerId: customerId,
        metadata: {
          'deviceInfo': await paymentProvider.getDeviceInfo(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PaymentStatusScreen(
              transaction: paymentProvider.currentTransaction!,
              isSuccess: success,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
} 