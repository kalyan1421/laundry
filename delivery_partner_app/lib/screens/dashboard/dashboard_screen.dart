// screens/dashboard/dashboard_screen.dart - Delivery Partner Dashboard
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/delivery_partner_model.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../tasks/task_detail_screen.dart';
import '../../widgets/custom_bottom_navigation.dart';

class DashboardScreen extends StatefulWidget {
  final DeliveryPartnerModel deliveryPartner;

  const DashboardScreen({
    super.key,
    required this.deliveryPartner,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTabIndex = 0; // 0 for Pickups, 1 for Deliveries
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    print('🚚 🎯 Dashboard: Initializing for delivery partner ID: ${widget.deliveryPartner.id}');
    print('🚚 🎯 Dashboard: Delivery partner name: ${widget.deliveryPartner.name}');
    _loadStats();
  }

  Future<void> _loadStats() async {
    final orderProvider = context.read<OrderProvider>();
    
    print('🚚 🆕 Dashboard: Loading stats with NEW simplified approach');
    
    final stats = await orderProvider.getDeliveryPartnerStats(widget.deliveryPartner.id);
    if (mounted) {
      setState(() {
        _stats = stats;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () async {
          print('🚚 🔄 Dashboard: Manual refresh triggered');
          
          // Refresh stats
          await _loadStats();
          
          // Force refresh all order data via OrderProvider
          final orderProvider = context.read<OrderProvider>();
          await orderProvider.forceRefreshAllData(widget.deliveryPartner.id);
          
          // Show feedback
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.refresh, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Dashboard refreshed'),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
          }
        },
        child: Column(
          children: [
            // Custom header without AppBar
            _buildModernHeader(),
            
            // Content section
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Today's stats cards
                    _buildTodayStats(),
                    
                    // Today's schedule section
                    _buildTodaysSchedule(),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            
            // Enhanced Bottom navigation
            EnhancedBottomNavigation(
              currentIndex: 0,
              deliveryPartner: widget.deliveryPartner,
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1E3A8A),
      foregroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'Dashboard',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontFamily: 'SFProDisplay',
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            // TODO: Navigate to notifications
          },
        ),

        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'profile':
                _showProfileDialog();
                break;
              case 'debug':
                _runDiagnostics();
                break;
              case 'logout':
                _showLogoutDialog();
                break;
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person_outline),
                  SizedBox(width: 8),
                  Text('Profile'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'debug',
              child: Row(
                children: [
                  Icon(Icons.bug_report),
                  SizedBox(width: 8),
                  Text('Debug Orders'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout),
                  SizedBox(width: 8),
                  Text('Logout'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF87CEEB), Color(0xFFB8E6FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Top row with logo and notifications
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.iron,
                    color: Color(0xFF1E3A8A),
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Cloud Ironing Factory',
                    style: TextStyle(
                      color: Color(0xFF1E3A8A),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SFProDisplay',
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFF1E3A8A),
                  size: 20,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 30),
          
          // Profile section
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  Icons.person,
                  color: Color(0xFF1E3A8A),
                  size: 30,
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Text(
                  widget.deliveryPartner.name,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SFProDisplay',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 20,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'SFProDisplay',
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontFamily: 'SFProDisplay',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTodayStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontFamily: 'SFProDisplay',
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color(0xFFE8F5E8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Color(0xFFC8E6C9), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Completed\nOrders',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'SFProDisplay',
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        _stats['todayCompleted']?.toString() ?? '20',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'SFProDisplay',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Color(0xFFFFE082), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pending\nOrders',
                        style: TextStyle(
                          color: Color(0xFFF57F17),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'SFProDisplay',
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        _stats['todayPending']?.toString() ?? '5',
                        style: TextStyle(
                          color: Color(0xFFF57F17),
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'SFProDisplay',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String period, String value, String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                period,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontFamily: 'SFProDisplay',
                ),
              ),
              Icon(
                icon,
                color: color,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'SFProDisplay',
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontFamily: 'SFProDisplay',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysSchedule() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Today \'s Schedule',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SFProDisplay',
                  color: Colors.black,
                ),
              ),
              Text(
                DateFormat('dd MMM yyyy').format(DateTime.now()),
                style: const TextStyle(
                  color: Color(0xFF9E9E9E),
                  fontSize: 14,
                  fontFamily: 'SFProDisplay',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Tab buttons for Pickups/Deliveries
          Container(
            decoration: BoxDecoration(
              color: Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTabIndex = 0;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTabIndex == 0 ? Color(0xFF1E3A8A) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Pickups',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _selectedTabIndex == 0 ? Colors.white : Color(0xFF9E9E9E),
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SFProDisplay',
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTabIndex = 1;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTabIndex == 1 ? Color(0xFF1E3A8A) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Deliveries',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _selectedTabIndex == 1 ? Colors.white : Color(0xFF9E9E9E),
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SFProDisplay',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Orders list
          StreamBuilder<List<OrderModel>>(
            stream: _selectedTabIndex == 0
                ? context.read<OrderProvider>().getPickupTasksStream(widget.deliveryPartner.id)
                : context.read<OrderProvider>().getDeliveryTasksStream(widget.deliveryPartner.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No tasks scheduled',
                      style: TextStyle(
                        color: Color(0xFF9E9E9E),
                        fontFamily: 'SFProDisplay',
                      ),
                    ),
                  ),
                );
              }
              
              return Column(
                children: snapshot.data!.take(3).map((order) {
                  return _buildModernTaskItem(order);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModernTaskItem(OrderModel order) {
    // Match the same statuses used in OrderProvider.getPickupTasksStream
    final pickupStatuses = ['assigned', 'confirmed', 'ready_for_pickup'];
    bool isPickup = pickupStatuses.contains(order.status);
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailScreen(order: order),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFE0E0E0), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isPickup ? Color(0xFFFFF3E0) : Color(0xFFE8F5E8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isPickup ? Icons.north_east : Icons.south_east,
                color: isPickup ? Color(0xFFFF8F00) : Color(0xFF4CAF50),
                size: 18,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.orderNumber ?? 'N/A',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      fontFamily: 'SFProDisplay',
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${isPickup ? 'Pickup' : 'Delivery'} Assigned',
                    style: const TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 14,
                      fontFamily: 'SFProDisplay',
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Color(0xFF9E9E9E),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton('Pickups', 0),
          ),
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
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E3A8A) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.w600,
            fontFamily: 'SFProDisplay',
          ),
        ),
      ),
    );
  }

  Widget _buildTaskList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
      child: StreamBuilder<List<OrderModel>>(
        stream: _selectedTabIndex == 0
            ? context.read<OrderProvider>().getPickupTasksStream(widget.deliveryPartner.id)
            : context.read<OrderProvider>().getDeliveryTasksStream(widget.deliveryPartner.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      _selectedTabIndex == 0 
                          ? Icons.arrow_upward 
                          : Icons.arrow_downward,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _selectedTabIndex == 0 
                          ? 'No pickup tasks available'
                          : 'No delivery tasks available',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                        fontFamily: 'SFProDisplay',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final order = snapshot.data![index];
              return _buildTaskItem(order);
            },
          );
        },
      ),
    );
  }

  Widget _buildTaskItem(OrderModel order) {
    // Match the same statuses used in OrderProvider.getPickupTasksStream
    final pickupStatuses = ['assigned', 'confirmed', 'ready_for_pickup'];
    bool isPickup = pickupStatuses.contains(order.status);
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isPickup ? Colors.orange[100] : Colors.green[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isPickup ? Icons.arrow_upward : Icons.arrow_downward,
          color: isPickup ? Colors.orange[700] : Colors.green[700],
        ),
      ),
      title: Text(
        order.orderNumber ?? 'N/A',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontFamily: 'SFProDisplay',
        ),
      ),
      subtitle: Text(
        '${isPickup ? 'Pickup' : 'Delivery'} • ${order.status.replaceAll('_', ' ').toUpperCase()}',
        style: const TextStyle(
          fontSize: 12,
          fontFamily: 'SFProDisplay',
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailScreen(order: order),
          ),
        );
      },
    );
  }

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${widget.deliveryPartner.name}'),
            Text('Phone: ${widget.deliveryPartner.phoneNumber}'),
            Text('Email: ${widget.deliveryPartner.email}'),
            Text('License: ${widget.deliveryPartner.licenseNumber}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _runDiagnostics() async {
    final orderProvider = context.read<OrderProvider>();
    
    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('🔍 Running diagnostics...'),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
    
    // Run full diagnostic and refresh
    await orderProvider.forceRefreshAllData(widget.deliveryPartner.id);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔍 Diagnostics completed. Check console logs for details.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().signOut();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }



} 