// screens/item_list_screen.dart
import 'package:admin_panel/models/item_model.dart';
import 'package:admin_panel/providers/item_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'add_item_screen.dart';

class ItemListScreen extends StatefulWidget {
  const ItemListScreen({Key? key}) : super(key: key);

  @override
  State<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedStatus = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load items when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ItemProvider>(context, listen: false).loadItems();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ironing Service Items'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<ItemProvider>(context, listen: false).loadItems();
            },
            tooltip: 'Refresh Items',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_item_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddItemScreen()),
          ).then((_) {
            // Refresh items when returning from add screen
            Provider.of<ItemProvider>(context, listen: false).loadItems();
          });
        },
        backgroundColor: Colors.blue[700],
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Item', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search ironing items...',
                    prefixIcon: const Icon(Icons.search, color: Colors.blue),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue[700]!),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                
                // Category Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryChip('All'),
                      _buildCategoryChip('Shirts'),
                      _buildCategoryChip('Trousers'),
                      _buildCategoryChip('Dresses'),
                      _buildCategoryChip('Suits'),
                      _buildCategoryChip('Bedding'),
                      _buildCategoryChip('Curtains'),
                      _buildCategoryChip('Traditional'),
                      _buildCategoryChip('Other'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                
                // Status Filter
                Row(
                  children: [
                    const Text('Status: ', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(width: 8),
                    _buildStatusChip('All'),
                    const SizedBox(width: 8),
                    _buildStatusChip('Active'),
                    const SizedBox(width: 8),
                    _buildStatusChip('Inactive'),
                  ],
                ),
              ],
            ),
          ),

          // Items Count
          Consumer<ItemProvider>(
            builder: (context, itemProvider, child) {
              List<ItemModel> filteredItems = _getFilteredItems(itemProvider.items);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      '${filteredItems.length} items found',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (itemProvider.isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              );
            },
          ),

          // Items List
          Expanded(
            child: Consumer<ItemProvider>(
              builder: (context, itemProvider, child) {
                if (itemProvider.isLoading && itemProvider.items.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading ironing service items...'),
                      ],
                    ),
                  );
                }

                if (itemProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading items',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          itemProvider.error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red[600]),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            itemProvider.clearError();
                            itemProvider.loadItems();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                List<ItemModel> filteredItems = _getFilteredItems(itemProvider.items);

                if (filteredItems.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.iron, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No items found for "$_searchQuery"'
                              : 'No ironing service items available',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Try adjusting your search or filters'
                              : 'Add your first ironing service item',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_searchQuery.isNotEmpty) ...[
                          TextButton.icon(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _selectedCategory = 'All';
                                _selectedStatus = 'All';
                              });
                            },
                            icon: const Icon(Icons.clear),
                            label: const Text('Clear Filters'),
                          ),
                        ] else ...[
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AddItemScreen()),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add First Item'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await itemProvider.loadItems();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return _buildItemCard(context, item, itemProvider);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(category),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
          });
        },
        selectedColor: Colors.blue[100],
        checkmarkColor: Colors.blue[700],
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isSelected ? Colors.blue[700]! : Colors.grey[300]!,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final isSelected = _selectedStatus == status;
    Color chipColor = Colors.grey;
    if (status == 'Active') chipColor = Colors.green;
    if (status == 'Inactive') chipColor = Colors.red;
    
    return FilterChip(
      label: Text(status),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = status;
        });
      },
      selectedColor: chipColor.withOpacity(0.2),
      checkmarkColor: chipColor,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? chipColor : Colors.grey[300]!,
      ),
    );
  }

  List<ItemModel> _getFilteredItems(List<ItemModel> items) {
    List<ItemModel> filtered = items;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) =>
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.category.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    // Filter by category
    if (_selectedCategory != 'All') {
      filtered = filtered.where((item) =>
          item.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();
    }

    // Filter by status
    if (_selectedStatus != 'All') {
      filtered = filtered.where((item) =>
          _selectedStatus == 'Active' ? item.isActive : !item.isActive).toList();
    }

    return filtered;
  }

  Widget _buildItemCard(BuildContext context, ItemModel item, ItemProvider itemProvider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.blue[50],
            border: Border.all(color: Colors.blue[100]!),
          ),
          child: item.imageUrl != null && item.imageUrl!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.blue[50],
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.blue[300],
                        ),
                      ),
                    ),
                    errorWidget: (context, error, stackTrace) {
                      return Container(
                        color: Colors.blue[50],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.iron,
                              color: Colors.blue[300],
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Image\nError',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.blue[300],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    httpHeaders: const {
                      'Cache-Control': 'max-age=3600',
                    },
                  ),
                )
              : Icon(
                  Icons.iron,
                  color: Colors.blue[300],
                  size: 30,
                ),
        ),
        title: Text(
          item.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              '₹${item.price.toStringAsFixed(2)} per ${item.unit}',
              style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Text(
                    item.category,
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.isActive ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: item.isActive ? Colors.green[200]! : Colors.red[200]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.isActive ? Icons.check_circle : Icons.cancel,
                        size: 12,
                        color: item.isActive ? Colors.green[700] : Colors.red[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: item.isActive ? Colors.green[700] : Colors.red[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.grey[600]),
          onSelected: (value) async {
            switch (value) {
              case 'edit':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddItemScreen(item: item),
                  ),
                ).then((_) {
                  // Refresh items when returning from edit screen
                  itemProvider.loadItems();
                });
                break;
              case 'toggle_status':
                await itemProvider.toggleItemStatus(item.id);
                if (itemProvider.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${itemProvider.error}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Item ${item.isActive ? 'deactivated' : 'activated'} successfully',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
                break;
              case 'delete':
                _showDeleteConfirmation(context, item, itemProvider);
                break;
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit, color: Colors.blue),
                title: Text('Edit Item'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem<String>(
              value: 'toggle_status',
              child: ListTile(
                leading: Icon(
                  item.isActive ? Icons.visibility_off : Icons.visibility,
                  color: item.isActive ? Colors.orange : Colors.green,
                ),
                title: Text(item.isActive ? 'Deactivate' : 'Activate'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () {
          _showItemDetails(context, item);
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, ItemModel item, ItemProvider itemProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange[600]),
              const SizedBox(width: 8),
              const Text('Delete Item'),
            ],
          ),
          content: Text('Are you sure you want to delete "${item.name}"?\n\nThis action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
                
                final success = await itemProvider.deleteItem(item.id);
                
                // Hide loading
                Navigator.of(context).pop();
                
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Item deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting item: ${itemProvider.error}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showItemDetails(BuildContext context, ItemModel item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Container(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.iron, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    const Text(
                      'Item Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(),
                
                // Image
                if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                  Container(
                    height: 150,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: item.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.iron,
                                  size: 50,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Failed to load image',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                
                // Item Info
                _buildDetailRow('Name', item.name),
                _buildDetailRow('Price', '₹${item.price.toStringAsFixed(2)} per ${item.unit}'),
                if (item.originalPrice != null)
                  _buildDetailRow('Original Price', '₹${item.originalPrice!.toStringAsFixed(2)} per ${item.unit}'),
                if (item.offerPrice != null)
                  _buildDetailRow('Offer Price', '₹${item.offerPrice!.toStringAsFixed(2)} per ${item.unit}'),
                _buildDetailRow('Category', item.category),
                _buildDetailRow('Status', item.isActive ? 'Active' : 'Inactive'),
                _buildDetailRow('Unit', item.unit),
                if (item.sortOrder > 0)
                  _buildDetailRow('Display Position', item.sortOrder.toString()),
                // _buildDetailRow('Created', '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}'),
                _buildDetailRow('Last Updated', '${item.updatedAt.day}/${item.updatedAt.month}/${item.updatedAt.year}'),
                
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}