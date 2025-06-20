import 'package:flutter/material.dart';
import 'package:customer_app/presentation/screens/orders/schedule_pickup_delivery_screen.dart';
import 'package:customer_app/data/models/item_model.dart';

class AlliedServicesScreen extends StatefulWidget {
  const AlliedServicesScreen({super.key});

  @override
  State<AlliedServicesScreen> createState() => _AlliedServicesScreenState();
}

class _AlliedServicesScreenState extends State<AlliedServicesScreen> {
  // Service items with their quantities
  Map<String, int> serviceQuantities = {
    'bed_sheet': 0,
    'pillow_cover': 0,
    'stain_removal': 0,
  };

  // Service definitions
  final List<Map<String, dynamic>> _services = [
    {
      'id': 'bed_sheet',
      'name': 'Bed Sheet',
      'description': 'Professional cleaning and ironing',
      'price': 100.0,
      'unit': 'piece',
      'icon': Icons.bed,
      'color': Colors.blue,
      'hasPrice': true,
    },
    {
      'id': 'pillow_cover',
      'name': 'Pillow Cover',
      'description': 'Deep cleaning and fresh ironing',
      'price': 20.0,
      'unit': 'piece',
      'icon': Icons.airline_seat_individual_suite,
      'color': Colors.green,
      'hasPrice': true,
    },
    {
      'id': 'stain_removal',
      'name': 'Stain Removal',
      'description': 'Price will be notified after inspection',
      'price': 0.0,
      'unit': 'item',
      'icon': Icons.cleaning_services,
      'color': Colors.orange,
      'hasPrice': false,
    },
  ];

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
    return serviceQuantities.entries.fold<double>(0.0, (sum, entry) {
      final service = _services.firstWhere((s) => s['id'] == entry.key);
      if (service['hasPrice']) {
        return sum + (service['price'] * entry.value);
      }
      return sum;
    });
  }

  int get totalItems => serviceQuantities.values.fold(0, (sum, quantity) => sum + quantity);

  void _proceedToSchedule() {
    // Convert selected services to ItemModel format for compatibility
    final selectedItems = <ItemModel, int>{};
    
    serviceQuantities.entries.where((entry) => entry.value > 0).forEach((entry) {
      final service = _services.firstWhere((s) => s['id'] == entry.key);
      final item = ItemModel(
        id: service['id'],
        name: service['name'],
        pricePerPiece: service['price'],
        category: 'Allied Services',
        unit: service['unit'],
        isActive: true,
        order: 1,
      );
      selectedItems[item] = entry.value;
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Allied Services',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue.shade50,
                          Colors.white,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.home_repair_service,
                              color: Colors.blue.shade600,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Additional Services',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Professional cleaning and care for your bedding and special stain removal',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Services List
                  const Text(
                    'Available Services',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _services.length,
                    itemBuilder: (context, index) {
                      final service = _services[index];
                      final quantity = serviceQuantities[service['id']] ?? 0;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
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
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: (service['color'] as Color).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      service['icon'] as IconData,
                                      color: service['color'] as Color,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          service['name'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          service['description'],
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        if (service['hasPrice'])
                                          Text(
                                            '₹${service['price'].toInt()} per ${service['unit']}',
                                            style: TextStyle(
                                              color: Colors.green[600],
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          )
                                        else
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'Quote after inspection',
                                              style: TextStyle(
                                                color: Colors.orange[700],
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  // Quantity Controls
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey[300]!),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          onPressed: quantity > 0 
                                              ? () => _decrementQuantity(service['id'])
                                              : null,
                                          icon: Icon(
                                            Icons.remove,
                                            color: quantity > 0 
                                                ? Colors.grey[600] 
                                                : Colors.grey[300],
                                            size: 20,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          child: Text(
                                            '$quantity',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => _incrementQuantity(service['id']),
                                          icon: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: Colors.blue,
                                              borderRadius: BorderRadius.circular(4),
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
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Important Notes
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info, color: Colors.amber[700], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Important Notes',
                              style: TextStyle(
                                color: Colors.amber[700],
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Stain removal pricing depends on stain type and fabric\n'
                          '• Final quote will be provided after inspection\n'
                          '• All items are handled with professional care\n'
                          '• Pickup and delivery included in service',
                          style: TextStyle(
                            color: Colors.amber[700],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100), // Space for bottom sheet
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: totalItems > 0 ? _buildBottomSheet() : null,
    );
  }

  Widget _buildBottomSheet() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$totalItems item${totalItems > 1 ? 's' : ''} selected',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
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
                const SizedBox(width: 16),
                Flexible(
                  child: ElevatedButton(
                    onPressed: _proceedToSchedule,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      // padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Schedule Pickup',
                      style: TextStyle(
                        color: Colors.white,
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
    );
  }
} 