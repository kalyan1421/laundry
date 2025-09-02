// screens/orders/orders_screen.dart - Orders List Screen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/delivery_partner_model.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../tasks/task_detail_screen.dart';
import '../../widgets/custom_bottom_navigation.dart';

class OrdersScreen extends StatefulWidget {
  final DeliveryPartnerModel deliveryPartner;

  const OrdersScreen({
    super.key,
    required this.deliveryPartner,
  });

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Custom header
          _buildModernHeader(),
          
          // Tab bar
          _buildTabBar(),
          
          // Content based on selected tab
          Expanded(
            child: _buildTabContent(),
          ),
          
          // Enhanced Bottom navigation
          EnhancedBottomNavigation(
            currentIndex: 1,
            deliveryPartner: widget.deliveryPartner,
          ),
        ],
      ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row with back and notifications
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    color: Color(0xFF1E3A8A),
                    size: 20,
                  ),
                ),
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
          
          const SizedBox(height: 20),
          
          // Page title
          Text(
            'My Orders',
            style: TextStyle(
              color: Colors.black,
              fontSize: 32,
              fontWeight: FontWeight.bold,
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
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton('Active', 0),
          ),
          Expanded(
            child: _buildTabButton('Completed', 1),
          ),
          Expanded(
            child: _buildTabButton('Cancelled', 2),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _currentTabIndex == index;
    return GestureDetector(
      onTap: () {
        _tabController.animateTo(index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF00BFFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Color(0xFF9E9E9E),
            fontWeight: FontWeight.w600,
            fontFamily: 'SFProDisplay',
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_currentTabIndex) {
      case 0:
        return _buildOrdersList(['assigned', 'confirmed', 'ready_for_pickup', 'picked_up', 'in_transit']);
      case 1:
        return _buildOrdersList(['delivered', 'completed']);
      case 2:
        return _buildOrdersList(['cancelled']);
      default:
        return _buildOrdersList(['assigned', 'confirmed', 'ready_for_pickup']);
    }
  }

  Widget _buildOrdersList(List<String> statuses) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: StreamBuilder<List<OrderModel>>(
        stream: context.read<OrderProvider>().getOrdersByStatuses(widget.deliveryPartner.id, statuses),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00BFFF),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 64,
                    color: Color(0xFF9E9E9E),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No orders found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF9E9E9E),
                      fontFamily: 'SFProDisplay',
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 20),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final order = snapshot.data![index];
              return _buildModernOrderItem(order);
            },
          );
        },
      ),
    );
  }

  Widget _buildModernOrderItem(OrderModel order) {
    // Determine if it's pickup or delivery
    final pickupStatuses = ['assigned', 'confirmed', 'ready_for_pickup'];
    bool isPickup = pickupStatuses.contains(order.status);
    
    Color statusColor = Color(0xFF9E9E9E);
    if (order.status == 'completed' || order.status == 'delivered') {
      statusColor = Color(0xFF4CAF50);
    } else if (order.status == 'cancelled') {
      statusColor = Color(0xFFFF5722);
    } else if (isPickup) {
      statusColor = Color(0xFF00BFFF);
    }

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
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFE0E0E0), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isPickup ? Icons.north_east : Icons.south_east,
                color: statusColor,
                size: 20,
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


}
