// screens/admin/manage_items.dart
import 'package:admin_panel/screens/admin/add_item_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/item_provider.dart';
import '../../models/item_model.dart';
import '../../widgets/cached_image_widget.dart';

class ManageItems extends StatefulWidget {
  const ManageItems({super.key});

  @override
  State<ManageItems> createState() => _ManageItemsState();
}

class _ManageItemsState extends State<ManageItems> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  void _refreshImages() {
    // Force refresh of the items to reload images
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    itemProvider.loadItems();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Refreshing images...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  List<ItemModel> _filterItems(List<ItemModel> items) {
    List<ItemModel> filtered = items;

    // Filter by category
    if (_selectedCategory != 'All') {
      filtered = filtered.where((item) {
        final category = item.category.toLowerCase();
        switch (_selectedCategory) {
          case 'Ironing':
            return category.contains('iron') || category == 'ironing';
          case 'Laundry':
            return category.contains('laundry') || category.contains('wash') || category.contains('dry');
          case 'Alien':
            return category.contains('alien');
          case 'Allied Services':
            return category.contains('allied') || category.contains('service');
          default:
            return true;
        }
      }).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        return item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               item.category.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return filtered;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemProvider = Provider.of<ItemProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Items'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshImages,
            tooltip: 'Refresh Images',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search items...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Category Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((category) {
                      final isSelected = _selectedCategory == category;
                      final Color categoryColor = _getCategoryColor(category);
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getCategoryIcon(category),
                                size: 16,
                                color: isSelected ? Colors.white : categoryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(category),
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          backgroundColor: categoryColor.withOpacity(0.1),
                          selectedColor: categoryColor,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : categoryColor,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          // Items List
          Expanded(
            child: StreamBuilder<List<ItemModel>>(
              stream: itemProvider.itemsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No items found. Add some items!',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final filteredItems = _filterItems(snapshot.data!);

                if (filteredItems.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No items found for "$_searchQuery" in $_selectedCategory',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return _buildItemCard(item);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_new_item_fab',
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddItemScreen()),
          );
          if (result == true) {
            // Refresh the items list
            _refreshImages();
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Add New Item',
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Ironing':
        return Colors.orange[600]!;
      case 'Laundry':
        return Colors.blue[600]!;
      case 'Alien':
        return Colors.green[600]!;
      case 'Allied Services':
        return Colors.purple[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Ironing':
        return Icons.iron;
      case 'Laundry':
        return Icons.local_laundry_service;
      case 'Alien':
        return Icons.space_dashboard;
      case 'Allied Services':
        return Icons.miscellaneous_services;
      default:
        return Icons.category;
    }
  }

  Widget _buildItemCard(ItemModel item) {
    final categoryColor = _getCategoryColor(_getCategoryFromItem(item.category));
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: categoryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Item Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[100],
              ),
              child: CachedImageWidget(
                imageUrl: item.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 16),
            // Item Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item Name and Category Badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: categoryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getCategoryIcon(_getCategoryFromItem(item.category)),
                              size: 14,
                              color: categoryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.category,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: categoryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Unit and Position
                  Text(
                    'Unit: ${item.unit}${item.sortOrder > 0 ? ' • Position: ${item.sortOrder}' : ''}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Pricing
                  Row(
                    children: [
                      // Current Price
                      Text(
                        '₹${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 16,
                        ),
                      ),
                      // Original Price (strikethrough)
                      if (item.originalPrice != null && item.originalPrice! > item.price)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            '₹${item.originalPrice!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      // Offer Price
                      if (item.offerPrice != null)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Offer: ₹${item.offerPrice!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Status and Actions Row
                  Row(
                    children: [
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: item.isActive ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: item.isActive ? Colors.green : Colors.red,
                          ),
                        ),
                        child: Text(
                          item.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: item.isActive ? Colors.green : Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Action Buttons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _navigateToEditItem(context, item),
                            tooltip: 'Edit Item',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteItem(context, item.id),
                            tooltip: 'Delete Item',
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryFromItem(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('iron') || cat == 'ironing') {
      return 'Ironing';
    } else if (cat.contains('alien')) {
      return 'Alien';
    } else if (cat.contains('allied') || cat.contains('service')) {
      return 'Allied Services';
    } else {
      return 'Laundry';
    }
  }

  Future<void> _navigateToEditItem(BuildContext context, ItemModel item) async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddItemScreen(item: item), // Pass the item for editing
        ),
      );
      if (result == true) {
        _refreshImages();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening edit screen: $e')),
      );
    }
  }

  Future<void> _deleteItem(BuildContext context, String itemId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final itemProvider = Provider.of<ItemProvider>(context, listen: false);
        await itemProvider.deleteItem(itemId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}