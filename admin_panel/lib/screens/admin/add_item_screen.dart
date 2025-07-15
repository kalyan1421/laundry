// screens/add_item_screen.dart
import 'package:admin_panel/models/item_model.dart';
import 'package:admin_panel/providers/item_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';

class AddItemScreen extends StatefulWidget {
  final ItemModel? item; // For editing existing item
  
  const AddItemScreen({Key? key, this.item}) : super(key: key);

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _offerPriceController = TextEditingController();
  final _positionController = TextEditingController();
  
  bool _isActive = true;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _removeCurrentImage = false;

  // Predefined ironing items
  final List<String> _ironingItems = [
    'Shirt',
    'Pant', 
    'Churidar',
    'Churidar Pant',
    'Saree',
    'Blouse',
    'Special',
    'T-Shirt',
    'Jeans',
    'Kurti',
    'Dupatta',
    'Bed Sheet',
    'Pillow Cover'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      // Pre-fill form for editing
      _nameController.text = widget.item!.name;
      _priceController.text = widget.item!.price.toString();
      _originalPriceController.text = widget.item!.originalPrice?.toString() ?? '';
      _offerPriceController.text = widget.item!.offerPrice?.toString() ?? '';
      _positionController.text = widget.item!.sortOrder.toString();
      _isActive = widget.item!.isActive;
    }
    
