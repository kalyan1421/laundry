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
      QuerySnapshot snapshot = await _firestore
          .collection('items')
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .get();

      _availableItems = snapshot.docs
          .map((doc) => ItemModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();

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

      // Update order in Firestore with enhanced tracking
      await _firestore.collection('orders').doc(widget.order.id).update({
        'items': updatedItems,
        'totalAmount': _totalAmount,
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
          title: const Text('Edit Order'),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primary,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.access_time,
                  size: 80,
                  color: Colors.orange,
                ),
                const SizedBox(height: 24),
                Text(
                  'Order Cannot Be Edited',
                  style: AppTextTheme.headlineMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Orders can only be edited before processing starts. Your order is already being processed.',
                  style: AppTextTheme.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
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
          title: const Text('Edit Order'),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primary,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Edit Order'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Order Information Header
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Number
                Text(
                  'Order #${widget.order.orderNumber ?? widget.order.id}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F3057),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Pickup Information
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Pickup: ${_formatDate(widget.order.pickupDate.toDate())} • ${widget.order.pickupTimeSlot}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
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
          
          // Items Section Header
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: const Text(
              'Select Items for Ironing',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Items List
          Expanded(
            child: _availableItems.isEmpty
                ? const Center(child: Text('No items available'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _availableItems.length,
                    itemBuilder: (context, index) {
                      ItemModel item = _availableItems[index];
                      int currentQuantity = _selectedItems[item.name] ?? 0;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                          child: Row(
                            children: [
                            // Item Image/Icon
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CachedNetworkImage(
                                        imageUrl: item.imageUrl!,
                                        fit: BoxFit.cover,
                                        errorWidget: (context, url, error) {
                                          return Icon(_getItemIcon(item.name), color: Colors.grey[400]);
                                        },
                                      ),
                                    )
                                  : Icon(_getItemIcon(item.name), color: Colors.grey[400]),
                            ),
                            const SizedBox(width: 16),
                            
                            // Item Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                  // Item Name
                                    Text(
                                      item.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      ),
                                    ),
                                  
                                  // Price Display with original and offer prices
                                  Row(
                                    children: [
                                      // Original Price (strikethrough) - Show first if there's an offer
                                      if (item.originalPrice != null && item.originalPrice! > (item.offerPrice ?? item.pricePerPiece))
                                    Text(
                                          '₹${item.originalPrice!.toInt()}',
                                          style: const TextStyle(
                                            decoration: TextDecoration.lineThrough,
                                            color: Colors.grey,
                                            fontSize: 12,
                                      ),
                                    ),
                                      // Add spacing between original and offer price
                                      if (item.originalPrice != null && item.originalPrice! > (item.offerPrice ?? item.pricePerPiece))
                                        const SizedBox(width: 8),
                                      // Current/Offer Price
                                      Text(
                                        '₹${(item.offerPrice ?? item.pricePerPiece).toInt()} per ${item.unit}',
                                        style: TextStyle(
                                          color: item.offerPrice != null ? Colors.green[700] : Colors.grey[600],
                                          fontSize: 14,
                                          fontWeight: item.offerPrice != null ? FontWeight.w600 : FontWeight.normal,
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
                                    onPressed: currentQuantity > 0
                                        ? () => _updateItemQuantity(item.name, currentQuantity - 1)
                                        : null,
                                  icon: Icon(
                                    Icons.remove,
                                    color: currentQuantity > 0 ? Colors.grey[600] : Colors.grey[300],
                                  ),
                                  ),
                                  Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      child: Text(
                                    '$currentQuantity',
                                    style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _updateItemQuantity(item.name, currentQuantity + 1),
                                  icon: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
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
                  ),
          ),
          SizedBox(height: 120,),
        ],
      ),
      
      // Bottom Sheet with Total and Update Button
      bottomSheet: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 50),
        decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -2),
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
                        style: const TextStyle(
                        fontWeight: FontWeight.w600,
                          fontSize: 16,
                      ),
                    ),
                    Text(
                        'Total Amount: ₹${_totalAmount.toInt()}',
                        style: const TextStyle(
                        fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.blue,
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
                        backgroundColor: const Color(0xFF0F3057),
                        foregroundColor: Colors.white,
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