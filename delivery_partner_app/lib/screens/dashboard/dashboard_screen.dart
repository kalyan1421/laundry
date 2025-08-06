// screens/dashboard/dashboard_screen.dart - Delivery Partner Dashboard
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/delivery_partner_model.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../tasks/task_detail_screen.dart';

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
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          print('🚚 🔄 Dashboard: Manual refresh triggered');
          
          // Refresh stats
          await _loadStats();
          
          // Refresh order data via OrderProvider
          final orderProvider = context.read<OrderProvider>();
          await orderProvider.refreshOrderData(widget.deliveryPartner.id);
          orderProvider.refreshData();
          
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
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Header with greeting and stats
              _buildHeader(),
              
              // Quick stats cards
              _buildStatsCards(),
              
              // Today's tasks section
              _buildTodaysTasks(),
              
              // Tab bar for pickups/deliveries
              _buildTabBar(),
              
              // Task list based on selected tab
              _buildTaskList(),
            ],
          ),
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

  Widget _buildHeader() {
    final currentHour = DateTime.now().hour;
    String greeting = 'Good Morning';
    if (currentHour >= 12 && currentHour < 17) {
      greeting = 'Good Afternoon';
    } else if (currentHour >= 17) {
      greeting = 'Good Evening';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting,',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontFamily: 'SFProDisplay',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.deliveryPartner.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'SFProDisplay',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildHeaderStat(
                'Today Completed',
                _stats['todayCompleted']?.toString() ?? '0',
                Icons.check_circle_outline,
              ),
              const SizedBox(width: 24),
              _buildHeaderStat(
                'Pending',
                _stats['todayPending']?.toString() ?? '0',
                Icons.access_time,
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

  Widget _buildStatsCards() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'This Week',
              _stats['weekCompleted']?.toString() ?? '0',
              'Completed',
              Colors.green,
              Icons.trending_up,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'This Month',
              _stats['monthCompleted']?.toString() ?? '0',
              'Completed',
              Colors.blue,
              Icons.calendar_month,
            ),
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

  Widget _buildTodaysTasks() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
              const Text(
                'Today\'s Schedule',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SFProDisplay',
                ),
              ),
              Text(
                DateFormat('MMM dd, yyyy').format(DateTime.now()),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontFamily: 'SFProDisplay',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<OrderModel>>(
            stream: context.read<OrderProvider>().getTodayTasksStream(widget.deliveryPartner.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No tasks scheduled for today',
                      style: TextStyle(
                        color: Colors.grey,
                        fontFamily: 'SFProDisplay',
                      ),
                    ),
                  ),
                );
              }
              
              return Column(
                children: snapshot.data!.take(3).map((order) {
                  return _buildTodayTaskItem(order);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTodayTaskItem(OrderModel order) {
    bool isPickup = order.status == 'confirmed' || order.status == 'ready_for_pickup';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isPickup ? Colors.orange[100] : Colors.green[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isPickup ? Icons.arrow_upward : Icons.arrow_downward,
              color: isPickup ? Colors.orange[700] : Colors.green[700],
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.orderNumber ?? 'N/A',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    fontFamily: 'SFProDisplay',
                  ),
                ),
                Text(
                  isPickup ? 'Pickup' : 'Delivery',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontFamily: 'SFProDisplay',
                  ),
                ),
              ],
            ),
          ),
          Text(
            order.status.replaceAll('_', ' ').toUpperCase(),
            style: TextStyle(
              color: isPickup ? Colors.orange[700] : Colors.green[700],
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'SFProDisplay',
            ),
          ),
        ],
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
    bool isPickup = order.status == 'confirmed' || order.status == 'ready_for_pickup';
    
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