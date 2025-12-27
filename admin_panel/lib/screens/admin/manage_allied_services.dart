// screens/admin/manage_allied_services.dart
import 'package:admin_panel/screens/admin/add_allied_service_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/allied_service_provider.dart';
import '../../models/allied_service_model.dart';

class ManageAlliedServices extends StatefulWidget {
  const ManageAlliedServices({super.key});

  @override
  State<ManageAlliedServices> createState() => _ManageAlliedServicesState();
}

class _ManageAlliedServicesState extends State<ManageAlliedServices> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  final List<String> _subCategories = [
    'Allied Services',
    'Laundry', 
    'Special Services',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _subCategories.length, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase().trim();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alliedServiceProvider = Provider.of<AlliedServiceProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Search Bar - Outside StreamBuilder to prevent rebuild on stream update
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search services...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[500]),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF0F3057), width: 1.5),
                ),
              ),
            ),
          ),
          // StreamBuilder for the rest of the content
          Expanded(
            child: StreamBuilder<List<AlliedServiceModel>>(
              stream: alliedServiceProvider.alliedServicesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F3057)),
                        ),
                        SizedBox(height: 16),
                        Text('Loading services...'),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading services',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => alliedServiceProvider.loadAlliedServices(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F3057),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final alliedServices = snapshot.data ?? [];

                return Column(
                  children: [
                    // Enhanced Tab Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Statistics Row
                    // Container(
                    //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    //   child: Row(
                    //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    //     children: _subCategories.map((subCategory) {
                    //       final servicesInCategory = alliedServices
                    //           .where((service) => service.subCategory == subCategory)
                    //           .length;
                    //       final activeServices = alliedServices
                    //           .where((service) => service.subCategory == subCategory && service.isActive)
                    //           .length;
                          
                    //       return Expanded(
                    //         child: Container(
                    //           margin: const EdgeInsets.symmetric(horizontal: 4),
                    //           padding: const EdgeInsets.all(12),
                    //           decoration: BoxDecoration(
                    //             color: _getSubCategoryColor(subCategory).withOpacity(0.1),
                    //             borderRadius: BorderRadius.circular(8),
                    //             border: Border.all(
                    //               color: _getSubCategoryColor(subCategory).withOpacity(0.3),
                    //             ),
                    //           ),
                    //           child: Column(
                    //             children: [
                    //               Icon(
                    //                 _getSubCategoryIcon(subCategory),
                    //                 color: _getSubCategoryColor(subCategory),
                    //                 size: 20,
                    //               ),
                    //               const SizedBox(height: 4),
                    //               // Text(
                    //               //   '$servicesInCategory',
                    //               //   style: TextStyle(
                    //               //     fontSize: 18,
                    //               //     fontWeight: FontWeight.bold,
                    //               //     color: _getSubCategoryColor(subCategory),
                    //               //   ),
                    //               // ),
                    //               Text(
                    //                 '$activeServices active',
                    //                 style: TextStyle(
                    //                   fontSize: 10,
                    //                   color: Colors.grey[600],
                    //                 ),
                    //               ),
                    //             ],
                    //           ),
                    //         ),
                    //       );
                    //     }).toList(),
                    //   ),
                    // ),
                    // Tab Bar
                    TabBar(
                      controller: _tabController,
                      isScrollable: false,
                      labelColor: const Color(0xFF0F3057),
                      unselectedLabelColor: Colors.grey[600],
                      indicatorColor: const Color(0xFF0F3057),
                      indicatorWeight: 3,
                      indicatorPadding: const EdgeInsets.symmetric(horizontal: 16),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 14,
                      ),
                      tabs: _subCategories.map((subCategory) {
                        return Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getSubCategoryIcon(subCategory),
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  _getShortName(subCategory),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: _subCategories.map((subCategory) {
                    var servicesInCategory = alliedServices
                        .where((service) => service.subCategory == subCategory)
                        .toList();
                    
                    // Apply search filter
                    if (_searchQuery.isNotEmpty) {
                      servicesInCategory = servicesInCategory.where((service) {
                        return service.name.toLowerCase().contains(_searchQuery) ||
                               service.description.toLowerCase().contains(_searchQuery) ||
                               service.subCategory.toLowerCase().contains(_searchQuery);
                      }).toList();
                    }
                    
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_allied_service_fab',
        onPressed: () {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddAlliedServiceScreen()),
            );
          }
        },
        backgroundColor: const Color(0xFF0F3057),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Service'),
      ),
    );
  }

  String _getShortName(String subCategory) {
    switch (subCategory.toLowerCase()) {
      case 'allied services':
        return 'Allied';
      case 'laundry':
        return 'Laundry';
      case 'special services':
        return 'Special';
      default:
        return subCategory;
    }
  }

  Widget _buildTabContent(String subCategory, List<AlliedServiceModel> services, AlliedServiceProvider provider) {
    if (services.isEmpty) {
      // Check if it's empty due to search or no services at all
      final isSearchResult = _searchQuery.isNotEmpty;
      
      return Container(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isSearchResult 
                      ? Colors.grey.withOpacity(0.1)
                      : _getSubCategoryColor(subCategory).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSearchResult ? Icons.search_off : _getSubCategoryIcon(subCategory),
                  size: 64,
                  color: isSearchResult 
                      ? Colors.grey[400]
                      : _getSubCategoryColor(subCategory),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isSearchResult 
                    ? 'No Results Found'
                    : 'No $subCategory Found',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSearchResult
                    ? 'No services match "$_searchQuery" in $subCategory'
                    : 'Add your first $subCategory service to get started',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (isSearchResult)
                OutlinedButton.icon(
                  onPressed: () {
                    _searchController.clear();
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear Search'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F3057),
                    side: const BorderSide(color: Color(0xFF0F3057)),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
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
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await provider.loadAlliedServices();
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: services.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final service = services[index];
          return _buildServiceCard(service, provider);
        },
      ),
    );
  }

  Color _getSubCategoryColor(String subCategory) {
    switch (subCategory.toLowerCase()) {
      case 'allied services':
        return const Color(0xFF2196F3);
      case 'laundry':
        return const Color(0xFF4CAF50);
      case 'special services':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFFFF9800);
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
      elevation: 3,
      shadowColor: Colors.grey.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey[50]!,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Service Image
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[200],
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: service.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: service.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey[100],
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey[200],
                                ),
                                child: Icon(
                                  _getSubCategoryIcon(service.subCategory),
                                  size: 32,
                                  color: _getSubCategoryColor(service.subCategory),
                                ),
                              ),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: _getSubCategoryColor(service.subCategory).withOpacity(0.1),
                            ),
                            child: Icon(
                              _getSubCategoryIcon(service.subCategory),
                              size: 32,
                              color: _getSubCategoryColor(service.subCategory),
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),

                  // Service Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                service.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: service.isActive ? Colors.green : Colors.grey,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Switch(
                                value: service.isActive,
                                onChanged: (value) {
                                  provider.toggleServiceStatus(service.id, value);
                                },
                                activeColor: Colors.white,
                                activeTrackColor: Colors.green,
                                inactiveThumbColor: Colors.white,
                                inactiveTrackColor: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          service.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Tags and Price Row
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getSubCategoryColor(service.subCategory).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getSubCategoryColor(service.subCategory).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getSubCategoryIcon(service.subCategory),
                          size: 14,
                          color: _getSubCategoryColor(service.subCategory),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          service.subCategory,
                          style: TextStyle(
                            fontSize: 12,
                            color: _getSubCategoryColor(service.subCategory),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: service.hasPrice ? Colors.green[50] : Colors.orange[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: service.hasPrice ? Colors.green[300]! : Colors.orange[300]!,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          service.hasPrice ? Icons.currency_rupee : Icons.visibility,
                          size: 14,
                          color: service.hasPrice ? Colors.green[700] : Colors.orange[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          service.hasPrice 
                              ? '₹${service.price.toStringAsFixed(0)}/${service.unit}'
                              : 'Price on inspection',
                          style: TextStyle(
                            fontSize: 12,
                            color: service.hasPrice ? Colors.green[700] : Colors.orange[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Text(
                      'Order: ${service.sortOrder}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
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
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue[700],
                        side: BorderSide(color: Colors.blue[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showDeleteDialog(service, provider),
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red[700],
                        side: BorderSide(color: Colors.red[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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

  void _showDeleteDialog(AlliedServiceModel service, AlliedServiceProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red[600], size: 28),
            const SizedBox(width: 12),
            const Text('Delete Service'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${service.name}"?'),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.deleteAlliedService(service.id, service.imageUrl);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          success ? Icons.check_circle : Icons.error,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Text(success 
                            ? 'Service deleted successfully' 
                            : 'Failed to delete service'),
                      ],
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}