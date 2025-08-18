// screens/admin/manage_delivery_partners_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
// Removed unused import
import '../../services/delivery_partner_service.dart';

class ManageDeliveryPartnersScreen extends StatefulWidget {
  const ManageDeliveryPartnersScreen({super.key});

  @override
  State<ManageDeliveryPartnersScreen> createState() =>
      _ManageDeliveryPartnersScreenState();
}

class _ManageDeliveryPartnersScreenState
    extends State<ManageDeliveryPartnersScreen> {
  final DeliveryPartnerService _deliveryService = DeliveryPartnerService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        isExtended: true,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddDeliveryPartnerPage()),
          );
        },
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.add),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('delivery')
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delivery_dining, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No delivery partners found'),
                  Text('Tap + to add a new delivery partner'),
                ],
              ),
            );
          }

          final deliveryPartners = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: deliveryPartners.length,
            itemBuilder: (context, index) {
              final doc = deliveryPartners[index];
              final data = doc.data() as Map<String, dynamic>;
              final partnerId = doc.id;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        data['isActive'] == true ? Colors.green : Colors.red,
                    child: Text(
                      (data['name'] ?? 'N/A').substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(data['name'] ?? 'Unknown'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Phone: ${data['phoneNumber'] ?? 'N/A'}'),
                      Text('Email: ${data['email'] ?? 'N/A'}'),
                      Text('License: ${data['licenseNumber'] ?? 'N/A'}'),
                      Text('Aadhar: ${data['aadharNumber'] ?? 'N/A'}'),
                      Text('Code: ${data['loginCode'] ?? 'Not set'}'),
                      Text(
                        'Status: ${data['isActive'] == true ? 'Active' : 'Inactive'}',
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showEditDeliveryPartnerDialog(partnerId, data);
                          break;
                        case 'toggle_status':
                          _togglePartnerStatus(
                            partnerId,
                            data['isActive'] == true,
                          );
                          break;
                        case 'reset_code':
                          _showResetCodeDialog(partnerId, data);
                          break;
                        case 'delete':
                          _showDeleteConfirmation(
                            partnerId,
                            data['name'] ?? 'Unknown',
                          );
                          break;
                      }
                    },
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          PopupMenuItem(
                            value: 'toggle_status',
                            child: Text(
                              data['isActive'] == true
                                  ? 'Deactivate'
                                  : 'Activate',
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'reset_code',
                            child: Text('Reset Code'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddDeliveryPartnerDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final licenseController = TextEditingController();
    final aadharController = TextEditingController();
    final codeController = TextEditingController();
    bool isActive = true;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Delivery Partner'),
            content: StatefulBuilder(
              builder:
                  (context, setState) => SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number *',
                            hintText: '9876543210',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email Address *',
                            hintText: 'example@email.com',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: licenseController,
                          decoration: const InputDecoration(
                            labelText: 'Driving License Number *',
                            hintText: 'DL1234567890123',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: aadharController,
                          decoration: const InputDecoration(
                            labelText: 'Aadhar Number *',
                            hintText: '123456789012',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 12,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: codeController,
                          decoration: const InputDecoration(
                            labelText: 'Login Code *',
                            hintText: '4-6 digits',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                        ),
                        const SizedBox(height: 16),
                        CheckboxListTile(
                          title: const Text('Active'),
                          value: isActive,
                          onChanged:
                              (value) =>
                                  setState(() => isActive = value ?? true),
                        ),
                      ],
                    ),
                  ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed:
                    () => _addDeliveryPartner(
                      nameController.text,
                      phoneController.text,
                      emailController.text,
                      licenseController.text,
                      aadharController.text,
                      codeController.text,
                      isActive,
                    ),
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  void _showEditDeliveryPartnerDialog(
    String partnerId,
    Map<String, dynamic> data,
  ) {
    final nameController = TextEditingController(text: data['name']);
    final phoneController = TextEditingController(
      text: data['phoneNumber']?.replaceAll('+91', ''),
    );
    final emailController = TextEditingController(text: data['email']);
    final licenseController = TextEditingController(
      text: data['licenseNumber'],
    );
    final aadharController = TextEditingController(text: data['aadharNumber']);
    final codeController = TextEditingController(text: data['loginCode']);
    bool isActive = data['isActive'] == true;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Delivery Partner'),
            content: StatefulBuilder(
              builder:
                  (context, setState) => SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number *',
                            hintText: '9876543210',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email Address *',
                            hintText: 'example@email.com',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: licenseController,
                          decoration: const InputDecoration(
                            labelText: 'Driving License Number *',
                            hintText: 'DL1234567890123',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: aadharController,
                          decoration: const InputDecoration(
                            labelText: 'Aadhar Number *',
                            hintText: '123456789012',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 12,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: codeController,
                          decoration: const InputDecoration(
                            labelText: 'Login Code *',
                            hintText: '4-6 digits',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                        ),
                        const SizedBox(height: 16),
                        CheckboxListTile(
                          title: const Text('Active'),
                          value: isActive,
                          onChanged:
                              (value) =>
                                  setState(() => isActive = value ?? true),
                        ),
                      ],
                    ),
                  ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed:
                    () => _updateDeliveryPartner(
                      partnerId,
                      nameController.text,
                      phoneController.text,
                      emailController.text,
                      licenseController.text,
                      aadharController.text,
                      codeController.text,
                      isActive,
                    ),
                child: const Text('Update'),
              ),
            ],
          ),
    );
  }

  void _showResetCodeDialog(String partnerId, Map<String, dynamic> data) {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Reset Code for ${data['name']}'),
            content: TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'New Login Code *',
                hintText: '4-6 digits',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed:
                    () => _resetLoginCode(partnerId, codeController.text),
                child: const Text('Reset'),
              ),
            ],
          ),
    );
  }

  void _showDeleteConfirmation(String partnerId, String name) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Delivery Partner'),
            content: Text('Are you sure you want to delete $name?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => _deleteDeliveryPartner(partnerId),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  Future<void> _addDeliveryPartner(
    String name,
    String phone,
    String email,
    String license,
    String aadhar,
    String code,
    bool isActive,
  ) async {
    if (name.trim().isEmpty ||
        phone.trim().isEmpty ||
        email.trim().isEmpty ||
        license.trim().isEmpty ||
        aadhar.trim().isEmpty ||
        code.trim().isEmpty) {
      _showSnackBar('Please fill all required fields');
      return;
    }

    if (code.length < 4) {
      _showSnackBar('Code must be at least 4 digits');
      return;
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await _deliveryService.addDeliveryPartner(
        name: name.trim(),
        phoneNumber: phone.trim(),
        email: email.trim(),
        licenseNumber: license.trim(),
        aadharNumber: aadhar.trim(),
        loginCode: code.trim(),
        isActive: isActive,
        createdBy: authProvider.user?.uid ?? '',
        createdByRole: authProvider.userRole?.toString() ?? 'admin',
      );

      Navigator.pop(context);
      _showSnackBar('Delivery partner added successfully');
    } catch (e) {
      _showSnackBar('Error adding delivery partner: ${e.toString()}');
    }
  }

  Future<void> _updateDeliveryPartner(
    String partnerId,
    String name,
    String phone,
    String email,
    String license,
    String aadhar,
    String code,
    bool isActive,
  ) async {
    if (name.trim().isEmpty ||
        phone.trim().isEmpty ||
        email.trim().isEmpty ||
        license.trim().isEmpty ||
        aadhar.trim().isEmpty ||
        code.trim().isEmpty) {
      _showSnackBar('Please fill all required fields');
      return;
    }

    if (code.length < 4) {
      _showSnackBar('Code must be at least 4 digits');
      return;
    }

    try {
      await _deliveryService.updateDeliveryPartner(
        partnerId: partnerId,
        name: name.trim(),
        phoneNumber: phone.trim(),
        email: email.trim(),
        licenseNumber: license.trim(),
        aadharNumber: aadhar.trim(),
        loginCode: code.trim(),
        isActive: isActive,
      );

      Navigator.pop(context);
      _showSnackBar('Delivery partner updated successfully');
    } catch (e) {
      _showSnackBar('Error updating delivery partner: ${e.toString()}');
    }
  }

  Future<void> _togglePartnerStatus(
    String partnerId,
    bool currentStatus,
  ) async {
    try {
      await _deliveryService.togglePartnerStatus(partnerId, !currentStatus);
      _showSnackBar('Partner status updated successfully');
    } catch (e) {
      _showSnackBar('Error updating status: ${e.toString()}');
    }
  }

  Future<void> _resetLoginCode(String partnerId, String newCode) async {
    if (newCode.trim().isEmpty || newCode.length < 4) {
      _showSnackBar('Code must be at least 4 digits');
      return;
    }

    try {
      await _deliveryService.resetLoginCode(partnerId, newCode.trim());
      Navigator.pop(context);
      _showSnackBar('Login code reset successfully');
    } catch (e) {
      _showSnackBar('Error resetting code: ${e.toString()}');
    }
  }

  Future<void> _deleteDeliveryPartner(String partnerId) async {
    try {
      await _deliveryService.deleteDeliveryPartner(partnerId);
      Navigator.pop(context);
      _showSnackBar('Delivery partner deleted successfully');
    } catch (e) {
      _showSnackBar('Error deleting delivery partner: ${e.toString()}');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class AddDeliveryPartnerPage extends StatefulWidget {
  const AddDeliveryPartnerPage({super.key});

  @override
  State<AddDeliveryPartnerPage> createState() => _AddDeliveryPartnerPageState();
}

class _AddDeliveryPartnerPageState extends State<AddDeliveryPartnerPage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final licenseController = TextEditingController();
  final aadharController = TextEditingController();
  final codeController = TextEditingController();

  bool isActive = true;

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    licenseController.dispose();
    aadharController.dispose();
    codeController.dispose();
    super.dispose();
  }

  final DeliveryPartnerService _deliveryService = DeliveryPartnerService();

  Future<void> _addDeliveryPartner(
    String name,
    String phone,
    String email,
    String license,
    String aadhar,
    String code,
    bool isActive,
  ) async {
    if (name.trim().isEmpty ||
        phone.trim().isEmpty ||
        email.trim().isEmpty ||
        license.trim().isEmpty ||
        aadhar.trim().isEmpty ||
        code.trim().isEmpty) {
      _showSnackBar('Please fill all required fields');
      return;
    }

    if (code.length < 4) {
      _showSnackBar('Code must be at least 4 digits');
      return;
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await _deliveryService.addDeliveryPartner(
        name: name.trim(),
        phoneNumber: phone.trim(),
        email: email.trim(),
        licenseNumber: license.trim(),
        aadharNumber: aadhar.trim(),
        loginCode: code.trim(),
        isActive: isActive,
        createdBy: authProvider.user?.uid ?? '',
        createdByRole: authProvider.userRole?.toString() ?? 'admin',
      );

      Navigator.pop(context);
      _showSnackBar('Delivery partner added successfully');
    } catch (e) {
      _showSnackBar('Error adding delivery partner: ${e.toString()}');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Replace this with your actual function call
      _addDeliveryPartner(
        nameController.text,
        phoneController.text,
        emailController.text,
        licenseController.text,
        aadharController.text,
        codeController.text,
        isActive,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Delivery Partner'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (v) => v == null || v.isEmpty ? 'Enter full name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  hintText: '9876543210',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator:
                    (v) =>
                        v == null || v.length < 10 ? 'Enter valid phone' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address *',
                  hintText: 'example@email.com',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator:
                    (v) =>
                        v == null || !v.contains('@')
                            ? 'Enter valid email'
                            : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: licenseController,
                decoration: const InputDecoration(
                  labelText: 'Driving License Number *',
                  hintText: 'DL1234567890123',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (v) =>
                        v == null || v.isEmpty ? 'Enter license number' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: aadharController,
                decoration: const InputDecoration(
                  labelText: 'Aadhar Number *',
                  hintText: '123456789012',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                maxLength: 12,
                validator:
                    (v) =>
                        v == null || v.length != 12
                            ? 'Enter valid Aadhar'
                            : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Login Code *',
                  hintText: '4-6 digits',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
                validator:
                    (v) =>
                        v == null || v.length < 4
                            ? 'Code must be 4-6 digits'
                            : null,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Active'),
                value: isActive,
                onChanged: (v) => setState(() => isActive = v ?? true),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Add'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
