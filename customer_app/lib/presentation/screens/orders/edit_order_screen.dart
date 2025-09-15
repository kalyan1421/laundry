import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:customer_app/data/models/order_model.dart';
import 'package:customer_app/data/models/item_model.dart';
import 'package:customer_app/data/models/allied_service_model.dart';
import 'package:customer_app/core/theme/app_colors.dart';
import 'package:customer_app/core/theme/app_text_theme.dart';
import 'package:customer_app/presentation/widgets/common/custom_button.dart';
import 'package:customer_app/services/order_notification_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:customer_app/core/theme/theme_extensions.dart';

class EditOrderScreen extends StatefulWidget {
  final OrderModel order;

  const EditOrderScreen({super.key, required this.order});

  @override
  State<EditOrderScreen> createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends State<EditOrderScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // For regular ironing items
  Map<String, int> _selectedItems = {};
  List<ItemModel> _availableItems = [];
  
  // For allied services
  Map<String, int> _selectedAlliedServices = {};
  List<AlliedServiceModel> _availableAlliedServices = [];
  
  bool _isLoading = true;
  bool _isSaving = false;
  double _totalAmount = 0.0;
  
  // Store original order data for comparison
  Map<String, int> _originalItems = {};
  double _originalAmount = 0.0;
  
  // Determine if this is an allied service order
  bool get _isAlliedService => widget.order.serviceType.toLowerCase().contains('allied');

  @override
  void initState() {
    super.initState();
    _storeOriginalData();
    _initializeCurrentItems();
    _fetchAvailableItems();
  }

  void _storeOriginalData() {
    // Store original order data for comparison
    _originalAmount = widget.order.totalAmount;
    for (var item in widget.order.items) {
      String itemName = item['name'] ?? '';
      int quantity = item['quantity'] ?? 0;
      if (itemName.isNotEmpty && quantity > 0) {
        _originalItems[itemName] = quantity;
      }
    }
  }

  void _initializeCurrentItems() {
    // Initialize selected items from current order
    for (var item in widget.order.items) {
      String itemName = item['name'] ?? '';
      int quantity = item['quantity'] ?? 0;
      if (itemName.isNotEmpty) {
        if (_isAlliedService) {
          _selectedAlliedServices[itemName] = quantity;
        } else {
          _selectedItems[itemName] = quantity;
        }
      }
    }
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
            .map((doc) => ItemModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
            .toList();

        // Filter items based on the original service type
        _availableItems = _filterItemsByServiceType(_availableItems, widget.order.serviceType);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching items: \$e');
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load items. Please try again.');
    }
  }

  List<ItemModel> _filterItemsByServiceType(List<ItemModel> allItems, String serviceType) {
    if (serviceType.toLowerCase().contains('ironing')) {
      // For ironing services, show only ironing items
      return allItems.where((item) => 
        item.category.toLowerCase().contains('iron') ||
        item.category.toLowerCase() == 'ironing'
      ).toList();
    } else if (serviceType.toLowerCase().contains('laundry')) {
      // For laundry services, show only laundry items
      return allItems.where((item) => 
        item.category.toLowerCase().contains('laundry') ||
        item.category.toLowerCase().contains('wash') ||
        item.category.toLowerCase().contains('dry')
      ).toList();
    } else if (serviceType.toLowerCase().contains('allied')) {
      // For allied services, this shouldn't be called as we use _availableAlliedServices
      return [];
    } else {
      // Default: return all items
      return allItems;
    }
  }

