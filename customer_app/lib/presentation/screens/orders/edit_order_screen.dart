import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:customer_app/data/models/order_model.dart';
import 'package:customer_app/data/models/item_model.dart';
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
  
  Map<String, int> _selectedItems = {};
  List<ItemModel> _availableItems = [];
  bool _isLoading = true;
  bool _isSaving = false;
  double _totalAmount = 0.0;

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
        _selectedItems[itemName] = quantity;
      }
    }
    _calculateTotal();
  }

  Future<void> _fetchAvailableItems() async {
    try {
      List<ItemModel> allItems = [];
      
      // Always fetch regular items
      QuerySnapshot itemsSnapshot = await _firestore
          .collection('items')
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .get();

      List<ItemModel> regularItems = itemsSnapshot.docs
          .map((doc) => ItemModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();

      // If service type is Laundry, also fetch allied services
      if (widget.order.serviceType.toLowerCase().contains('laundry')) {
        try {
          QuerySnapshot alliedSnapshot = await _firestore
              .collection('allied_services')
              .where('isActive', isEqualTo: true)
              .orderBy('sortOrder')
              .get();

          List<ItemModel> alliedServices = alliedSnapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            // Convert allied service to ItemModel format
            return ItemModel(
              id: doc.id,
              name: data['name'] ?? '',
              category: 'Allied Service', // Set category for allied services
              pricePerPiece: (data['offerPrice'] ?? data['price'] ?? 0.0).toDouble(),
              unit: data['unit'] ?? 'service',
              isActive: data['isActive'] ?? true,
              order: data['sortOrder'] ?? 0,
              imageUrl: data['imageUrl'], // Add image URL field
              offerPrice: data['offerPrice']?.toDouble(),
            );
          }).toList();
          
          allItems.addAll(alliedServices);
        } catch (e) {
          print('Error fetching allied services: $e');
        }
      }
      
      // Add regular items
      allItems.addAll(regularItems);

      // Filter items based on the current order's service type
      _availableItems = _filterItemsByServiceType(allItems, widget.order.serviceType);

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

  // Helper method to filter items based on service type
  List<ItemModel> _filterItemsByServiceType(List<ItemModel> allItems, String serviceType) {
    if (serviceType.toLowerCase().contains('mixed')) {
      // For mixed services, show all items
      return allItems;
    } else if (serviceType.toLowerCase().contains('ironing')) {
      // For ironing services, show only ironing items
      return allItems.where((item) => 
        item.category.toLowerCase().contains('iron') || 
        item.category.toLowerCase() == 'ironing'
      ).toList();
    } else if (serviceType.toLowerCase().contains('laundry')) {
      // For laundry services, show only allied services
      return allItems.where((item) => 
        item.category.toLowerCase() == 'allied service'
      ).toList();
    } else if (serviceType.toLowerCase().contains('allied')) {
      // For allied services, show only allied items
      return allItems.where((item) => 
        item.category.toLowerCase().contains('allied') || 
        item.category.toLowerCase() == 'allied service' ||
        item.category.toLowerCase() == 'allied services'
      ).toList();
    } else {
      // Default: show all items
      return allItems;
    }
  }

  void _calculateTotal() {
    double total = 0.0;
    for (String itemName in _selectedItems.keys) {
      int quantity = _selectedItems[itemName] ?? 0;
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
    setState(() {
      _totalAmount = total;
    });
  }

  // Helper method to determine service type based on selected items
  String _determineServiceType() {
    if (_selectedItems.isEmpty) {
      return 'Laundry Service';
    }
    
    Map<String, int> categoryCount = {};
    
    for (String itemName in _selectedItems.keys) {
      int quantity = _selectedItems[itemName] ?? 0;
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
    
    // Determine service type based on items
    int ironingCount = categoryCount['ironing'] ?? 0;
    int alliedCount = categoryCount['allied'] ?? 0;
    int laundryCount = categoryCount['laundry'] ?? 0;
    
    // Check for combinations
    List<String> serviceTypes = [];
    if (ironingCount > 0) serviceTypes.add('Ironing');
    if (alliedCount > 0) serviceTypes.add('Allied');
    if (laundryCount > 0) serviceTypes.add('Laundry');
    
    if (serviceTypes.length > 1) {
      return 'Mixed Service (${serviceTypes.join(' & ')})';
    } else if (ironingCount > 0) {
      return 'Ironing Service';
    } else if (alliedCount > 0) {
      return 'Allied Service';
    } else {
      return 'Laundry Service';
    }
  }

  // Helper methods for service type display
  Widget _buildServiceTypeChip(String serviceType) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getServiceTypeColor(serviceType),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        serviceType.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _getServiceTypeColor(String serviceType) {
    final type = serviceType.toLowerCase();
    if (type.contains('ironing')) {
      return Colors.orange[600]!;
    } else if (type.contains('allied')) {
      return Colors.green[600]!;
    } else if (type.contains('mixed')) {
      return Colors.purple[600]!;
    } else {
      return Colors.blue[600]!;
    }
  }

  IconData _getServiceTypeIcon(String serviceType) {
    final type = serviceType.toLowerCase();
    if (type.contains('ironing')) {
      return Icons.iron;
    } else if (type.contains('allied')) {
      return Icons.cleaning_services; // Allied services icon
    } else if (type.contains('mixed')) {
      return Icons.miscellaneous_services;
    } else {
      return Icons.local_laundry_service_outlined;
    }
  }

  void _updateItemQuantity(String itemName, int newQuantity) {
    setState(() {
      if (newQuantity <= 0) {
        _selectedItems.remove(itemName);
      } else {
        _selectedItems[itemName] = newQuantity;
      }
    });
    _calculateTotal();
  }

  bool _canEditOrder() {
    // Customer can edit order until processing starts
    String orderStatus = widget.order.status.toLowerCase().trim();
    
    // Allow editing for these statuses (before processing starts)
    List<String> editableStatuses = [
      'pending',
      'confirmed',
      'placed',
      'accepted',
      'order_placed',
      'order_confirmed',
      'picked_up',  // Allow editing even after pickup
    ];
    
    // Block editing for these statuses (after processing starts)
    List<String> nonEditableStatuses = [
      'processing',
      'in_progress',
      'ready',
      'delivered',
      'completed',
      'cancelled',
      'rejected',
    ];
    
    // If status is in non-editable list, block editing
    if (nonEditableStatuses.contains(orderStatus)) {
      return false;
    }
    
    // If status is in editable list, allow editing
    if (editableStatuses.contains(orderStatus)) {
      return true;
    }
    
    // For any unknown status, default to not allowing editing
    return false;
  }

  Future<void> _saveChanges() async {
    if (!_canEditOrder()) {
      _showErrorSnackBar('Cannot edit order after processing has started');
      return;
    }

    if (_selectedItems.isEmpty) {
      _showErrorSnackBar('Please select at least one item');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Prepare updated items list
      List<Map<String, dynamic>> updatedItems = [];
      for (String itemName in _selectedItems.keys) {
        int quantity = _selectedItems[itemName] ?? 0;
        ItemModel item = _availableItems.firstWhere(
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
        
        updatedItems.add({
          'name': item.name,
          'quantity': quantity,
          'pricePerPiece': item.offerPrice ?? item.pricePerPiece,
          'category': item.category,
          'unit': item.unit,
        });
      }

      // Determine the new service type based on updated items
      String newServiceType = _determineServiceType();

      // Update order in Firestore with enhanced tracking
      await _firestore.collection('orders').doc(widget.order.id).update({
        'items': updatedItems,
        'totalAmount': _totalAmount,
        'serviceType': newServiceType,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastModifiedBy': 'customer',
        'lastModifiedAt': FieldValue.serverTimestamp(),
        'statusHistory': FieldValue.arrayUnion([
          {
            'status': 'modified',
            'timestamp': Timestamp.now(),
            'updatedBy': 'customer',
            'title': 'Order Modified',
            'description': 'Customer updated order items and total amount',
            'changes': {
              'itemCount': updatedItems.length,
              'totalAmount': _totalAmount,
            },
          }
        ]),
      });

      // Send notification to admin about order edit
      try {
        await OrderNotificationService.notifyOrderEdit(
          orderId: widget.order.id,
          orderNumber: widget.order.orderNumber ?? 'N/A',
          changes: {
            'itemCount': updatedItems.length,
            'totalAmount': _totalAmount,
            'items': updatedItems,
          },
        );
        print('✅ Order edit notification sent to admin');
      } catch (e) {
        print('❌ Error sending order edit notification: $e');
      }

      _showSuccessSnackBar('Order updated successfully!');
      Navigator.of(context).pop(true); // Return true to indicate success
    } catch (e) {
      print('Error updating order: $e');
      _showErrorSnackBar('Failed to update order. Please try again.');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
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
          children: _availableItems.map((item) {
            final quantity = _selectedItems[item.name] ?? 0;
            // Debug: Print item information
            print('Item: ${item.name}, ImageURL: ${item.imageUrl}, Category: ${item.category}');

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
                                Icons.image,
                                color: context.onSurfaceVariant,
                                size: 20,
                              ),
                            ),
                            errorWidget: (context, url, error) {
                              print('Error loading image for ${item.name}: $error');
                              print('Image URL: ${item.imageUrl}');
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
                      // Price display with original and offer prices
                      Row(
                        children: [
                          // Original Price (strikethrough) - Show first if there's an offer
                          if (item.offerPrice != null && item.offerPrice! < item.pricePerPiece)
                            Text(
                              '₹${item.pricePerPiece.toInt()}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: context.onSurfaceVariant,
                              ),
                            ),
                          // Add spacing between original and offer price
                          if (item.offerPrice != null && item.offerPrice! < item.pricePerPiece)
                            const SizedBox(width: 8),
                          // Current/Offer Price
                          Text(
                            '₹${(item.offerPrice ?? item.pricePerPiece).toInt()} per ${item.unit}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: item.offerPrice != null
                                  ? context.primaryColor
                                  : context.onSurfaceVariant,
                              fontWeight: item.offerPrice != null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
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
          }).toList(),
        ),
      ),
      // Add bottom spacing to account for the bottom sheet
      const SizedBox(height: 120),
    ],
  );
}
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final selectedDate = DateTime(date.year, date.month, date.day);

    if (selectedDate == today) {
      return 'Today';
    } else if (selectedDate == tomorrow) {
      return 'Tomorrow';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
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
        foregroundColor: context.onSurfaceColor ,
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
            child: _availableItems.isEmpty
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
                        'Total Items: ${_selectedItems.values.fold(0, (sum, quantity) => sum + quantity)}',
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
                      onPressed: _selectedItems.isEmpty || _isSaving ? null : _saveChanges,
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
}