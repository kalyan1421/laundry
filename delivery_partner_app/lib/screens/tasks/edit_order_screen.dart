import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../services/item_service.dart';

class EditOrderScreen extends StatefulWidget {
  final OrderModel order;

  const EditOrderScreen({
    Key? key,
    required this.order,
  }) : super(key: key);

  @override
  State<EditOrderScreen> createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends State<EditOrderScreen> {
  late List<Map<String, dynamic>> _editableItems;
  late TextEditingController _notesController;
  bool _isLoading = false;
  double _totalAmount = 0.0;
  final ItemService _itemService = ItemService();
  Map<String, Map<String, dynamic>> _itemDetails = {};

  @override
  void initState() {
    super.initState();
    _editableItems = widget.order.items.map((item) => {
      'itemId': item['itemId'] ?? '',
      'itemName': item['itemName'] ?? '',
      'quantity': item['quantity'] ?? 1,
      'price': (item['price'] ?? 0.0).toDouble(),
      'originalPrice': (item['originalPrice'] ?? item['price'] ?? 0.0).toDouble(),
      'category': item['category'] ?? '',
      'unit': item['unit'] ?? 'piece',
    }).toList();
    
    _notesController = TextEditingController();
    _calculateTotal();
    _loadItemDetails();
  }

  Future<void> _loadItemDetails() async {
    // Extract item IDs from order
    final itemIds = _editableItems
        .map((item) => item['itemId']?.toString())
        .where((id) => id != null && id.isNotEmpty)
        .cast<String>()
        .toList();

    if (itemIds.isNotEmpty) {
      print('✏️ EditOrder: Loading details for ${itemIds.length} items');
      final itemDetails = await _itemService.getItemsByIds(itemIds);
      
      if (mounted) {
        setState(() {
          _itemDetails = itemDetails;
          // Update editable items with resolved names
          for (int i = 0; i < _editableItems.length; i++) {
            final itemId = _editableItems[i]['itemId']?.toString();
            if (itemId != null && itemDetails.containsKey(itemId)) {
              final details = itemDetails[itemId]!;
              _editableItems[i]['itemName'] = details['name'] ?? _editableItems[i]['itemName'];
              _editableItems[i]['category'] = details['category'] ?? _editableItems[i]['category'];
              _editableItems[i]['unit'] = details['unit'] ?? _editableItems[i]['unit'];
              _editableItems[i]['originalPrice'] = details['price'] ?? _editableItems[i]['originalPrice'];
            }
          }
        });
        print('✏️ EditOrder: Loaded ${itemDetails.length} item details');
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    _totalAmount = _editableItems.fold(0.0, (sum, item) {
      return sum + ((item['quantity'] as int) * (item['price'] as double));
    });
    setState(() {});
  }

  void _updateItemQuantity(int index, int newQuantity) {
    if (newQuantity >= 0) {
      setState(() {
        _editableItems[index]['quantity'] = newQuantity;
      });
      _calculateTotal();
    }
  }

  void _updateItemPrice(int index, double newPrice) {
    if (newPrice >= 0) {
      setState(() {
        _editableItems[index]['price'] = newPrice;
      });
      _calculateTotal();
    }
  }

  void _removeItem(int index) {
    setState(() {
      _editableItems.removeAt(index);
    });
    _calculateTotal();
  }

  Future<void> _saveChanges() async {
    if (_editableItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order must have at least one item'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final orderProvider = context.read<OrderProvider>();
    
    // Filter out items with zero quantity
    final validItems = _editableItems.where((item) => (item['quantity'] as int) > 0).toList();
    
    final success = await orderProvider.updateOrderItems(
      widget.order.id,
      validItems,
      _totalAmount,
      pickupNotes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // Return true to indicate changes were made
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.error ?? 'Failed to update order'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Order ${widget.order.orderNumber}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'SFProDisplay',
          ),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _saveChanges,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SFProDisplay',
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer info (read-only)
                  _buildCustomerInfoCard(),
                  
                  const SizedBox(height: 20),
                  
                  // Editable items
                  _buildEditableItemsCard(),
                  
                  const SizedBox(height: 20),
                  
                  // Notes section
                  _buildNotesCard(),
                  
                  const SizedBox(height: 30),
                  
                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SFProDisplay',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCustomerInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customer Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'SFProDisplay',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.person, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                widget.order.customerName,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'SFProDisplay',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.phone, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                widget.order.customerPhone,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'SFProDisplay',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditableItemsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Items (Editable)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'SFProDisplay',
            ),
          ),
          const SizedBox(height: 16),
          
          // Items list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _editableItems.length,
            itemBuilder: (context, index) {
              final item = _editableItems[index];
              return _buildEditableItemRow(item, index);
            },
          ),
          
          const Divider(thickness: 2),
          
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SFProDisplay',
                ),
              ),
              Text(
                '₹${_totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontFamily: 'SFProDisplay',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditableItemRow(Map<String, dynamic> item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item['itemName'] ?? 'Unknown Item',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    fontFamily: 'SFProDisplay',
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _removeItem(index),
                icon: const Icon(Icons.delete, color: Colors.red),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              // Quantity controls
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quantity',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontFamily: 'SFProDisplay',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _updateItemQuantity(index, (item['quantity'] as int) - 1),
                          icon: const Icon(Icons.remove_circle_outline),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '${item['quantity']}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'SFProDisplay',
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _updateItemQuantity(index, (item['quantity'] as int) + 1),
                          icon: const Icon(Icons.add_circle_outline),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Price controls
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Price per piece',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontFamily: 'SFProDisplay',
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      initialValue: (item['price'] as double).toStringAsFixed(2),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        prefixText: '₹',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                      onChanged: (value) {
                        final price = double.tryParse(value) ?? 0.0;
                        _updateItemPrice(index, price);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Item total
          Text(
            'Item Total: ₹${((item['quantity'] as int) * (item['price'] as double)).toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.green,
              fontFamily: 'SFProDisplay',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pickup Notes (Optional)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'SFProDisplay',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Add any notes about the pickup or changes made...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }
}
