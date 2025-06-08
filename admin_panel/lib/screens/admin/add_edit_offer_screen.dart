import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp

// Assuming your models and services are here
// Adjust path as per your project structure, e.g.,
// import 'package:admin_panel/models/offer_model.dart';
// import 'package:admin_panel/services/offer_service.dart';
// import 'package:admin_panel/services/storage_service.dart';
import '../../models/offer_model.dart';
import '../../services/offer_service.dart';
import '../../services/storage_service.dart';

class AddEditOfferScreen extends StatefulWidget {
  final OfferModel? offer; // Pass null for adding, existing offer for editing

  const AddEditOfferScreen({Key? key, this.offer}) : super(key: key);

  @override
  _AddEditOfferScreenState createState() => _AddEditOfferScreenState();
}

class _AddEditOfferScreenState extends State<AddEditOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  final OfferService _offerService = OfferService();
  final StorageService _storageService = StorageService();

  // Form field controllers
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _promoCodeController;
  late TextEditingController _discountValueController;
  late TextEditingController _minOrderValueController;
  late TextEditingController _termsController;

  String _discountType = 'percentage'; // Default discount type
  bool _isActive = true;
  DateTime _validFrom = DateTime.now();
  DateTime _validTo = DateTime.now().add(Duration(days: 7)); // Default validity

  File? _selectedImageFile;
  String? _existingImageUrl; // For editing

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.offer?.title);
    _descriptionController = TextEditingController(text: widget.offer?.description);
    _promoCodeController = TextEditingController(text: widget.offer?.promoCode);
    _discountValueController = TextEditingController(text: widget.offer?.discountValue.toString());
    _minOrderValueController = TextEditingController(text: widget.offer?.minOrderValue?.toString());
    _termsController = TextEditingController(text: widget.offer?.termsAndConditions);

    if (widget.offer != null) {
      _discountType = widget.offer!.discountType;
      _isActive = widget.offer!.isActive;
      _validFrom = widget.offer!.validFrom.toDate();
      _validTo = widget.offer!.validTo.toDate();
      _existingImageUrl = widget.offer!.imageUrl;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _promoCodeController.dispose();
    _discountValueController.dispose();
    _minOrderValueController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImageFile = File(pickedFile.path);
        _existingImageUrl = null; // Clear existing image if new one is picked
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    await showDatePicker(
      context: context,
      initialDate: isFromDate ? _validFrom : _validTo,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    ).then((value) {
      if (value != null) {
        setState(() {
          if (isFromDate) {
            _validFrom = value;
          } else {
              _validTo = value;
          }
        });
      }
    });
  }

  Future<void> _saveOffer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();
    setState(() { _isLoading = true; });

    String? imageUrl = _existingImageUrl; 
    String offerIdForImageStorage = widget.offer?.id ?? FirebaseFirestore.instance.collection('offers').doc().id;


    if (_selectedImageFile != null) {
        // If editing and there was an old image different from the new one, delete it.
        if (widget.offer != null && widget.offer!.imageUrl.isNotEmpty && _existingImageUrl != widget.offer!.imageUrl) { // This condition might need refinement
             // Potentially delete widget.offer!.imageUrl if it's being replaced
             // await _storageService.deleteOfferImage(widget.offer!.imageUrl); // Be cautious with deletion logic
        }
        imageUrl = await _storageService.uploadOfferImage(_selectedImageFile!, offerIdForImageStorage);
        if (imageUrl == null) {
            setState(() { _isLoading = false; });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to upload image. Please try again.'))
              );
            }
            return;
        }
    }

    if (imageUrl == null || imageUrl.isEmpty) {
         setState(() { _isLoading = false; });
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Offer image is required.'))
           );
         }
         return;
    }


    OfferModel offerData = OfferModel(
      id: widget.offer?.id, 
      title: _titleController.text,
      description: _descriptionController.text,
      imageUrl: imageUrl,
      promoCode: _promoCodeController.text.isEmpty ? null : _promoCodeController.text,
      discountType: _discountType,
      discountValue: num.tryParse(_discountValueController.text) ?? 0,
      minOrderValue: num.tryParse(_minOrderValueController.text),
      validFrom: Timestamp.fromDate(_validFrom),
      validTo: Timestamp.fromDate(_validTo),
      isActive: _isActive,
      termsAndConditions: _termsController.text.isEmpty ? null : _termsController.text,
      createdAt: widget.offer?.createdAt ?? Timestamp.now(),
      updatedAt: Timestamp.now(),
    );

    bool success = false;
    String? operationError;

    if (widget.offer == null) { // New offer
      // For new offer, ensure offerData.id is null so Firestore generates one if `addOffer` doesn't handle it internally
      // Or, use the pre-generated offerIdForImageStorage if `addOffer` expects an ID.
      // Assuming `addOffer` creates a document and returns its ID, we pass `offerData` which might have `id: null`.
      // If your `addOffer` in `OfferService` takes `OfferModel offer` and creates a *new* document without needing an ID in `offerData`, it's fine.
      // If `addOffer` expects `offerData` to have an ID to use for the new document, then you should set `offerData.id = offerIdForImageStorage;` before calling.
      // Let's assume `addOffer` creates the document and returns its ID, or the ID isn't strictly needed back here immediately.
      
      // If we are creating a new offer, we should use the ID generated for image storage as the document ID.
      final newOfferWithId = OfferModel(
          id: offerIdForImageStorage, // Use the generated ID
          title: offerData.title,
          description: offerData.description,
          imageUrl: offerData.imageUrl,
          promoCode: offerData.promoCode,
          discountType: offerData.discountType,
          discountValue: offerData.discountValue,
          minOrderValue: offerData.minOrderValue,
          validFrom: offerData.validFrom,
          validTo: offerData.validTo,
          isActive: offerData.isActive,
          termsAndConditions: offerData.termsAndConditions,
          createdAt: offerData.createdAt,
          updatedAt: offerData.updatedAt
      );


      String? createdOfferId = await _offerService.addOffer(newOfferWithId); // addOffer should ideally take the model and use its ID, or ignore it if it auto-generates
      if (createdOfferId != null) {
        success = true;
      } else {
        operationError = "Failed to add offer.";
        // If image upload succeeded but Firestore failed, consider deleting the uploaded image.
        if (_selectedImageFile != null && imageUrl.isNotEmpty) {
          await _storageService.deleteOfferImage(imageUrl);
        }
      }
    } else { // Update existing offer
      // Ensure offerData has the correct ID for update
      offerData = OfferModel( // Reconstruct with the correct ID
          id: widget.offer!.id, // Crucial for update
          title: offerData.title,
          description: offerData.description,
          imageUrl: offerData.imageUrl,
          promoCode: offerData.promoCode,
          discountType: offerData.discountType,
          discountValue: offerData.discountValue,
          minOrderValue: offerData.minOrderValue,
          validFrom: offerData.validFrom,
          validTo: offerData.validTo,
isActive: offerData.isActive,
          termsAndConditions: offerData.termsAndConditions,
          createdAt: offerData.createdAt, // Keep original createdAt
          updatedAt: Timestamp.now() // Update updatedAt
      );
      success = await _offerService.updateOffer(offerData);
      if (!success) operationError = "Failed to update offer.";
    }

    setState(() { _isLoading = false; });

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Offer ${widget.offer == null ? "added" : "updated"} successfully!'))
        );
        Navigator.of(context).pop(); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(operationError ?? 'Failed to save offer. Please try again.'))
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.offer == null ? 'Add New Offer' : 'Edit Offer'),
        actions: [
          if (!_isLoading) IconButton(icon: const Icon(Icons.save), onPressed: _saveOffer),
          if (_isLoading) const Padding(padding: EdgeInsets.all(10.0), child: CircularProgressIndicator(color: Colors.white,)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              // --- Image Picker and Preview ---
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _isLoading && _selectedImageFile != null // Show loader on image during upload
                    ? Center(child: CircularProgressIndicator())
                    : _selectedImageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(7.0), // Match container border radius minus border width
                          child: Image.file(_selectedImageFile!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                        )
                      : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(7.0),
                              child: Image.network(_existingImageUrl!, fit: BoxFit.cover, width: double.infinity, height: double.infinity,
                                errorBuilder: (context, error, stackTrace) => Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey[700]))),
                            )
                          : Center(child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 50, color: Colors.grey[700]),
                                SizedBox(height: 8),
                                Text("Tap to select image", style: TextStyle(color: Colors.grey[700]))
                              ],
                            ))),
                ),
              ),
              SizedBox(height: 20),

              // --- Title ---
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Offer Title', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),

              // --- Description ---
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                maxLines: 3,
                validator: (value) => value == null || value.isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 16),

              // --- Promo Code (Optional) ---
              TextFormField(
                controller: _promoCodeController,
                decoration: const InputDecoration(labelText: 'Promo Code (Optional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Discount Type ---
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _discountType,
                      decoration: const InputDecoration(labelText: 'Discount Type', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'percentage', child: Text('Percentage (%)')),
                        DropdownMenuItem(value: 'fixed', child: Text('Fixed Amount')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() { _discountType = value; });
                        }
                      },
                       validator: (value) => value == null || value.isEmpty ? 'Please select a discount type' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // --- Discount Value ---
                  Expanded(
                    child: TextFormField(
                      controller: _discountValueController,
                      decoration: const InputDecoration(labelText: 'Discount Value', border: OutlineInputBorder()),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Enter value';
                        final num? numValue = num.tryParse(value);
                        if (numValue == null) return 'Valid number';
                        if (numValue <= 0) return 'Must be > 0';
                        if (_discountType == 'percentage' && numValue > 100) return 'Max 100%';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),


              // --- Min Order Value (Optional) ---
              TextFormField(
                controller: _minOrderValueController,
                decoration: const InputDecoration(labelText: 'Minimum Order Value (Optional)', border: OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final num? numValue = num.tryParse(value);
                    if (numValue == null) return 'Valid number or empty';
                    if (numValue < 0) return 'Cannot be negative';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // --- Valid From Date ---
               Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Valid From',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(DateFormat.yMMMd().format(_validFrom)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Valid To',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(DateFormat.yMMMd().format(_validTo)),
                      ),
                    ),
                  ),
                ],
              ),
              if (_validTo.isBefore(_validFrom))
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('"Valid To" date must be after "Valid From" date.', style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
                ),
              const SizedBox(height: 16),
              
              // --- Terms and Conditions (Optional) ---
              TextFormField(
                controller: _termsController,
                decoration: const InputDecoration(labelText: 'Terms and Conditions (Optional)', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // --- Is Active Switch ---
              SwitchListTile(
                title: const Text('Activate Offer'),
                value: _isActive,
                onChanged: (bool value) {
                  setState(() { _isActive = value; });
                },
                contentPadding: EdgeInsets.zero,
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                 tileColor: Colors.grey[100],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
} 