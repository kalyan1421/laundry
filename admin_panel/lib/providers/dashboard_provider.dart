import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import '../models/order_model.dart'; // Assuming OrderModel is correctly defined

class DashboardProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  Stream<int> get totalOrdersCountStream {
    return _dbService.getAllOrders()
        .map((orders) => orders.length)
        .handleError((error) {
          print('Dashboard Error (Total Orders): $error');
          return 0;
        });
  }

  // Corresponds to 'Pending Orders' in the UI image
  Stream<int> get pendingOrdersCountStream {
    return _dbService.getAllOrders()
        .map((orders) {
          return orders.where((order) => order.status == 'pending' || order.status == 'confirmed').length;
        })
        .handleError((error) {
          print('Dashboard Error (Pending Orders): $error');
          return 0;
        });
  }

  // Corresponds to 'Orders in Process' in the UI image
  Stream<int> get ordersInProcessCountStream {
    return _dbService.getAllOrders()
        .map((orders) {
          return orders.where((order) => 
              order.status == 'picked_up' || 
              order.status == 'processing' || 
              order.status == 'ready'
          ).length;
        })
        .handleError((error) {
          print('Dashboard Error (Orders In Process): $error');
          return 0;
        });
  }

  // Corresponds to 'Delivered Orders' in the UI image
  Stream<int> get deliveredOrdersCountStream {
    return _dbService.getAllOrders()
        .map((orders) {
          return orders.where((order) => order.status == 'delivered').length;
        })
        .handleError((error) {
          print('Dashboard Error (Delivered Orders): $error');
          return 0;
        });
  }

  Stream<double> get totalRevenueStream {
    return _dbService.getAllOrders()
        .map((orders) {
          double total = 0.0;
          for (var order in orders.where((o) => o.status == 'delivered')) {
            total += order.totalAmount;
          }
          return total;
        })
        .handleError((error) {
          print('Dashboard Error (Total Revenue): $error');
          return 0.0;
        });
  }



  // For "Order Status Overview" in the UI image
  Stream<Map<String, int>> get orderStatusOverviewStream {
    return _dbService.getAllOrders()
        .map((orders) {
          Map<String, int> overview = {
            'New Orders': 0,      // Typically 'pending' or 'confirmed'
            'Pending Ironing': 0, // Typically 'processing'
            'In Delivery': 0,     // Typically 'out_for_delivery'
            'In Hand': 0,         // Typically 'picked_up' (from customer) or 'ready' (for delivery)
            'In Process': 0,      // This might be redundant or a broader category than 'Pending Ironing'. 
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
          return overview;
        })
        .handleError((error) {
          print('Dashboard Error (Order Status Overview): $error');
          return <String, int>{
            'New Orders': 0,
            'Pending Ironing': 0,
            'In Delivery': 0,
            'In Hand': 0,
            'In Process': 0,
          };
        });
  }

  // You might also want a method for "Pickup vs Delivery Comparison"
  // This would likely involve counting orders based on a 'serviceType' field (e.g., 'pickup', 'delivery_request')
  // or analyzing addresses.
  // Stream<Map<String, int>> get pickupVsDeliveryComparisonStream { ... }
} 