    // Add listeners to update the calculator when prices change
    _originalPriceController.addListener(() => setState(() {}));
    _offerPriceController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _offerPriceController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _removeCurrentImage = false; // Reset removal flag when new image is selected
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _removeCurrentImage = false; // Reset removal flag when new image is selected
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking photo: $e')),
      );
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              if (_selectedImage != null || widget.item?.imageUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Image', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImage = null;
                      _removeCurrentImage = true;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final itemProvider = Provider.of<ItemProvider>(context, listen: false);

    try {
      if (widget.item == null) {
        // Adding new item
        final newItem = ItemModel(
          id: '', // Will be set by Firestore
          name: _nameController.text.trim(),
          price: double.parse(_priceController.text),
          originalPrice: _originalPriceController.text.isNotEmpty ? double.parse(_originalPriceController.text) : null,
          offerPrice: _offerPriceController.text.isNotEmpty ? double.parse(_offerPriceController.text) : null,
          category: 'Ironing', // Fixed category for ironing service
          unit: 'piece', // Fixed unit for ironing items
          isActive: _isActive,
          updatedAt: DateTime.now(),
          sortOrder: _positionController.text.isNotEmpty ? int.parse(_positionController.text) : 0,
        );

        final success = await itemProvider.addItem(newItem, imageFile: _selectedImage);
        
        if (success) {
          Navigator.pop(context, true); // Return true to indicate success
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Item added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception(itemProvider.error ?? 'Failed to add item');
        }
      } else {
        // Updating existing item
        final updateData = {
          'name': _nameController.text.trim(),
          'price': double.parse(_priceController.text),
          'originalPrice': _originalPriceController.text.isNotEmpty ? double.parse(_originalPriceController.text) : null,
          'offerPrice': _offerPriceController.text.isNotEmpty ? double.parse(_offerPriceController.text) : null,
          'sortOrder': _positionController.text.isNotEmpty ? int.parse(_positionController.text) : 0,
          'isActive': _isActive,
          'updatedAt': DateTime.now(),
        };

        final success = await itemProvider.updateItem(
          widget.item!.id,
          updateData,
          newImageFile: _selectedImage,
          removeImage: _removeCurrentImage,
        );

        if (success) {
          Navigator.pop(context, true); // Return true to indicate success
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Item updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception(itemProvider.error ?? 'Failed to update item');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _calculateSavings() {
    if (_originalPriceController.text.isNotEmpty && _offerPriceController.text.isNotEmpty) {
      final originalPrice = double.tryParse(_originalPriceController.text) ?? 0;
      final offerPrice = double.tryParse(_offerPriceController.text) ?? 0;
      return (originalPrice - offerPrice).toStringAsFixed(2);
    }
    return '0.00';
  }

  String _calculateDiscountPercentage() {
    if (_originalPriceController.text.isNotEmpty && _offerPriceController.text.isNotEmpty) {
      final originalPrice = double.tryParse(_originalPriceController.text) ?? 0;
      final offerPrice = double.tryParse(_offerPriceController.text) ?? 0;
      if (originalPrice > 0) {
        final discount = ((originalPrice - offerPrice) / originalPrice) * 100;
        return discount.toStringAsFixed(1);
      }
    }
    return '0.0';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Add Ironing Item' : 'Edit Ironing Item'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Item Image',
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _showImagePickerOptions,
                        child: Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!, width: 2),
                          ),
                          child: _selectedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : widget.item?.imageUrl != null && !_removeCurrentImage
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: CachedNetworkImage(
                                        imageUrl: widget.item!.imageUrl!,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                        errorWidget: (context, url, error) => const Icon(
                                          Icons.iron,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    )
                                  : const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_a_photo,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Tap to add image',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),

              // Item Name with Dropdown
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Item Details',
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Item Name Field with Dropdown
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Item Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.iron, color: Colors.blue),
                          suffixIcon: PopupMenuButton<String>(
                            icon: const Icon(Icons.arrow_drop_down),
                            onSelected: (String item) {
                              _nameController.text = item;
                            },
                            itemBuilder: (BuildContext context) {
                              return _ironingItems.map((String item) {
                                return PopupMenuItem<String>(
                                  value: item,
                                  child: Text(item),
                                );
                              }).toList();
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter item name';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Price Field
                      TextFormField(
                        controller: _priceController,
                        decoration: InputDecoration(
                          labelText: 'Price per piece (₹)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.currency_rupee, color: Colors.green),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter price';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter valid price';
                          }
                          if (double.parse(value) <= 0) {
                            return 'Price must be greater than 0';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Original Price Field
                      TextFormField(
                        controller: _originalPriceController,
                        decoration: InputDecoration(
                          labelText: 'Original Price (₹) - Optional',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.money, color: Colors.orange),
                          helperText: 'Enter original price for discount display',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            if (double.tryParse(value) == null) {
                              return 'Please enter valid price';
                            }
                            if (double.parse(value) <= 0) {
                              return 'Original price must be greater than 0';
                            }
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Offer Price Field
                      TextFormField(
                        controller: _offerPriceController,
                        decoration: InputDecoration(
                          labelText: 'Offer Price (₹) - Optional',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.local_offer, color: Colors.red),
                          helperText: 'Enter special offer price',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            if (double.tryParse(value) == null) {
                              return 'Please enter valid price';
                            }
                            if (double.parse(value) <= 0) {
                              return 'Offer price must be greater than 0';
                            }
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Position Field
                      TextFormField(
                        controller: _positionController,
                        decoration: InputDecoration(
                          labelText: 'Display Position',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.sort, color: Colors.blue),
                          helperText: 'Enter position number for item ordering (e.g., 1, 2, 3...)',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            if (int.tryParse(value) == null) {
                              return 'Please enter valid position number';
                            }
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Calculate Available Price Button
                      if (_originalPriceController.text.isNotEmpty && _offerPriceController.text.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.calculate, color: Colors.green),
                              const SizedBox(height: 4),
                              Text(
                                'Savings: ₹${_calculateSavings()}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              Text(
                                '${_calculateDiscountPercentage()}% OFF',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Active Status
                      SwitchListTile(
                        title: const Text('Active Status'),
                        subtitle: Text(
                          _isActive ? 'Item is available for service' : 'Item is not available',
                          style: TextStyle(
                            color: _isActive ? Colors.green : Colors.red,
                          ),
                        ),
                        value: _isActive,
                        activeColor: Colors.blue,
                        onChanged: (bool value) {
                          setState(() {
                            _isActive = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        widget.item == null ? 'Add Item' : 'Update Item',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}