  void _calculateTotal() {
    double total = 0.0;
    
    if (_isAlliedService) {
      // Calculate total for allied services
      for (String serviceName in _selectedAlliedServices.keys) {
        int quantity = _selectedAlliedServices[serviceName] ?? 0;
        if (quantity > 0) {
          AlliedServiceModel? service = _availableAlliedServices.firstWhere(
            (service) => service.name == serviceName,
            orElse: () => AlliedServiceModel(
              id: '',
              name: serviceName,
              description: '',
              price: 0.0,
              category: '',
              unit: 'service',
              isActive: true,
              hasPrice: true,
              updatedAt: DateTime.now(),
            ),
          );
          double effectivePrice = service.effectivePrice;
          total += effectivePrice * quantity;
        }
      }
    } else {
      // Calculate total for regular items
      for (String itemName in _selectedItems.keys) {
        int quantity = _selectedItems[itemName] ?? 0;
        if (quantity > 0) {
          ItemModel? item = _availableItems.firstWhere(
            (item) => item.name == itemName,
            orElse: () => ItemModel(
              id: '',
              name: itemName,
              category: '',
              pricePerPiece: 0.0,
              unit: 'piece',
              isActive: true,
              order: 0,
            ),
          );
          // Use offer price if available, otherwise use regular price
          final effectivePrice = item.offerPrice ?? item.pricePerPiece;
          total += effectivePrice * quantity;
        }
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

  bool _hasSelectedItems() {
    // Check if any items have quantity > 0
    if (_isAlliedService) {
      return _selectedAlliedServices.values.any((quantity) => quantity > 0);
    } else {
      return _selectedItems.values.any((quantity) => quantity > 0);
    }
  }

  bool _hasChanges() {
    // Check if there are any changes from the original order
    Map<String, int> currentItems = _isAlliedService ? _selectedAlliedServices : _selectedItems;
    
    // Check if item counts changed
    if (currentItems.length != _originalItems.length) {
      return true;
    }
    
    // Check if any item quantities changed
    for (String itemName in currentItems.keys) {
      if (currentItems[itemName] != _originalItems[itemName]) {
        return true;
      }
    }
    
    // Check if any original items were removed
    for (String itemName in _originalItems.keys) {
      if (!currentItems.containsKey(itemName)) {
        return true;
      }
    }
    
    return false;
  }

  bool _canEditOrder() {
    // Customer can edit order until processing starts
    String orderStatus = widget.order.status.toLowerCase().trim();
    List<String> editableStatuses = [
      'pending',
      'placed',
      'order_placed',
      'new_order',
    ];
    return editableStatuses.contains(orderStatus);
  }

  Future<void> _saveChanges() async {
    if (!_canEditOrder()) {
      _showErrorSnackBar('Cannot edit order after processing has started');
      return;
    }

    if (!_hasSelectedItems()) {
      _showErrorSnackBar('Please select at least one item');
      return;
    }

    if (!_hasChanges()) {
      _showErrorSnackBar('No changes detected');
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
          if (quantity > 0) {
            AlliedServiceModel? service;
            try {
              service = _availableAlliedServices.firstWhere(
                (service) => service.name == serviceName,
              );
            } catch (e) {
              service = null;
            }
            
            if (service != null) {
              updatedItems.add({
                'name': service.name,
                'quantity': quantity,
                'price': service.effectivePrice,
                'category': service.category,
                'unit': service.unit,
              });
            }
          }
        }
      } else {
        // Handle regular items
        for (String itemName in _selectedItems.keys) {
          int quantity = _selectedItems[itemName] ?? 0;
          if (quantity > 0) {
            ItemModel? item;
            try {
              item = _availableItems.firstWhere(
                (item) => item.name == itemName,
              );
            } catch (e) {
              item = null;
            }
            
            if (item != null) {
              updatedItems.add({
                'name': item.name,
                'quantity': quantity,
                'price': item.offerPrice ?? item.pricePerPiece,
                'category': item.category,
                'unit': item.unit,
              });
            }
          }
        }
      }

      if (updatedItems.isEmpty) {
        _showErrorSnackBar('No valid items selected');
        return;
      }

      // Determine the new service type based on updated items
      String newServiceType = _determineServiceType();

      // Get current user ID
      String? userId = _auth.currentUser?.uid;

      // Prepare update data
      Map<String, dynamic> updateData = {
        'items': updatedItems,
        'totalAmount': _totalAmount,
        'serviceType': newServiceType,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastModifiedBy': 'customer',
        'lastModifiedAt': FieldValue.serverTimestamp(),
      };

      // Add status history entry
      Map<String, dynamic> statusHistoryEntry = {
        'status': 'modified',
        'timestamp': Timestamp.now(),
        'updatedBy': 'customer',
        'userId': userId,
        'title': 'Order Modified',
        'description': 'Customer updated order items and total amount',
        'changes': {
          'itemCount': updatedItems.length,
          'totalAmount': _totalAmount,
          'previousAmount': _originalAmount,
        },
      };

      updateData['statusHistory'] = FieldValue.arrayUnion([statusHistoryEntry]);

      // Update order in Firestore
      await _firestore.collection('orders').doc(widget.order.id).update(updateData);

      // Send notification to admin about order edit
      try {
        await OrderNotificationService.notifyOrderEdit(
          orderId: widget.order.id,
          orderNumber: widget.order.orderNumber ?? 'N/A',
          changes: {
            'itemCount': updatedItems.length,
            'totalAmount': _totalAmount,
            'previousAmount': _originalAmount,
            'items': updatedItems,
          },
        );
        print('✅ Order edit notification sent to admin');
      } catch (e) {
        print('❌ Error sending order edit notification: \$e');
        // Don't fail the entire operation if notification fails
      }

      _showSuccessSnackBar('Order updated successfully!');
      Navigator.of(context).pop(true); // Return true to indicate success
    } catch (e) {
      print('Error updating order: \$e');
      _showErrorSnackBar('Failed to update order. Please try again.');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _determineServiceType() {
    if (_isAlliedService) {
      return 'Allied Service';
    }
    
    if (_selectedItems.isEmpty) {
      return widget.order.serviceType; // Keep original service type if no items
    }
    
    // Count items by category to determine the dominant service type
    Map<String, int> categoryCount = {};
    
    for (String itemName in _selectedItems.keys) {
      int quantity = _selectedItems[itemName] ?? 0;
      if (quantity > 0) {
        ItemModel? item = _availableItems.firstWhere(
          (item) => item.name == itemName,
          orElse: () => ItemModel(
            id: '',
            name: itemName,
            category: '',
            pricePerPiece: 0.0,
            unit: 'piece',
            isActive: true,
            order: 0,
          ),
        );
        
        String category = item.category.toLowerCase();
        
        // Normalize category names
        if (category.contains('iron') || category == 'ironing') {
          categoryCount['ironing'] = (categoryCount['ironing'] ?? 0) + quantity;
        } else if (category.contains('allied') || category == 'allied service' || category == 'allied services') {
          categoryCount['allied'] = (categoryCount['allied'] ?? 0) + quantity;
        } else {
          // Everything else is considered laundry (wash & fold, dry cleaning, etc.)
          categoryCount['laundry'] = (categoryCount['laundry'] ?? 0) + quantity;
        }
      }
    }
    
    // Determine the service type based on the majority of items
    String dominantCategory = categoryCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    switch (dominantCategory) {
      case 'ironing':
        return 'Ironing Service';
      case 'allied':
        return 'Allied Service';
      case 'laundry':
      default:
        return 'Laundry Service';
    }
  }

  Widget _buildServiceTypeChip(String serviceType) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getServiceTypeColor(serviceType).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getServiceTypeColor(serviceType)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getServiceTypeIcon(serviceType),
            size: 16,
            color: _getServiceTypeColor(serviceType),
          ),
          const SizedBox(width: 6),
          Text(
            serviceType.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _getServiceTypeColor(serviceType),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getServiceTypeIcon(String serviceType) {
    final type = serviceType.toLowerCase();
    if (type.contains('ironing')) {
      return Icons.iron;
    } else if (type.contains('allied')) {
      return Icons.cleaning_services;
    } else if (type.contains('laundry')) {
      return Icons.local_laundry_service;
    } else {
      return Icons.local_laundry_service_outlined;
    }
  }

  Color _getServiceTypeColor(String serviceType) {
    final type = serviceType.toLowerCase();
    if (type.contains('ironing')) {
      return Colors.orange[600]!;
    } else if (type.contains('allied')) {
      return Colors.purple[600]!;
    } else if (type.contains('laundry')) {
      return Colors.blue[600]!;
    } else {
      return Colors.grey[600]!;
    }
  }

  IconData _getItemIcon(String itemName) {
    final name = itemName.toLowerCase();
    if (name.contains('shirt')) return Icons.checkroom;
    if (name.contains('pant') || name.contains('trouser')) return Icons.checkroom;
    if (name.contains('churidar')) return Icons.checkroom;
    if (name.contains('saree') || name.contains('sare')) return Icons.checkroom;
    if (name.contains('blouse') || name.contains('blows')) return Icons.checkroom;
    if (name.contains('special')) return Icons.star;
    return Icons.checkroom;
  }

  @override
  Widget build(BuildContext context) {
    if (!_canEditOrder()) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Edit Order', 
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: context.onSurfaceColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: context.backgroundColor,
          foregroundColor: context.onSurfaceColor,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.access_time,
                  size: 80,
                  color: Colors.orange,
                ),
                const SizedBox(height: 24),
                Text(
                  'Order Cannot Be Edited',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: context.onSurfaceColor,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Orders can only be edited before processing starts. Your order is already being processed.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: context.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Go Back',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Edit Order', 
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: context.onSurfaceColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: context.backgroundColor,
          foregroundColor: context.onSurfaceColor,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text('Edit Order', 
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: context.onSurfaceColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: context.backgroundColor,
        foregroundColor: context.onSurfaceColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Order Information Header
          Container(
            width: double.infinity,
            color: context.surfaceColor,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Number and Service Type
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order #${widget.order.orderNumber ?? widget.order.id}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.onSurfaceColor,
                      ),
                    ),
                    _buildServiceTypeChip(_determineServiceType()),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Pickup Information
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: context.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      'Pickup: ${_formatDate(widget.order.pickupDate.toDate())} • ${widget.order.pickupTimeSlot}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                
                // Status
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Status: ${widget.order.status.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Items List
          Expanded(
            child: (_isAlliedService ? _availableAlliedServices.isEmpty : _availableItems.isEmpty)
                ? const Center(child: Text('No items available'))
                : SingleChildScrollView(
                    child: _buildItemsSection(),
                  ),
          ),
        ],
      ),
      
      // Bottom Sheet with Total and Update Button
      bottomSheet: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 50),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          boxShadow: [
            BoxShadow(
              color: context.shadowColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Total Amount Display
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Items: ${_isAlliedService ? _selectedAlliedServices.values.fold(0, (sum, quantity) => sum + quantity) : _selectedItems.values.fold(0, (sum, quantity) => sum + quantity)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.onSurfaceColor,
                        ),
                      ),
                      Text(
                        'Total Amount: ₹${_totalAmount.toInt()}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  
                  // Update Button
                  SizedBox(
                    width: 150,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _hasSelectedItems() && _hasChanges() && !_isSaving ? _saveChanges : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryColor,
                        foregroundColor: context.onPrimaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Update Order',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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

  Widget _buildItemsSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Edit Items for ${widget.order.serviceType}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: _isAlliedService 
                ? _availableAlliedServices.map((service) {
                    final quantity = _selectedAlliedServices[service.name] ?? 0;
                    return _buildAlliedServiceCard(service, quantity);
                  }).toList()
                : _availableItems.map((item) {
                    final quantity = _selectedItems[item.name] ?? 0;
                    return _buildItemCard(item, quantity);
                  }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(ItemModel item, int quantity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: context.surfaceVariant,
                        child: Icon(
                          _getItemIcon(item.name),
                          color: context.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                      errorWidget: (context, url, error) {
                        return Icon(_getItemIcon(item.name),
                            color: context.onSurfaceVariant);
                      },
                    ),
                  )
                : Icon(_getItemIcon(item.name),
                    color: context.onSurfaceVariant),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.onSurfaceColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.category,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${(item.offerPrice ?? item.pricePerPiece).toInt()} per ${item.unit}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: quantity > 0
                        ? context.primaryColor
                        : context.onSurfaceVariant,
                  ),
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
                  color: quantity > 0
                      ? context.onSurfaceVariant
                      : context.outlineVariant,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Text(
                  '$quantity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.onSurfaceColor,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _updateItemQuantity(item.name, quantity + 1),
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: context.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add,
                    color: context.onPrimaryColor,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlliedServiceCard(AlliedServiceModel service, int quantity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: service.imageUrl != null && service.imageUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: service.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: context.surfaceVariant,
                        child: Icon(
                          Icons.cleaning_services,
                          color: context.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                      errorWidget: (context, url, error) => Icon(
                        Icons.cleaning_services,
                        color: context.onSurfaceVariant,
                      ),
                    ),
                  )
                : Icon(
                    Icons.cleaning_services,
                    color: context.onSurfaceVariant,
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.onSurfaceColor,
                  ),
                ),
                if (service.description.isNotEmpty)
                  Text(
                    service.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.onSurfaceVariant,
                    ),
                  ),
                // Price display with original and offer prices
                Row(
                  children: [
                    if (service.hasOffer && service.offerPrice != null) ...[
                      Text(
                        '₹${service.price.toInt()}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: context.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '₹${service.offerPrice!.toInt()}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.green[600],
                        ),
                      ),
                    ] else
                      Text(
                        '₹${service.price.toInt()}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.primaryColor,
                        ),
                      ),
                    Text(
                      ' per ${service.unit}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.onSurfaceVariant,
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
                  color: quantity > 0
                      ? context.onSurfaceVariant
                      : context.outlineVariant,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Text(
                  '$quantity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.onSurfaceColor,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _updateItemQuantity(service.name, quantity + 1),
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: context.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add,
                    color: context.onPrimaryColor,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final selectedDate = DateTime(date.year, date.month, date.day);

    if (selectedDate == today) {
      return 'Today';
    } else if (selectedDate == tomorrow) {
      return 'Tomorrow';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
}