// screens/delivery/delivery_home.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/fcm_service.dart';

import '../../models/order_model.dart';
import './task_detail_screen.dart';
import './quick_order_notifications.dart';
import '../../utils/phone_formatter.dart';

class DeliveryHome extends StatefulWidget {
  const DeliveryHome({super.key});

  @override
  State<DeliveryHome> createState() => _DeliveryHomeState();
}

class _DeliveryHomeState extends State<DeliveryHome> {
  @override
  void initState() {
    super.initState();
    _refreshData();
    
    // Ensure FCM token is saved when delivery home loads
    _ensureFCMToken();
  }

  void _refreshData() {
    // Refresh order data by triggering a rebuild
    if (mounted) {
      setState(() {
        // Force rebuild to refresh streams
      });
    }
  }

  void _ensureFCMToken() async {
    try {
      final fcmService = FcmService();
      await fcmService.ensureDeliveryPartnerTokenSaved();
      print('FCM token ensured for delivery partner');
    } catch (e) {
      print('Error ensuring FCM token: $e');
    }
  }

  void _refreshFCMToken() async {
    try {
      final fcmService = FcmService();
      
      // First check current token status
      Map<String, dynamic> tokenStatus = await fcmService.checkDeliveryPartnerFCMToken();
      print('Current FCM token status: $tokenStatus');
      
      // Force refresh the token
      Map<String, dynamic> refreshResult = await fcmService.forceRefreshDeliveryToken();
      
      if (mounted) {
        if (refreshResult['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FCM Token Refreshed Successfully'),
                  if (tokenStatus['deliveryPartnerName'] != null)
                    Text('Partner: ${tokenStatus['deliveryPartnerName']}', 
                         style: TextStyle(fontSize: 12)),
                  if (tokenStatus['documentId'] != null)
                    Text('Doc ID: ${tokenStatus['documentId']}', 
                         style: TextStyle(fontSize: 12)),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${refreshResult['error']}'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing FCM token: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showFCMTokenDebugInfo() async {
    final fcmService = FcmService();
    Map<String, dynamic> tokenInfo = await fcmService.checkDeliveryPartnerFCMToken();
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('FCM Token Debug Info'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                                 _buildDebugRow('Has Token', tokenInfo['hasToken']?.toString() ?? 'Unknown'),
                 _buildDebugRow('Document ID', tokenInfo['documentId']?.toString() ?? 'Not Found'),
                 _buildDebugRow('Partner Name', tokenInfo['deliveryPartnerName']?.toString() ?? 'Unknown'),
                 _buildDebugRow('Phone Number', tokenInfo['phoneNumber']?.toString() ?? 'Unknown'),
                 _buildDebugRow('Matched By', tokenInfo['matchedBy']?.toString() ?? 'Unknown'),
                 _buildDebugRow('Is Active', tokenInfo['isActive']?.toString() ?? 'Unknown'),
                 _buildDebugRow('Last Updated', tokenInfo['lastUpdated']?.toString() ?? 'Unknown'),
                 if (tokenInfo['error'] != null)
                   _buildDebugRow('Error', tokenInfo['error'].toString()),
                 if (tokenInfo['token'] != null)
                   _buildDebugRow('Token (Preview)', '${tokenInfo['token'].toString().substring(0, 20)}...'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
            TextButton(
              onPressed: () async {
                if (tokenInfo['documentId'] != null) {
                  final result = await FcmService.testDeliveryPartnerNotificationFlow(tokenInfo['documentId']);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['success'] ? 'Test notification sent!' : 'Test failed: ${result['error']}'),
                        backgroundColor: result['success'] ? Colors.green : Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text('Test Notification'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _refreshFCMToken();
              },
              child: Text('Refresh Token'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDebugRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: DeliveryDashboard(userId: userId),
      ),
    );
  }
}

class DeliveryDashboard extends StatefulWidget {
  final String userId;

  const DeliveryDashboard({super.key, required this.userId});

  @override
  State<DeliveryDashboard> createState() => _DeliveryDashboardState();
}

class _DeliveryDashboardState extends State<DeliveryDashboard> {
  int _selectedTabIndex = 0; // 0 for Pickups, 1 for Deliveries

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);

    return SingleChildScrollView(
      child: SizedBox(
        height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Stats Cards
            _buildStatsCards(orderProvider),
            
            // Today's Schedule - Make it smaller to prevent overflow
            _buildTodaysSchedule(orderProvider),
            
            // Tasks Section
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Tab Bar
                    _buildTabBar(),
                    
                    // Task List
                    Expanded(
                      child: _buildTaskList(orderProvider),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Refresh FCM Token',
                onPressed: () {
                  final state = context.findAncestorStateOfType<_DeliveryHomeState>();
                  state?._refreshFCMToken();
                },
                onLongPress: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('FCM Debug Information'),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FutureBuilder<Map<String, dynamic>>(
                              future: FcmService().checkDeliveryPartnerFCMToken(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return CircularProgressIndicator();
                                }
                                
                                if (snapshot.hasData) {
                                  Map<String, dynamic> tokenInfo = snapshot.data!;
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('📱 FCM Token Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text('Has Token: ${tokenInfo['hasToken']}'),
                                      if (tokenInfo['token'] != null) 
                                        Text('Token: ${tokenInfo['token'].toString().substring(0, 20)}...'),
                                      Text('Document ID: ${tokenInfo['documentId'] ?? 'N/A'}'),
                                      Text('Partner Name: ${tokenInfo['deliveryPartnerName'] ?? 'N/A'}'),
                                      Text('Phone: ${tokenInfo['phoneNumber'] ?? 'N/A'}'),
                                      Text('Active: ${tokenInfo['isActive'] ?? 'N/A'}'),
                                      Text('Matched By: ${tokenInfo['matchedBy'] ?? 'N/A'}'),
                                      Text('Last Updated: ${tokenInfo['lastUpdated'] ?? 'N/A'}'),
                                      if (tokenInfo['error'] != null)
                                        Text('Error: ${tokenInfo['error']}', style: TextStyle(color: Colors.red)),
                                      SizedBox(height: 10),
                                      ElevatedButton(
                                        onPressed: () async {
                                          // Get the navigator before any async operations
                                          final navigator = Navigator.of(context);
                                          final messenger = ScaffoldMessenger.of(context);
                                          
                                          navigator.pop();
                                          
                                          // Test enhanced notification with real order data
                                          String? testOrderId = '0Uo57xDyzuqWshz4Bxao'; // Use the order ID from your image
                                          
                                          messenger.showSnackBar(
                                            SnackBar(content: Text('Sending enhanced test notification...'))
                                          );
                                          
                                          Map<String, dynamic> result = await FcmService()
                                              .testEnhancedDeliveryPartnerNotificationFlow(testOrderId: testOrderId);
                                          
                                          // Show result in a new snackbar instead of dialog to avoid context issues
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                result['success'] 
                                                  ? '✅ Notification sent! Order: ${result['orderNumber'] ?? 'N/A'}, Customer: ${result['customerName'] ?? 'N/A'}'
                                                  : '❌ Failed: ${result['error'] ?? 'Unknown error'}'
                                              ),
                                              backgroundColor: result['success'] ? Colors.green : Colors.red,
                                              duration: Duration(seconds: 5),
                                            ),
                                          );
                                        },
                                        child: Text('🚀 Test Enhanced Notification'),
                                      ),
                                    ],
                                  );
                                }
                                
                                return Text('Error loading token info');
                              },
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('delivery')
                    .doc(widget.userId)
                    .collection('notifications')
                    .where('read', isEqualTo: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  int unreadCount = snapshot.data?.docs.length ?? 0;
                  
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuickOrderNotifications(userId: widget.userId),
                            ),
                          );
                        },
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              // Logout Button
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                tooltip: 'Logout',
                onPressed: () => _showLogoutConfirmation(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Add logout confirmation method
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
                         ElevatedButton(
               onPressed: () async {
                 // Store references before async operations
                 final navigator = Navigator.of(context);
                 final messenger = ScaffoldMessenger.of(context);
                 final authProvider = Provider.of<AuthProvider>(context, listen: false);
                 
                 navigator.pop(); // Close confirmation dialog
                 
                 // Show loading indicator
                 showDialog(
                   context: context,
                   barrierDismissible: false,
                   builder: (context) => const Center(
                     child: CircularProgressIndicator(),
                   ),
                 );
                 
                 try {
                   // Perform logout
                   await authProvider.signOut();
                   
                   // AuthWrapper will automatically handle navigation to login screen
                   // Try to close loading dialog with stored navigator reference
                   try {
                     navigator.pop(); // Close loading dialog
                   } catch (e) {
                     // Ignore navigation errors after logout as widget may be disposed
                   }
                 } catch (e) {
                   // Handle logout error
                   try {
                     navigator.pop(); // Close loading dialog
                     messenger.showSnackBar(
                       SnackBar(
                         content: Text('Logout failed: $e'),
                         backgroundColor: Colors.red,
                       ),
                     );
                   } catch (navError) {
                     // Ignore navigation errors if widget is disposed
                   }
                 }
               },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsCards(OrderProvider orderProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: StreamBuilder<List<OrderModel>>(
        stream: orderProvider.getDeliveryOrdersStream(widget.userId),
        builder: (context, snapshot) {
          final orders = snapshot.data ?? [];
          final todayOrders = _getTodayOrders(orders);
          final pickups = _getPickupOrders(orders);
          final deliveries = _getDeliveryOrders(orders);
          
          return Row(
            children: [
              Expanded(child: _buildStatCard('Tasks', orders.length.toString(), Icons.list_alt, const Color(0xFF6366F1))),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Pickups', pickups.length.toString(), Icons.get_app, const Color(0xFF3B82F6))),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Deliveries', deliveries.length.toString(), Icons.local_shipping, const Color(0xFF10B981))),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Today', todayOrders.length.toString(), Icons.today, const Color(0xFFF59E0B))),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildTodaysSchedule(OrderProvider orderProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s Schedule',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<OrderModel>>(
            stream: orderProvider.getDeliveryOrdersStream(widget.userId),
            builder: (context, snapshot) {
              final todayOrders = _getTodayOrders(snapshot.data ?? []);
              if (todayOrders.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No tasks scheduled for today',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              final displayOrders = todayOrders.take(2).toList();
              return Column(
                children: displayOrders.asMap().entries.map((entry) {
                  int index = entry.key;
                  OrderModel order = entry.value;
                  bool isLast = index == displayOrders.length - 1;
                  return _buildScheduleItem(order, isLast);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(OrderModel order, bool isLast) {
    final isPickup = _isPickupTask(order);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isPickup ? const Color(0xFF3B82F6) : const Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast) // Fixed: Use the isLast parameter instead of comparing with empty list
                Container(
                  width: 2,
                  height: 40,
                  color: Colors.grey[300],
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Task info
          Expanded(
            child: GestureDetector(
              onTap: () => _navigateToTaskDetail(order),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _getTaskTime(order),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(order.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            order.status.replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              color: _getStatusColor(order.status),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${isPickup ? 'Pickup' : 'Delivery'} - Order #${order.orderNumber ?? order.id.substring(0, 8)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      order.customer?.name ?? order.customer?.phoneNumber ?? 'phone  not available',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton('Pickups', 0),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTabButton('Deliveries', 1),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E3A8A) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskList(OrderProvider orderProvider) {
    return StreamBuilder<List<OrderModel>>(
      stream: orderProvider.getDeliveryOrdersStream(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final orders = snapshot.data ?? [];
        final filteredOrders = _selectedTabIndex == 0 
            ? _getPickupOrders(orders) 
            : _getDeliveryOrders(orders);

        if (filteredOrders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _selectedTabIndex == 0 ? Icons.get_app : Icons.local_shipping,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${_selectedTabIndex == 0 ? 'pickups' : 'deliveries'} assigned',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          itemCount: filteredOrders.length,
          itemBuilder: (context, index) {
            final order = filteredOrders[index];
            return _buildTaskCard(order);
          },
        );
      },
    );
  }

  Widget _buildTaskCard(OrderModel order) {
    final isPickup = _isPickupTask(order);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _navigateToTaskDetail(order),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Left indicator bar
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: isPickup ? const Color(0xFF3B82F6) : const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              // Order info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Order #${order.orderNumber ?? order.id.substring(0, 8)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _getTaskTime(order),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Customer name (if available)
                    if (order.customer?.name != null) ...[
                      Text(
                        'Customer: ${order.customer!.name}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    // Client ID (Phone number without +91)
                    Text(
                      'Client ID: ${PhoneFormatter.getClientId(order.customer?.phoneNumber)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Enhanced address display
                    Text(
                      _getDisplayAddress(order, isPickup),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Order details (amount and items)
                    if (order.totalAmount > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '₹${order.totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.green[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (order.items.isNotEmpty) ...[
                            Text(' • ', style: TextStyle(color: Colors.grey[400])),
                            Text(
                              '${order.items.fold<int>(0, (sum, item) => sum + item.quantity)} items',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(order.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            order.status.replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              color: _getStatusColor(order.status),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Colors.blue[600],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods
  List<OrderModel> _getTodayOrders(List<OrderModel> orders) {
    final today = DateTime.now();
    return orders.where((order) {
      final orderDate = order.orderTimestamp.toDate();
      return orderDate.year == today.year &&
             orderDate.month == today.month &&
             orderDate.day == today.day;
    }).toList();
  }

  List<OrderModel> _getPickupOrders(List<OrderModel> orders) {
    return orders.where((order) => _isPickupTask(order)).toList();
  }

  List<OrderModel> _getDeliveryOrders(List<OrderModel> orders) {
    return orders.where((order) => !_isPickupTask(order)).toList();
  }

  bool _isPickupTask(OrderModel order) {
    return ['pending', 'confirmed', 'assigned', 'ready_for_pickup'].contains(order.status);
  }

  String _getTaskTime(OrderModel order) {
    if (order.pickupDate != null && order.pickupTimeSlot != null) {
      return order.pickupTimeSlot!;
    }
    if (order.deliveryDate != null && order.deliveryTimeSlot != null) {
      return order.deliveryTimeSlot!;
    }
    return DateFormat('HH:mm a').format(order.orderTimestamp.toDate());
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'confirmed':
      case 'assigned':
        return const Color(0xFF3B82F6);
      case 'processing':
      case 'in_progress':
        return const Color(0xFF8B5CF6);
      case 'ready_for_pickup':
      case 'ready_for_delivery':
        return const Color(0xFF06B6D4);
      case 'out_for_delivery':
        return const Color(0xFF10B981);
      case 'delivered':
      case 'completed':
        return const Color(0xFF059669);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _getDisplayAddress(OrderModel order, bool isPickup) {
    if (isPickup) {
      return order.pickupAddress ?? 'Pickup address not available';
    } else {
      // For delivery, prefer the structured address
      if (order.deliveryAddressDetails != null) {
        return order.deliveryAddressDetails!.fullAddress;
      }
      return order.deliveryAddress ?? 'Delivery address not available';
    }
  }

  void _navigateToTaskDetail(OrderModel order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(order: order),
      ),
    );
  }
}
