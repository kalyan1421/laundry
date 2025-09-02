import 'package:customer_app/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:customer_app/presentation/screens/orders/schedule_pickup_delivery_screen.dart';
import 'package:customer_app/data/models/item_model.dart';
import 'package:customer_app/presentation/providers/allied_service_provider.dart';

class AlliedServicesScreen extends StatefulWidget {
  const AlliedServicesScreen({super.key});

  @override
  State<AlliedServicesScreen> createState() => _AlliedServicesScreenState();
}

class _AlliedServicesScreenState extends State<AlliedServicesScreen> {
  // Service items with their quantities
  Map<String, int> serviceQuantities = {};

  @override
  void initState() {
    super.initState();
    // Load allied services when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AlliedServiceProvider>(context, listen: false)
          .loadAlliedServices();
    });
  }

  void _incrementQuantity(String serviceId) {
    setState(() {
      serviceQuantities[serviceId] = (serviceQuantities[serviceId] ?? 0) + 1;
    });
  }

  void _decrementQuantity(String serviceId) {
    setState(() {
      if ((serviceQuantities[serviceId] ?? 0) > 0) {
        serviceQuantities[serviceId] = (serviceQuantities[serviceId] ?? 0) - 1;
      }
    });
  }

  double get totalAmount {
    final alliedServiceProvider =
        Provider.of<AlliedServiceProvider>(context, listen: false);
    return serviceQuantities.entries.fold<double>(0.0, (sum, entry) {
      try {
        final service = alliedServiceProvider.getServiceById(entry.key);
        if (service != null && service.hasPrice) {
          return sum + (service.effectivePrice * entry.value);
        }
        return sum;
      } catch (e) {
        return sum;
      }
    });
  }

  int get totalItems =>
      serviceQuantities.values.fold(0, (sum, quantity) => sum + quantity);

  void _proceedToSchedule() {
    // Convert selected services to ItemModel format for compatibility
    final selectedItems = <ItemModel, int>{};

    final alliedServiceProvider =
        Provider.of<AlliedServiceProvider>(context, listen: false);

    serviceQuantities.entries
        .where((entry) => entry.value > 0)
        .forEach((entry) {
      final service = alliedServiceProvider.getServiceById(entry.key);
      if (service != null) {
        final item = ItemModel(
          id: service.id,
          name: service.name,
          pricePerPiece: service.effectivePrice,
          offerPrice: service.hasOffer ? service.effectivePrice : null,
          category: service.category,
          unit: service.unit,
          isActive: service.isActive,
          order: service.sortOrder,
        );
        selectedItems[item] = entry.value;
      }
    });

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one service.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SchedulePickupDeliveryScreen(
          selectedItems: selectedItems,
          totalAmount: totalAmount,
          isAlliedServices: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        foregroundColor: context.onBackgroundColor,
        backgroundColor: context.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: context.onBackgroundColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Allied Services',
          style: TextStyle(
            color: context.onBackgroundColor,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.refresh, color: Colors.black),
        //     onPressed: () {
        //       Provider.of<AlliedServiceProvider>(context, listen: false)
        //           .refreshServices();
        //     },
        //   ),
        // ],
      ),
      body: Consumer<AlliedServiceProvider>(
        builder: (context, alliedServiceProvider, child) {
          if (alliedServiceProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (alliedServiceProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
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
                    alliedServiceProvider.error!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => alliedServiceProvider.refreshServices(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final services = alliedServiceProvider.alliedServices;

          if (services.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_laundry_service,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No allied services available',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Check back later for new services',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // // Header Section
                // Container(
                //   width: double.infinity,
                //   padding: const EdgeInsets.all(20),
                //   decoration: BoxDecoration(
                //     gradient: LinearGradient(
                //       begin: Alignment.topLeft,
                //       end: Alignment.bottomRight,
                //       colors: [
                //         Colors.blue.shade50,
                //         Colors.white,
                //       ],
                //     ),
                //     borderRadius: BorderRadius.circular(12),
                //     border: Border.all(color: Colors.blue.shade100),
                //   ),
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       Row(
                //         children: [
                //           Icon(
                //             Icons.home_repair_service,
                //             color: Colors.blue.shade600,
                //             size: 28,
                //           ),
                //           const SizedBox(width: 12),
                //           Text(
                //             'Additional Services',
                //             style: TextStyle(
                //               fontSize: 20,
                //               color: context.onInverseSurface,
                //               fontWeight: FontWeight.bold,
                //             ),
                //           ),
                //         ],
                //       ),
                //       const SizedBox(height: 8),
                //       Text(
                //         'Professional washing and care for your bedding and special stain removal',
                //         style: TextStyle(
                //           color: Colors.grey[600],
                //           fontSize: 14,
                //         ),
                //       ),
                //     ],
                //   ),
                // ),

                // Services List
                // const Text(
                //   'Available Services',
                //   style: TextStyle(
                //     fontSize: 18,
                //     fontWeight: FontWeight.bold,
                //   ),
                // ),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final service = services[index];
                    final quantity = serviceQuantities[service.id] ?? 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.outlineVariant),
                        boxShadow: [
                          BoxShadow(
                            color: context.shadowColor.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Service Image or Icon - smaller size to match ironing items
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: context.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: service.imageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: service.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorWidget: (context, url, error) => Icon(
                                        Icons.local_laundry_service,
                                        color: context.onSurfaceVariant,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.local_laundry_service,
                                    color: context.onSurfaceVariant,
                                  ),
                          ),
                          const SizedBox(width: 16),
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
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    // Offer badge - same as regular items
                                    if (service.offerPrice != null && service.originalPrice != null && service.originalPrice! > service.offerPrice!)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade100,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${(((service.originalPrice! - service.offerPrice!) / service.originalPrice!) * 100).toInt()}% OFF',
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                // Price display with original and offer prices (exactly matching regular items)
                                Row(
                                  children: [
                                    // Original Price (strikethrough) - Show first if there's an offer
                                    if (service.originalPrice != null &&
                                        service.originalPrice! >
                                            (service.offerPrice ?? service.price))
                                      Text(
                                        '₹${service.originalPrice!.toInt()}',
                                        style: TextStyle(
                                          decoration: TextDecoration.lineThrough,
                                          color: context.onSurfaceVariant,
                                          fontSize: 12,
                                        ),
                                      ),
                                    // Add spacing between original and offer price
                                    if (service.originalPrice != null &&
                                        service.originalPrice! >
                                            (service.offerPrice ?? service.price))
                                      const SizedBox(width: 8),
                                    // Current/Offer Price
                                    if (service.hasPrice)
                                      Text(
                                        '₹${(service.offerPrice ?? service.price).toInt()} per ${service.unit}',
                                        style: TextStyle(
                                          color: service.offerPrice != null
                                              ? Theme.of(context).colorScheme.tertiary
                                              : context.onSurfaceVariant,
                                          fontSize: 14,
                                          fontWeight: service.offerPrice != null
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                      )
                                    else
                                      Text(
                                        'Quote after inspection',
                                        style: TextStyle(
                                          color: Colors.orange[700],
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Quantity Controls matching ironing items design
                          Row(
                            children: [
                              IconButton(
                                onPressed: quantity > 0
                                    ? () => _decrementQuantity(service.id)
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _incrementQuantity(service.id),
                                icon: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.add,
                                    color: Theme.of(context).colorScheme.onPrimary,
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

                const SizedBox(height: 24),

                // Important Notes
                // Container(
                //   padding: const EdgeInsets.all(16),
                //   decoration: BoxDecoration(
                //     color: Colors.amber.withOpacity(0.1),
                //     borderRadius: BorderRadius.circular(8),
                //     border: Border.all(color: Colors.amber.withOpacity(0.3)),
                //   ),
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       Row(
                //         children: [
                //           Icon(Icons.info, color: Colors.amber[700], size: 20),
                //           const SizedBox(width: 8),
                //           Text(
                //             'Important Notes',
                //             style: TextStyle(
                //               color: Colors.amber[700],
                //               fontWeight: FontWeight.w600,
                //               fontSize: 14,
                //             ),
                //           ),
                //         ],
                //       ),
                //       const SizedBox(height: 8),
                //       Text(
                //         '• Stain removal pricing depends on stain type and fabric\n'
                //         '• Final quote will be provided after inspection\n'
                //         '• All items are handled with professional care\n'
                //         '• Pickup and delivery included in service',
                //         style: TextStyle(
                //           color: Colors.amber[700],
                //           fontSize: 12,
                //         ),
                //       ),
                //     ],
                //   ),
                // ),

                const SizedBox(height: 24),

                // Space for bottom sheet
                if (totalItems > 0) const SizedBox(height: 120),
              ],
            ),
          );
        },
      ),
      bottomSheet: totalItems > 0 ? _buildStickyCartSummary() : null,
    );
  }

  Widget _buildStickyCartSummary() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 50),
      child: Container(
        decoration: BoxDecoration(
          color: context.backgroundColor,
            borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: context.shadowColor.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.outlineVariant),
            ),
            padding:
                const EdgeInsets.fromLTRB(16, 16, 16, 20), // 20px from bottom
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cart Summary Row
                Row(
                  children: [
                    // Cart Icon with Badge
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F3057).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.shopping_cart,
                            color: Color(0xFF0F3057),
                            size: 24,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$totalItems',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),

                    // Amount Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$totalItems item${totalItems > 1 ? 's' : ''} selected',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (totalAmount > 0)
                            Text(
                              '₹${totalAmount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            )
                          else
                            const Text(
                              'Quote on inspection',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Schedule Button
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: ElevatedButton(
                        onPressed: _proceedToSchedule,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F3057),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Schedule',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
