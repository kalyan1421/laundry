import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import '../models/order_model.dart'; // Assuming OrderModel is correctly defined

class DashboardProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  Stream<int> get totalOrdersCountStream {
    return _dbService.getAllOrders().map((orders) => orders.length);
  }

  // Corresponds to 'Pending Orders' in the UI image
  Stream<int> get pendingOrdersCountStream {
    return _dbService.getAllOrders().map((orders) {
      return orders.where((order) => order.status == 'pending' || order.status == 'confirmed').length;
    });
  }

  // Corresponds to 'Orders in Process' in the UI image
  Stream<int> get ordersInProcessCountStream {
    return _dbService.getAllOrders().map((orders) {
      return orders.where((order) => 
          order.status == 'picked_up' || 
          order.status == 'processing' || 
          order.status == 'ready'
      ).length;
    });
  }

  // Corresponds to 'Delivered Orders' in the UI image
  Stream<int> get deliveredOrdersCountStream {
    return _dbService.getAllOrders().map((orders) {
      return orders.where((order) => order.status == 'delivered').length;
    });
  }

  Stream<double> get totalRevenueStream {
    return _dbService.getAllOrders().map((orders) {
      double total = 0.0;
      for (var order in orders.where((o) => o.status == 'delivered')) {
        total += order.totalAmount; // Assuming totalAmount is a double
      }
      return total;
    });
  }

  Stream<int> get pendingQuickOrdersCountStream {
    // Assuming getQuickOrderNotifications returns List<Map<String, dynamic>>
    // and each map has a 'status' field.
    return _dbService.getQuickOrderNotifications().map((notifications) {
      return notifications.where((notification) => notification['status'] == 'pending').length;
    });
  }

  // For "Order Status Overview" in the UI image
  Stream<Map<String, int>> get orderStatusOverviewStream {
    return _dbService.getAllOrders().map((orders) {
      Map<String, int> overview = {
        'New Orders': 0,      // Typically 'pending' or 'confirmed'
        'Pending Ironing': 0, // Typically 'processing'
        'In Delivery': 0,     // Typically 'out_for_delivery'
        'In Hand': 0,         // Typically 'picked_up' (from customer) or 'ready' (for delivery)
        'In Process': 0,      // This might be redundant or a broader category than 'Pending Ironing'. 
                              // The UI shows 'Orders in Process' as a KPI and 'In Process' in overview.
                              // For now, let's map 'processing' to 'Pending Ironing' and also to 'In Process' for the overview,
                              // or choose one. The design has specific numbers for these.
                              // Let's map based on common interpretations:
      };

      for (var order in orders) {
        if (order.status == 'pending' || order.status == 'confirmed') {
          overview['New Orders'] = (overview['New Orders'] ?? 0) + 1;
        }
        if (order.status == 'processing') { // For 'Pending Ironing'
          overview['Pending Ironing'] = (overview['Pending Ironing'] ?? 0) + 1;
        }
        if (order.status == 'out_for_delivery') {
          overview['In Delivery'] = (overview['In Delivery'] ?? 0) + 1;
        }
        if (order.status == 'picked_up' || order.status == 'ready') { // For 'In Hand'
            overview['In Hand'] = (overview['In Hand'] ?? 0) + 1;
        }
        if (order.status == 'processing') { // For 'In Process' in overview (can be same as Pending Ironing or broader)
            overview['In Process'] = (overview['In Process'] ?? 0) + 1;
        }
      }
      // The provided UI image for Order Status Overview has:
      // New Orders: 420
      // Pending Ironing: 210
      // In Delivery: 320
      // In Hand: 95
      // In Process: 160
      // These numbers might not sum up or directly relate to the top KPI cards if 'In Process' in overview
      // is a subset of 'Orders in Process' KPI, or if 'Pending Ironing' is a subset of 'In Process'.
      // For now, the mapping above is a starting point.
      return overview;
    });
  }

  // You might also want a method for "Pickup vs Delivery Comparison"
  // This would likely involve counting orders based on a 'serviceType' field (e.g., 'pickup', 'delivery_request')
  // or analyzing addresses.
  // Stream<Map<String, int>> get pickupVsDeliveryComparisonStream { ... }
} 