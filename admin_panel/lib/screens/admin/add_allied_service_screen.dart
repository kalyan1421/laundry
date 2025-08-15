// screens/admin/add_allied_service_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/allied_service_provider.dart';
import '../../models/allied_service_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class AddAlliedServiceScreen extends StatefulWidget {
  final AlliedServiceModel? service; // For editing existing service

  const AddAlliedServiceScreen({super.key, this.service});

  @override
  State<AddAlliedServiceScreen> createState() => _AddAlliedServiceScreenState();
}

class _AddAlliedServiceScreenState extends State<AddAlliedServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _unitController = TextEditingController();
  final _categoryController = TextEditingController();
  final _sortOrderController = TextEditingController();

  bool _isActive = true;
  bool _hasPrice = true;
  File? _selectedImage;
  String? _currentImageUrl;
  bool _removeCurrentImage = false;
  bool _isLoading = false;

  final List<String> _predefinedCategories = [
    'Allied Services',
    'Cleaning Services',
    'Special Services',
    'Premium Services',
  ];

  final List<String> _predefinedUnits = [
    'piece',
    'item',
    'set',
    'pair',
    'kg',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.service != null) {
      _populateFields();
    } else {
      // Set default values for new service
      _categoryController.text = 'Allied Services';
      _unitController.text = 'piece';
      _sortOrderController.text = '0';
    }
  }

  void _populateFields() {
    final service = widget.service!;
    _nameController.text = service.name;
    _descriptionController.text = service.description;
    _priceController.text = service.price.toString();
    _unitController.text = service.unit;
    _categoryController.text = service.category;
    _sortOrderController.text = service.sortOrder.toString();
    _isActive = service.isActive;
    _hasPrice = service.hasPrice;
    _currentImageUrl = service.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    _categoryController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _removeCurrentImage = false;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      if (_currentImageUrl != null) {
        _removeCurrentImage = true;
      }
    });
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<AlliedServiceProvider>(context, listen: false);

      if (widget.service == null) {
        // Adding new service
        final newService = AlliedServiceModel(
          id: '', // Will be set by Firestore
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: _hasPrice ? double.parse(_priceController.text) : 0.0,
          category: _categoryController.text.trim(),
          unit: _unitController.text.trim(),
          isActive: _isActive,
          hasPrice: _hasPrice,
          updatedAt: DateTime.now(),
          sortOrder: int.parse(_sortOrderController.text),
        );

        final success = await provider.addAlliedService(
          newService,
          imageFile: _selectedImage,
        );

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Allied service added successfully'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(provider.error ?? 'Failed to add service'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // Updating existing service
        final updateData = {
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'price': _hasPrice ? double.parse(_priceController.text) : 0.0,
          'category': _categoryController.text.trim(),
          'unit': _unitController.text.trim(),
          'isActive': _isActive,
          'hasPrice': _hasPrice,
          'updatedAt': DateTime.now(),
          'sortOrder': int.parse(_sortOrderController.text),
        };

        final success = await provider.updateAlliedService(
          widget.service!.id,
          updateData,
          newImageFile: _selectedImage,
          removeImage: _removeCurrentImage,
        );

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Allied service updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(provider.error ?? 'Failed to update service'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.service == null ? 'Add Allied Service' : 'Edit Allied Service'),
        backgroundColor: const Color(0xFF0F3057),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service Image Section
              const Text(
                'Service Image',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _selectedImage != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _selectedImage!,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              onPressed: _removeImage,
                              icon: const Icon(Icons.close),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      )
                    : (_currentImageUrl != null && !_removeCurrentImage)
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _currentImageUrl!,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                  onPressed: _removeImage,
                                  icon: const Icon(Icons.close),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : InkWell(
                            onTap: _pickImage,
                            child: Container(
                              width: double.infinity,
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Tap to add service image', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                          ),
              ),
              if (_selectedImage == null && _currentImageUrl == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Choose Image'),
                  ),
                ),

              const SizedBox(height: 24),

              // Service Details
              const Text(
                'Service Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _nameController,
                label: 'Service Name',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter service name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _descriptionController,
                label: 'Description',
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter service description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: _predefinedCategories.contains(_categoryController.text) 
                    ? _categoryController.text 
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _predefinedCategories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    _categoryController.text = value;
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Has Price Toggle
              Row(
                children: [
                  Checkbox(
                    value: _hasPrice,
                    onChanged: (value) {
                      setState(() {
                        _hasPrice = value ?? true;
                        if (!_hasPrice) {
                          _priceController.text = '0';
                        }
                      });
                    },
                  ),
                  const Text('Service has fixed price'),
                ],
              ),
              const SizedBox(height: 8),

              if (_hasPrice) ...[
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: CustomTextField(
                        controller: _priceController,
                        label: 'Price (₹)',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (_hasPrice && (value == null || value.trim().isEmpty)) {
                            return 'Please enter price';
                          }
                          if (_hasPrice && double.tryParse(value!) == null) {
                            return 'Please enter valid price';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _predefinedUnits.contains(_unitController.text) 
                            ? _unitController.text 
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          border: OutlineInputBorder(),
                        ),
                        items: _predefinedUnits.map((unit) {
                          return DropdownMenuItem(
                            value: unit,
                            child: Text(unit),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            _unitController.text = value;
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select unit';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              CustomTextField(
                controller: _sortOrderController,
                label: 'Sort Order',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter sort order';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Active Status Toggle
              Row(
                children: [
                  Checkbox(
                    value: _isActive,
                    onChanged: (value) {
                      setState(() {
                        _isActive = value ?? true;
                      });
                    },
                  ),
                  const Text('Service is active'),
                ],
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child:                 CustomButton(
                  text: _isLoading 
                      ? 'Saving...' 
                      : (widget.service == null ? 'Add Service' : 'Update Service'),
                  onPressed: () => _saveService(),
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}