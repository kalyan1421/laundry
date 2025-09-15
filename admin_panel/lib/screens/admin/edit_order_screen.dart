import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/order_model.dart';
import '../../models/item_model.dart';
import '../../models/allied_service_model.dart';

class AdminEditOrderScreen extends StatefulWidget {
  final OrderModel order;

  const AdminEditOrderScreen({super.key, required this.order});

  @override
  State<AdminEditOrderScreen> createState() => _AdminEditOrderScreenState();
}

class _AdminEditOrderScreenState extends State<AdminEditOrderScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // For ironing services
  Map<String, int> _selectedItems = {};
  List<ItemModel> _availableItems = [];
  
  // For allied services  
  Map<String, int> _selectedAlliedServices = {};
  List<AlliedServiceModel> _availableAlliedServices = [];
  
  bool _isLoading = true;
  bool _isSaving = false;
  double _totalAmount = 0.0;
  String? _specialInstructions;
  
  // Determine if this is an allied service or ironing service
  bool get _isAlliedService => widget.order.serviceType?.toLowerCase().contains('allied') ?? false;

  @override
  void initState() {
    super.initState();
    _initializeCurrentItems();
    _fetchAvailableItems();
  }

  void _initializeCurrentItems() {
    // Initialize with current order items
    for (var item in widget.order.items) {
      String itemName = item['name'] ?? '';
      int quantity = item['quantity'] ?? 0;
      if (itemName.isNotEmpty && quantity > 0) {
        if (_isAlliedService) {
          _selectedAlliedServices[itemName] = quantity;
        } else {
          _selectedItems[itemName] = quantity;
        }
      }
    }
    _specialInstructions = widget.order.specialInstructions;
    _calculateTotal();
  }

  Future<void> _fetchAvailableItems() async {
    try {
      if (_isAlliedService) {
        // Fetch allied services only
        QuerySnapshot alliedSnapshot = await _firestore
            .collection('allied_services')
            .where('isActive', isEqualTo: true)
            .orderBy('sortOrder')
            .get();

        _availableAlliedServices = alliedSnapshot.docs
            .map((doc) => AlliedServiceModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList();
      } else {
        // Fetch regular ironing items only
        QuerySnapshot itemsSnapshot = await _firestore
            .collection('items')
            .where('isActive', isEqualTo: true)
            .orderBy('sortOrder')
            .get();

        _availableItems = itemsSnapshot.docs
            .map((doc) => ItemModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .where((item) => item.category.toLowerCase().contains('iron') || item.category.toLowerCase() == 'ironing')
            .toList();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching items: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load items. Please try again.');
    }
  }


  void _calculateTotal() {
    double total = 0.0;
    
    if (_isAlliedService) {
      // Calculate total for allied services
      for (String serviceName in _selectedAlliedServices.keys) {
        int quantity = _selectedAlliedServices[serviceName] ?? 0;
        AlliedServiceModel? service = _availableAlliedServices.firstWhere(
          (service) => service.name == serviceName,
          orElse: () => AlliedServiceModel(
            id: '',
            name: serviceName,
            description: '',
            price: 0.0,
            category: 'Allied Services',
            subCategory: 'Allied Services',
            unit: 'piece',
            isActive: true,
            hasPrice: true,
            updatedAt: DateTime.now(),
          ),
        );
        final effectivePrice = service.offerPrice ?? service.price;
        total += effectivePrice * quantity;
      }
    } else {
      // Calculate total for ironing items
      for (String itemName in _selectedItems.keys) {
        int quantity = _selectedItems[itemName] ?? 0;
        ItemModel? item = _availableItems.firstWhere(
          (item) => item.name == itemName,
          orElse: () => ItemModel(
            id: '',
            name: itemName,
            category: '',
            price: 0.0,
            unit: 'piece',
            isActive: true,
            updatedAt: DateTime.now(),
          ),
        );
        final effectivePrice = item.offerPrice ?? item.price;
        total += effectivePrice * quantity;
      }
    }
    
    setState(() {
      _totalAmount = total;
    });
  }

  void _updateItemQuantity(String itemName, int newQuantity) {
    setState(() {
      if (_isAlliedService) {
        if (newQuantity <= 0) {
          _selectedAlliedServices.remove(itemName);
        } else {
          _selectedAlliedServices[itemName] = newQuantity;
        }
      } else {
        if (newQuantity <= 0) {
          _selectedItems.remove(itemName);
        } else {
          _selectedItems[itemName] = newQuantity;
        }
      }
    });
    _calculateTotal();
  }

  int _getCurrentQuantity(String itemName) {
    if (_isAlliedService) {
      return _selectedAlliedServices[itemName] ?? 0;
    } else {
      return _selectedItems[itemName] ?? 0;
    }
  }

  int get _totalSelectedItems {
    if (_isAlliedService) {
      return _selectedAlliedServices.values.fold(0, (sum, quantity) => sum + quantity);
    } else {
      return _selectedItems.values.fold(0, (sum, quantity) => sum + quantity);
    }
  }

  bool get _hasSelectedItems {
    if (_isAlliedService) {
      return _selectedAlliedServices.isNotEmpty;
    } else {
      return _selectedItems.isNotEmpty;
    }
  }

  Future<void> _saveChanges() async {
    if (!_hasSelectedItems) {
      _showErrorSnackBar('Please select at least one item');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Prepare updated items list
      List<Map<String, dynamic>> updatedItems = [];
      
      if (_isAlliedService) {
        // Handle allied services
        for (String serviceName in _selectedAlliedServices.keys) {
          int quantity = _selectedAlliedServices[serviceName] ?? 0;
          AlliedServiceModel service = _availableAlliedServices.firstWhere(
            (service) => service.name == serviceName,
            orElse: () => AlliedServiceModel(
              id: '',
              name: serviceName,
              description: '',
              price: 0.0,
              category: 'Allied Services',
              subCategory: 'Allied Services',
              unit: 'piece',
              isActive: true,
              hasPrice: true,
              updatedAt: DateTime.now(),
            ),
          );
          
          updatedItems.add({
            'itemId': service.id,
            'name': service.name,
            'quantity': quantity,
            'pricePerPiece': service.offerPrice ?? service.price,
            'offerPrice': service.offerPrice,
            'category': service.category,
            'unit': service.unit,
          });
        }
      } else {
        // Handle ironing items
        for (String itemName in _selectedItems.keys) {
          int quantity = _selectedItems[itemName] ?? 0;
          ItemModel item = _availableItems.firstWhere(
            (item) => item.name == itemName,
            orElse: () => ItemModel(
              id: '',
              name: itemName,
              category: '',
              price: 0.0,
              unit: 'piece',
              isActive: true,
              updatedAt: DateTime.now(),
            ),
          );
          
          updatedItems.add({
            'itemId': item.id,
            'name': item.name,
            'quantity': quantity,
            'pricePerPiece': item.offerPrice ?? item.price,
            'offerPrice': item.offerPrice,
            'category': item.category,
            'unit': item.unit,
          });
        }
      }

      // Update order in Firestore with admin tracking
      await _firestore.collection('orders').doc(widget.order.id).update({
        'items': updatedItems,
        'totalAmount': _totalAmount,
        'specialInstructions': _specialInstructions?.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastModifiedBy': 'admin',
        'lastModifiedAt': FieldValue.serverTimestamp(),
        'statusHistory': FieldValue.arrayUnion([
          {
            'status': 'modified_by_admin',
            'timestamp': Timestamp.now(),
            'updatedBy': 'admin',
            'title': 'Order Modified by Admin',
            'description': 'Admin updated order items and total amount',
            'changes': {
              'itemCount': updatedItems.length,
              'totalAmount': _totalAmount,
              'modifiedBy': _auth.currentUser?.email ?? 'admin',
            },
          }
        ]),
      });

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating order: $e');
      _showErrorSnackBar('Failed to update order. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  IconData _getItemIcon(String itemName) {
    String name = itemName.toLowerCase();
    if (name.contains('shirt')) return Icons.checkroom;
    if (name.contains('pant') || name.contains('trouser')) return Icons.work_outline;
    if (name.contains('dress')) return Icons.person;
    if (name.contains('bed') || name.contains('sheet')) return Icons.bed;
    if (name.contains('towel')) return Icons.dry_cleaning;
    return Icons.local_laundry_service;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Order'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isAlliedService ? 'Allied Services (Wash & Iron)' : 'Ironing Services',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Admin Edit Mode'),
                  content: const Text(
                    'You are editing this order as an admin. All changes will be tracked and recorded in the order history.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Information Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue.shade600, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Editing Order #${widget.order.orderNumber ?? widget.order.id.substring(0, 8)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Service Type: ${widget.order.serviceType ?? 'Unknown'}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Items List
            _isAlliedService ? _buildAlliedServicesList() : _buildIroningItemsList(),

            const SizedBox(height: 24),

            // Space for bottom sheet
            if (_hasSelectedItems) const SizedBox(height: 120),
          ],
        ),
      ),
      bottomSheet: _hasSelectedItems ? _buildStickyCartSummary() : null,
    );
  }

  Widget _buildIroningItemsList() {
    if (_availableItems.isEmpty) {
      return const Center(
        child: Column(
          children: [
            Icon(Icons.iron, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No ironing items available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      itemCount: _availableItems.length,
      itemBuilder: (context, index) {
        final item = _availableItems[index];
        final quantity = _getCurrentQuantity(item.name);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Item Image/Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: item.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: item.imageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Icon(
                            _getItemIcon(item.name),
                            color: Colors.grey.shade400,
                          ),
                        ),
                      )
                    : Icon(
                        _getItemIcon(item.name),
                        color: Colors.grey.shade400,
                      ),
              ),
              const SizedBox(width: 16),
              
              // Item Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        if (item.offerPrice != null && item.offerPrice! < item.price)
                          Text(
                            '₹${item.price.toInt()}',
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        if (item.offerPrice != null && item.offerPrice! < item.price)
                          const SizedBox(width: 8),
                        Text(
                          '₹${(item.offerPrice ?? item.price).toInt()} per ${item.unit}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Quantity Controls
              Row(
                children: [
                  IconButton(
                    onPressed: quantity > 0
                        ? () => _updateItemQuantity(item.name, quantity - 1)
                        : null,
                    icon: Icon(
                      Icons.remove,
                      color: quantity > 0 ? Colors.grey.shade600 : Colors.grey.shade300,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Text(
                      '$quantity',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _updateItemQuantity(item.name, quantity + 1),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlliedServicesList() {
    if (_availableAlliedServices.isEmpty) {
      return const Center(
        child: Column(
          children: [
            Icon(Icons.local_laundry_service, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No allied services available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      itemCount: _availableAlliedServices.length,
      itemBuilder: (context, index) {
        final service = _availableAlliedServices[index];
        final quantity = _getCurrentQuantity(service.name);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Service Image/Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: service.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: service.imageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => const Icon(
                            Icons.local_laundry_service,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.local_laundry_service,
                        color: Colors.grey,
                      ),
              ),
              const SizedBox(width: 16),
              
              // Service Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      service.description,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Row(
                      children: [
                        if (service.hasPrice && service.offerPrice != null && service.offerPrice! < service.price)
                          Text(
                            '₹${service.price.toInt()}',
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        if (service.hasPrice && service.offerPrice != null && service.offerPrice! < service.price)
                          const SizedBox(width: 8),
                        if (service.hasPrice)
                          Text(
                            '₹${(service.offerPrice ?? service.price).toInt()} per ${service.unit}',
                            style: TextStyle(
                              color: service.offerPrice != null
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else
                          Text(
                            'Quote after inspection',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Quantity Controls
              Row(
                children: [
                  IconButton(
                    onPressed: quantity > 0
                        ? () => _updateItemQuantity(service.name, quantity - 1)
                        : null,
                    icon: Icon(
                      Icons.remove,
                      color: quantity > 0 ? Colors.grey.shade600 : Colors.grey.shade300,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Text(
                      '$quantity',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _updateItemQuantity(service.name, quantity + 1),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStickyCartSummary() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 50),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cart Summary Row
                Row(
                  children: [
                    // Cart Icon with Badge
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F3057).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.shopping_cart,
                            color: Color(0xFF0F3057),
                            size: 24,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$_totalSelectedItems',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),

                    // Amount Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$_totalSelectedItems item${_totalSelectedItems > 1 ? 's' : ''} selected',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (_totalAmount > 0)
                            Text(
                              '₹${_totalAmount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            )
                          else
                            const Text(
                              'Quote on inspection',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Update Button
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: ElevatedButton(
                        onPressed: !_hasSelectedItems || _isSaving ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F3057),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.update, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Update',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_ios, size: 14),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper methods for service type display
  Color _getServiceTypeColor(String serviceType) {
    if (serviceType.toLowerCase().contains('iron')) {
      return Colors.orange;
    } else if (serviceType.toLowerCase().contains('laundry')) {
      return Colors.blue;
    } else if (serviceType.toLowerCase().contains('mixed')) {
      return Colors.purple;
    } else {
      return Colors.grey;
    }
  }

  IconData _getServiceTypeIcon(String serviceType) {
    if (serviceType.toLowerCase().contains('iron')) {
      return Icons.iron;
    } else if (serviceType.toLowerCase().contains('laundry')) {
      return Icons.local_laundry_service;
    } else if (serviceType.toLowerCase().contains('mixed')) {
      return Icons.miscellaneous_services;
    } else {
      return Icons.help_outline;
    }
  }
} 