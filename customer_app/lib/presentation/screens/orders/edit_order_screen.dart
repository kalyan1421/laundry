import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:customer_app/data/models/order_model.dart';
import 'package:customer_app/data/models/item_model.dart';
import 'package:customer_app/core/theme/app_colors.dart';
import 'package:customer_app/core/theme/app_text_theme.dart';
import 'package:customer_app/presentation/widgets/common/custom_button.dart';

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
      total += item.pricePerPiece * quantity;
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
    // Allow editing for pending, confirmed, and picked_up statuses
    
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
          'pricePerPiece': item.pricePerPiece,
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

  @override
  Widget build(BuildContext context) {
    if (!_canEditOrder()) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Order'),
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.primary,
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
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.primary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Order'),
          backgroundColor: AppColors.white,
        foregroundColor: AppColors.primary,
        actions: [
          if (_selectedItems.isNotEmpty)
            TextButton(
              onPressed: _isSaving ? null : _saveChanges,
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
                      'Save',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Order info header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${widget.order.orderNumber}',
                  style: AppTextTheme.titleLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Pickup: ${widget.order.pickupTimeSlot}',
                      style: AppTextTheme.bodyMedium.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Items list
          Expanded(
            child: _availableItems.isEmpty
                ? const Center(child: Text('No items available'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _availableItems.length,
                    itemBuilder: (context, index) {
                      ItemModel item = _availableItems[index];
                      int currentQuantity = _selectedItems[item.name] ?? 0;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Item info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: AppTextTheme.titleMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₹${item.pricePerPiece.toStringAsFixed(0)} per ${item.unit}',
                                      style: AppTextTheme.bodyMedium.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (item.description != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        item.description!,
                                        style: AppTextTheme.bodySmall.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              
                              // Quantity controls
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: currentQuantity > 0
                                        ? () => _updateItemQuantity(item.name, currentQuantity - 1)
                                        : null,
                                    icon: const Icon(Icons.remove_circle_outline),
                                    color: AppColors.primary,
                                  ),
                                  Container(
                                    width: 40,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey[300]!),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        currentQuantity.toString(),
                                        style: AppTextTheme.titleMedium.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _updateItemQuantity(item.name, currentQuantity + 1),
                                    icon: const Icon(Icons.add_circle_outline),
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          Padding(padding: const EdgeInsets.only(bottom: 50),
          child: 
          // Total and save button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount:',
                      style: AppTextTheme.titleLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '₹${_totalAmount.toStringAsFixed(0)}',
                      style: AppTextTheme.titleLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'Update Order',
                    onPressed: _selectedItems.isEmpty || _isSaving ? null : _saveChanges,
                    isLoading: _isSaving,
                  ),
                ),
              ],
            ),
          ),
          ),
        ],
      ),
    );
  }
} 