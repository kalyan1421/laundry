// screens/admin/manage_allied_services.dart
import 'package:admin_panel/screens/admin/add_allied_service_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/allied_service_provider.dart';
import '../../models/allied_service_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class ManageAlliedServices extends StatefulWidget {
  const ManageAlliedServices({super.key});

  @override
  State<ManageAlliedServices> createState() => _ManageAlliedServicesState();
}

class _ManageAlliedServicesState extends State<ManageAlliedServices> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final List<String> _subCategories = [
    'Allied Services',
    'Laundry', 
    'Special Services',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _subCategories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final alliedServiceProvider = Provider.of<AlliedServiceProvider>(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddAlliedServiceScreen()),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
      
      body: StreamBuilder<List<AlliedServiceModel>>(
        stream: alliedServiceProvider.alliedServicesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => alliedServiceProvider.loadAlliedServices(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final alliedServices = snapshot.data ?? [];

          return Column(
            children: [
              // Tab Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF0F3057),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFF0F3057),
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 14,
                  ),
                  tabs: _subCategories.map((subCategory) {
                    final servicesInCategory = alliedServices
                        .where((service) => service.subCategory == subCategory)
                        .length;
                    
                    return Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getSubCategoryIcon(subCategory),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(subCategory),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getSubCategoryColor(subCategory),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$servicesInCategory',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: _subCategories.map((subCategory) {
                    final servicesInCategory = alliedServices
                        .where((service) => service.subCategory == subCategory)
                        .toList();
                    
                    // Sort services by sortOrder, then by name
                    servicesInCategory.sort((a, b) {
                      if (a.sortOrder != b.sortOrder) {
                        return a.sortOrder.compareTo(b.sortOrder);
                      }
                      return a.name.compareTo(b.name);
                    });

                    return _buildTabContent(subCategory, servicesInCategory, alliedServiceProvider);
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabContent(String subCategory, List<AlliedServiceModel> services, AlliedServiceProvider provider) {
    if (services.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getSubCategoryIcon(subCategory),
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No $subCategory services found',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first $subCategory service to get started',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddAlliedServiceScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: Text('Add $subCategory Service'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getSubCategoryColor(subCategory),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildServiceCard(service, provider),
        );
      },
    );
  }

  Color _getSubCategoryColor(String subCategory) {
    switch (subCategory.toLowerCase()) {
      case 'allied services':
        return Colors.blue;
      case 'laundry':
        return Colors.green;
      case 'special services':
        return Colors.purple;
      default:
        return Colors.orange;
    }
  }

  IconData _getSubCategoryIcon(String subCategory) {
    switch (subCategory.toLowerCase()) {
      case 'allied services':
        return Icons.cleaning_services;
      case 'laundry':
        return Icons.local_laundry_service;
      case 'special services':
        return Icons.star_border;
      default:
        return Icons.room_service;
    }
  }

  Widget _buildServiceCard(AlliedServiceModel service, AlliedServiceProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  child: service.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: service.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) => const Icon(
                              Icons.local_laundry_service,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.local_laundry_service,
                          size: 40,
                          color: Colors.grey,
                        ),
                ),
                const SizedBox(width: 16),

                // Service Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              service.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Active/Inactive Toggle
                          Switch(
                            value: service.isActive,
                            onChanged: (value) {
                              provider.toggleServiceStatus(service.id, value);
                            },
                            activeColor: Colors.green,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        service.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getSubCategoryColor(service.subCategory).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: _getSubCategoryColor(service.subCategory).withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getSubCategoryIcon(service.subCategory),
                                  size: 12,
                                  color: _getSubCategoryColor(service.subCategory),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  service.subCategory,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _getSubCategoryColor(service.subCategory),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: service.hasPrice ? Colors.green[50] : Colors.orange[50],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: service.hasPrice ? Colors.green[200]! : Colors.orange[200]!,
                              ),
                            ),
                            child: Text(
                              service.hasPrice 
                                  ? '₹${service.price.toStringAsFixed(0)}/${service.unit}'
                                  : 'Price on inspection',
                              style: TextStyle(
                                fontSize: 12,
                                color: service.hasPrice ? Colors.green[700] : Colors.orange[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Order: ${service.sortOrder}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddAlliedServiceScreen(service: service),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _showDeleteDialog(service, provider),
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(AlliedServiceModel service, AlliedServiceProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service'),
        content: Text('Are you sure you want to delete "${service.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.deleteAlliedService(service.id, service.imageUrl);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success 
                        ? 'Service deleted successfully' 
                        : 'Failed to delete service'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}