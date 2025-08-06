import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../models/item_model.dart';

class AdminEditOrderScreen extends StatefulWidget {
  final OrderModel order;

  const AdminEditOrderScreen({super.key, required this.order});

  @override
  State<AdminEditOrderScreen> createState() => _AdminEditOrderScreenState();
}

class _AdminEditOrderScreenState extends State<AdminEditOrderScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Map<String, int> _selectedItems = {};
  List<ItemModel> _availableItems = [];
  bool _isLoading = true;
  bool _isSaving = false;
  double _totalAmount = 0.0;
  String? _specialInstructions;

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
    _specialInstructions = widget.order.specialInstructions;
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
          .map((doc) => ItemModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
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
          price: 0.0,
          unit: 'piece',
          isActive: true,
          updatedAt: DateTime.now(),
        ),
      );
      // Use offer price if available, otherwise use regular price
      final effectivePrice = item.offerPrice ?? item.price;
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

  Future<void> _saveChanges() async {
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
            price: 0.0,
            unit: 'piece',
            isActive: true,
            updatedAt: DateTime.now(),
          ),
        );
        
        updatedItems.add({
          'name': item.name,
          'quantity': quantity,
          'pricePerPiece': item.offerPrice ?? item.price,
          'originalPrice': item.originalPrice,
          'offerPrice': item.offerPrice,
          'category': item.category,
          'unit': item.unit,
        });
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Edit Order (Admin)'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue[700],
        elevation: 0,
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
                  'Order #${widget.order.orderNumber ?? widget.order.id.substring(0, 8)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Customer Information
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Customer: ${widget.order.customer?.name ?? 'Unknown'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                
                // Pickup Information
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Pickup: ${widget.order.pickupDate != null ? _formatDate(widget.order.pickupDate!.toDate()) : 'TBD'} • ${widget.order.pickupTimeSlot ?? 'TBD'}',
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
          
          // Special Instructions Section
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Special Instructions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _specialInstructions,
                  decoration: const InputDecoration(
                    hintText: 'Add special instructions...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  maxLines: 2,
                  onChanged: (value) {
                    _specialInstructions = value;
                  },
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
              'Edit Order Items',
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
                          border: Border.all(
                            color: currentQuantity > 0 ? Colors.blue[200]! : Colors.grey[200]!,
                            width: currentQuantity > 0 ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Item Image/Icon
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: currentQuantity > 0 ? Colors.blue[50] : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getItemIcon(item.name), 
                                color: currentQuantity > 0 ? Colors.blue[600] : Colors.grey[400],
                              ),
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
                                      if (item.originalPrice != null && item.originalPrice! > (item.offerPrice ?? item.price))
                                        Text(
                                          '₹${item.originalPrice!.toInt()}',
                                          style: const TextStyle(
                                            decoration: TextDecoration.lineThrough,
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      // Add spacing between original and offer price
                                      if (item.originalPrice != null && item.originalPrice! > (item.offerPrice ?? item.price))
                                        const SizedBox(width: 8),
                                      // Current/Offer Price
                                      Text(
                                        '₹${(item.offerPrice ?? item.price).toInt()} per ${item.unit}',
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
                                  decoration: BoxDecoration(
                                    color: currentQuantity > 0 ? Colors.blue[50] : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '$currentQuantity',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: currentQuantity > 0 ? Colors.blue[700] : Colors.grey[600],
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
        ],
      ),
      
      // Bottom Sheet with Total and Update Button
      bottomSheet: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
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
                    width: 140,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _selectedItems.isEmpty || _isSaving ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
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
                                fontSize: 16,
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