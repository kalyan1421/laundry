import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/workshop_worker_service.dart';
import '../../models/workshop_worker_model.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../providers/auth_provider.dart';
import 'admin_home.dart';

class AddWorkshopWorkerScreen extends StatefulWidget {
  final WorkshopWorkerModel? worker; // For editing existing worker
  
  const AddWorkshopWorkerScreen({super.key, this.worker});

  @override
  State<AddWorkshopWorkerScreen> createState() => _AddWorkshopWorkerScreenState();
}

class _AddWorkshopWorkerScreenState extends State<AddWorkshopWorkerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _workshopLocationController = TextEditingController();
  final _aadharNumberController = TextEditingController();
  
  final WorkshopWorkerService _workerService = WorkshopWorkerService();
  
  bool _isLoading = false;
  String? _selectedShift;
  String? _aadharCardUrl;
  

  
  final List<String> _availableShifts = [
    'morning',
    'afternoon',
    'night',
    'full_day',
  ];

  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }

  void _initializeFormData() {
    if (widget.worker != null) {
      // Populate form fields for editing
      final worker = widget.worker!;
      _nameController.text = worker.name;
      _emailController.text = worker.email ?? '';
      _phoneController.text = worker.phoneNumber;
      _employeeIdController.text = worker.employeeId;
      _hourlyRateController.text = worker.hourlyRate.toString();
      _workshopLocationController.text = worker.workshopLocation;
      _aadharNumberController.text = worker.aadharNumber ?? '';
      _aadharCardUrl = worker.aadharCardUrl;
      _selectedShift = worker.shift;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _employeeIdController.dispose();
    _hourlyRateController.dispose();
    _workshopLocationController.dispose();
    _aadharNumberController.dispose();
    super.dispose();
  }

  Future<void> _saveWorkshopWorker() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String phoneNumber = _phoneController.text.trim();
      String email = _emailController.text.trim();
      String employeeId = _employeeIdController.text.trim().toUpperCase();
      String aadharNumber = _aadharNumberController.text.trim();
      
      bool isEditing = widget.worker != null;

      if (!isEditing) {
        // For new workers, check availability
        
        // Check if phone is available
        bool phoneAvailable = await _workerService.isPhoneNumberAvailable(phoneNumber);
        if (!phoneAvailable && mounted) {
          _showMessage('Phone number is already registered', isError: true);
          return;
        }

        // Check if email is available
        bool emailAvailable = await _workerService.isEmailAvailable(email);
        if (!emailAvailable && mounted) {
          _showMessage('Email is already registered', isError: true);
          return;
        }

        // Check if employee ID is available
        bool employeeIdAvailable = await _workerService.isEmployeeIdAvailable(employeeId);
        if (!employeeIdAvailable && mounted) {
          _showMessage('Employee ID is already registered', isError: true);
          return;
        }
      } else {
        // For editing, check availability but exclude current worker
        final currentWorker = widget.worker!;
        
        if (phoneNumber != currentWorker.phoneNumber) {
          bool phoneAvailable = await _workerService.isPhoneNumberAvailable(phoneNumber);
          if (!phoneAvailable && mounted) {
            _showMessage('Phone number is already registered', isError: true);
            return;
          }
        }

        if (email != currentWorker.email) {
          bool emailAvailable = await _workerService.isEmailAvailable(email);
          if (!emailAvailable && mounted) {
            _showMessage('Email is already registered', isError: true);
            return;
          }
        }

        if (employeeId != currentWorker.employeeId) {
          bool employeeIdAvailable = await _workerService.isEmployeeIdAvailable(employeeId);
          if (!employeeIdAvailable && mounted) {
            _showMessage('Employee ID is already registered', isError: true);
            return;
          }
        }
      }

      // Parse hourly rate
      double hourlyRate = 0.0;
      if (_hourlyRateController.text.trim().isNotEmpty) {
        hourlyRate = double.tryParse(_hourlyRateController.text.trim()) ?? 0.0;
      }

      if (isEditing) {
        // Update existing worker
        Map<String, dynamic> updateData = {
          'name': _nameController.text.trim(),
          'phoneNumber': phoneNumber,
          'employeeId': employeeId,
          'workshopLocation': _workshopLocationController.text.trim().isNotEmpty 
              ? _workshopLocationController.text.trim() 
              : '',
          'hourlyRate': hourlyRate,
          'shift': _selectedShift ?? 'morning',
          'updatedAt': DateTime.now(),
        };

        // Add email only if provided
        if (email.isNotEmpty) {
          updateData['email'] = email;
        }

        // Add Aadhar details if provided
        if (aadharNumber.isNotEmpty) {
          updateData['aadharNumber'] = aadharNumber;
        }
        if (_aadharCardUrl != null) {
          updateData['aadharCardUrl'] = _aadharCardUrl;
        }

        await _workerService.updateWorkshopWorker(widget.worker!.id, updateData);
        
        if (mounted) {
          _showMessage('Workshop worker updated successfully!', isError: false);
          Navigator.of(context).pop(); // Go back to management screen
        }
      } else {
        // Create new worker
        final authProvider = context.read<AuthProvider>();
        String? createdByUid = authProvider.user?.uid;

        WorkshopWorkerModel? newWorker = await _workerService.createWorkshopWorkerByAdmin(
          name: _nameController.text.trim(),
          email: email.isNotEmpty ? email : null,
          phoneNumber: phoneNumber,
          employeeId: employeeId,
          workshopLocation: _workshopLocationController.text.trim().isNotEmpty 
              ? _workshopLocationController.text.trim() 
              : null,
          hourlyRate: hourlyRate,
          shift: _selectedShift,
          aadharNumber: aadharNumber.isNotEmpty ? aadharNumber : null,
          aadharCardUrl: _aadharCardUrl,
          createdByUid: createdByUid,
        );

        if (newWorker != null && mounted) {
          _showMessage('Workshop worker created successfully!', isError: false);
          
          // Show instructions dialog
          _showInstructionsDialog(newWorker);
          
          // Clear form
          _clearForm();
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Failed to ${widget.worker != null ? 'update' : 'create'} workshop worker: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showInstructionsDialog(WorkshopWorkerModel worker) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Worker Created Successfully',
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Workshop worker "${worker.name}" has been created successfully.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              if (worker.registrationToken != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.key, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Registration Token:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green[300]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              worker.registrationToken!,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 20),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: worker.registrationToken!),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Registration token copied to clipboard'),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Share this token with the worker for first-time login',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Login Instructions for ${worker.name}:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInstructionItem('1', 'Download the workshop worker app'),
                    _buildInstructionItem('2', 'Select "Workshop Worker" role during login'),
                    _buildInstructionItem('3', 'Enter phone number: ${worker.formattedPhone}'),
                    _buildInstructionItem('4', 'Verify with the OTP received on the phone'),
                    _buildInstructionItem(
                      '5',
                      'Enter the one-time registration token shown above',
                    ),
                    _buildInstructionItem('6', 'Complete profile setup if required'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The worker must have access to the registered phone number to receive OTP for login.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                        ),
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
              Navigator.of(context).pop();
            },
            child: const Text('Add Another'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const AdminHome(),
                ),
              );
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String number, String instruction) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.blue[100],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              instruction,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _employeeIdController.clear();
    _hourlyRateController.clear();
    _workshopLocationController.clear();
    _aadharNumberController.clear();
    setState(() {
      _selectedShift = null;
      _aadharCardUrl = null;
    });
  }

  void _showMessage(String message, {required bool isError}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.worker != null ? 'Edit Workshop Worker' : 'Add Workshop Worker'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Icon(
                Icons.engineering,
                size: 60,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              Text(
                widget.worker != null ? 'Edit Workshop Worker' : 'Add New Workshop Worker',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.worker != null 
                    ? 'Update workshop worker information and settings.'
                    : 'Create a new workshop worker account. They will login using their phone number.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),

              // Form fields
              CustomTextField(
                controller: _nameController,
                label: 'Full Name',
                prefixIcon: Icons.person,
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter full name';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _emailController,
                label: 'Email Address (Optional)',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  // Email is optional, so only validate if provided
                  if (value != null && value.trim().isNotEmpty) {
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _phoneController,
                label: 'Phone Number',
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter phone number';
                  }
                  if (value.trim().length < 10) {
                    return 'Phone number must be at least 10 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _employeeIdController,
                label: 'Employee ID',
                prefixIcon: Icons.badge,
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter employee ID';
                  }
                  if (value.trim().length < 3) {
                    return 'Employee ID must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _hourlyRateController,
                label: 'Hourly Rate (₹)',
                prefixIcon: Icons.currency_rupee,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid hourly rate';
                    }
                    if (double.parse(value) < 0) {
                      return 'Hourly rate cannot be negative';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _workshopLocationController,
                label: 'Workshop Location (Optional)',
                prefixIcon: Icons.location_on,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              
              // Aadhar Number Input
              CustomTextField(
                controller: _aadharNumberController,
                label: 'Aadhar Number (Optional)',
                prefixIcon: Icons.credit_card,
                keyboardType: TextInputType.number,
                validator: (value) {
                  // Aadhar is optional, so only validate if provided
                  if (value != null && value.trim().isNotEmpty) {
                    if (value.trim().length != 12) {
                      return 'Aadhar number must be 12 digits';
                    }
                    if (!RegExp(r'^\d{12}$').hasMatch(value.trim())) {
                      return 'Aadhar number must contain only digits';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Aadhar Card Upload
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.upload_file, color: Colors.grey[600]),
                      title: Text(
                        'Aadhar Card Upload (Optional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      subtitle: Text(
                        _aadharCardUrl != null 
                            ? 'Aadhar card uploaded' 
                            : 'Upload Aadhar card image',
                        style: TextStyle(
                          fontSize: 12,
                          color: _aadharCardUrl != null ? Colors.green : Colors.grey[600],
                        ),
                      ),
                      trailing: _aadharCardUrl != null
                          ? Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      onTap: () {
                        // TODO: Implement file upload functionality
                        _showMessage('File upload functionality will be implemented', isError: false);
                      },
                    ),
                    if (_aadharCardUrl != null) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.delete, color: Colors.red[600]),
                        title: Text(
                          'Remove Aadhar Card',
                          style: TextStyle(color: Colors.red[600]),
                        ),
                        onTap: () {
                          setState(() {
                            _aadharCardUrl = null;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Shift selection
              Text(
                'Work Shift',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedShift,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedShift = newValue;
                    });
                  },
                  items: _availableShifts.map((String shift) {
                    return DropdownMenuItem<String>(
                      value: shift,
                      child: Text(_getShiftDisplayName(shift)),
                    );
                  }).toList(),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: InputBorder.none,
                    hintText: 'Select work shift',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              const SizedBox(height: 32),
              
              // Save button
              CustomButton(
                text: widget.worker != null ? 'Update Workshop Worker' : 'Create Workshop Worker',
                onPressed: _saveWorkshopWorker,
                isLoading: _isLoading,
              ),
              
              const SizedBox(height: 16),
              
              // Info text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Important Information:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• The workshop worker will login using their phone number',
                      style: TextStyle(fontSize: 12),
                    ),
                    const Text(
                      '• OTP will be sent to their phone for verification',
                      style: TextStyle(fontSize: 12),
                    ),
                    const Text(
                      '• They must have access to the registered phone number',
                      style: TextStyle(fontSize: 12),
                    ),
                    const Text(
                      '• All details can be updated later by the worker',
                      style: TextStyle(fontSize: 12),
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
  
  String _getShiftDisplayName(String shift) {
    switch (shift) {
      case 'morning':
        return 'Morning (6 AM - 2 PM)';
      case 'afternoon':
        return 'Afternoon (2 PM - 10 PM)';
      case 'night':
        return 'Night (10 PM - 6 AM)';
      case 'full_day':
        return 'Full Day (6 AM - 6 PM)';
      default:
        return shift;
    }
  }
} 