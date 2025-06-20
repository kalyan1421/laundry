import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final List<PaymentMethod> _paymentMethods = [
    PaymentMethod(
      id: '1',
      type: PaymentType.card,
      title: '**** 1234',
      subtitle: 'Visa • Expires 12/25',
      isDefault: true,
    ),
    PaymentMethod(
      id: '2',
      type: PaymentType.upi,
      title: 'user@paytm',
      subtitle: 'UPI ID',
      isDefault: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Payment Methods'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddPaymentDialog(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Payment Methods List
            Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Saved Payment Methods',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F3057),
                      ),
                    ),
                  ),
                  if (_paymentMethods.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.payment,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No payment methods added',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Add a payment method to make checkout faster',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _paymentMethods.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final method = _paymentMethods[index];
                        return _buildPaymentMethodTile(method);
                      },
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Add New Payment Method
            Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Add New Payment Method',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F3057),
                      ),
                    ),
                  ),
                  _buildAddMethodOption(
                    Icons.credit_card,
                    'Add Debit/Credit Card',
                    'Add a new card for payments',
                    () => _showAddCardDialog(),
                  ),
                  _buildAddMethodOption(
                    Icons.account_balance,
                    'Add UPI ID',
                    'Link your UPI ID for quick payments',
                    () => _showAddUPIDialog(),
                  ),
                  _buildAddMethodOption(
                    Icons.account_balance_wallet,
                    'Add Wallet',
                    'Link your digital wallet',
                    () => _showAddWalletDialog(),
                  ),
                  _buildAddMethodOption(
                    Icons.business,
                    'Net Banking',
                    'Pay directly from your bank account',
                    () => _showNetBankingInfo(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Payment Security Info
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Security',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F3057),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSecurityInfo(
                    Icons.security,
                    'Secure Payments',
                    'All payments are processed securely using industry-standard encryption.',
                  ),
                  _buildSecurityInfo(
                    Icons.verified_user,
                    'PCI Compliant',
                    'We are PCI DSS compliant to ensure your card details are safe.',
                  ),
                  _buildSecurityInfo(
                    Icons.lock,
                    'No Storage',
                    'We do not store your card details on our servers.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile(PaymentMethod method) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getPaymentTypeColor(method.type).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _getPaymentTypeIcon(method.type),
          color: _getPaymentTypeColor(method.type),
          size: 20,
        ),
      ),
      title: Row(
        children: [
          Text(
            method.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (method.isDefault) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Default',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(method.subtitle),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) {
          switch (value) {
            case 'default':
              _setAsDefault(method);
              break;
            case 'edit':
              _editPaymentMethod(method);
              break;
            case 'delete':
              _deletePaymentMethod(method);
              break;
          }
        },
        itemBuilder: (context) => [
          if (!method.isDefault)
            const PopupMenuItem(
              value: 'default',
              child: Text('Set as Default'),
            ),
          const PopupMenuItem(
            value: 'edit',
            child: Text('Edit'),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddMethodOption(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildSecurityInfo(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.green[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPaymentTypeIcon(PaymentType type) {
    switch (type) {
      case PaymentType.card:
        return Icons.credit_card;
      case PaymentType.upi:
        return Icons.account_balance;
      case PaymentType.wallet:
        return Icons.account_balance_wallet;
      case PaymentType.netbanking:
        return Icons.business;
    }
  }

  Color _getPaymentTypeColor(PaymentType type) {
    switch (type) {
      case PaymentType.card:
        return Colors.blue;
      case PaymentType.upi:
        return Colors.orange;
      case PaymentType.wallet:
        return Colors.purple;
      case PaymentType.netbanking:
        return Colors.green;
    }
  }

  void _showAddPaymentDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Payment Method',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildAddMethodOption(
                      Icons.credit_card,
                      'Debit/Credit Card',
                      'Add a new card',
                      () {
                        Navigator.pop(context);
                        _showAddCardDialog();
                      },
                    ),
                    _buildAddMethodOption(
                      Icons.account_balance,
                      'UPI ID',
                      'Link your UPI ID',
                      () {
                        Navigator.pop(context);
                        _showAddUPIDialog();
                      },
                    ),
                    _buildAddMethodOption(
                      Icons.account_balance_wallet,
                      'Digital Wallet',
                      'Link your wallet',
                      () {
                        Navigator.pop(context);
                        _showAddWalletDialog();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCardDialog() {
    final formKey = GlobalKey<FormState>();
    final cardNumberController = TextEditingController();
    final expiryController = TextEditingController();
    final cvvController = TextEditingController();
    final holderNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Debit/Credit Card'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: cardNumberController,
                decoration: const InputDecoration(
                  labelText: 'Card Number',
                  hintText: '1234 5678 9012 3456',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16),
                ],
                validator: (value) {
                  if (value == null || value.length < 16) {
                    return 'Please enter a valid card number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: holderNameController,
                decoration: const InputDecoration(
                  labelText: 'Cardholder Name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter cardholder name';
                  }
                  return null;
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: expiryController,
                      decoration: const InputDecoration(
                        labelText: 'MM/YY',
                        hintText: '12/25',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      validator: (value) {
                        if (value == null || value.length < 4) {
                          return 'Invalid expiry';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: cvvController,
                      decoration: const InputDecoration(
                        labelText: 'CVV',
                        hintText: '123',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      validator: (value) {
                        if (value == null || value.length < 3) {
                          return 'Invalid CVV';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                _addPaymentMethod(PaymentMethod(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  type: PaymentType.card,
                  title: '**** ${cardNumberController.text.substring(12)}',
                  subtitle: 'Card • Expires ${expiryController.text}',
                  isDefault: _paymentMethods.isEmpty,
                ));
              }
            },
            child: const Text('Add Card'),
          ),
        ],
      ),
    );
  }

  void _showAddUPIDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add UPI ID'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'UPI ID',
            hintText: 'yourname@paytm',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context);
                _addPaymentMethod(PaymentMethod(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  type: PaymentType.upi,
                  title: controller.text,
                  subtitle: 'UPI ID',
                  isDefault: _paymentMethods.isEmpty,
                ));
              }
            },
            child: const Text('Add UPI'),
          ),
        ],
      ),
    );
  }

  void _showAddWalletDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Wallet integration coming soon!')),
    );
  }

  void _showNetBankingInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Net Banking'),
        content: const Text(
          'Net Banking option will be available during checkout. You can select your bank and complete the payment securely.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _addPaymentMethod(PaymentMethod method) {
    setState(() {
      _paymentMethods.add(method);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment method added successfully')),
    );
  }

  void _setAsDefault(PaymentMethod method) {
    setState(() {
      for (var m in _paymentMethods) {
        m.isDefault = m.id == method.id;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Default payment method updated')),
    );
  }

  void _editPaymentMethod(PaymentMethod method) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit functionality coming soon!')),
    );
  }

  void _deletePaymentMethod(PaymentMethod method) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment Method'),
        content: Text('Are you sure you want to delete ${method.title}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _paymentMethods.remove(method);
                if (method.isDefault && _paymentMethods.isNotEmpty) {
                  _paymentMethods.first.isDefault = true;
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment method deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

enum PaymentType {
  card,
  upi,
  wallet,
  netbanking,
}

class PaymentMethod {
  final String id;
  final PaymentType type;
  final String title;
  final String subtitle;
  bool isDefault;

  PaymentMethod({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.isDefault,
  });
} 