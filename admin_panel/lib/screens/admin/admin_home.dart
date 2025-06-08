// screens/admin/admin_home.dart
import 'package:admin_panel/screens/admin/item_list_screen.dart';
import 'package:admin_panel/screens/admin/manage_clients_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import 'offers_list_screen.dart';
import 'manage_items.dart';
import 'manage_banners.dart';
import 'all_orders.dart';
import 'admin_delivery_signup_screen.dart';
import 'package:intl/intl.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    const AdminDashboard(),
    const ManageClientsScreen(roleFilter: 'customer', pageTitle: 'Customers'),
    const ManageClientsScreen(roleFilter: 'delivery', pageTitle: 'Delivery Staff'),
    const ManageClientsScreen(roleFilter: 'admin', pageTitle: 'Administrators'),
    const ManageItems(),
    const ManageBanners(),
    const OffersListScreen(),
    const AllOrders(),
    const AddDeliveryPartnerScreen(),
  ];

  static final List<String> _titles = <String>[
    'Dashboard',
    'Customers',
    'Delivery Staff',
    'Administrators',
    'Manage Items',
    'Manage Banners',
    'Special Offers',
    'All Orders',
    'Add Delivery Partner',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await authProvider.signOut();
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                authProvider.userData?['name'] ?? 'Admin User',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              accountEmail: Text(authProvider.userData?['email'] ?? 'admin@example.com'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  authProvider.userData?['name']?.substring(0, 1).toUpperCase() ?? 'A',
                  style: TextStyle(fontSize: 40.0, color: Theme.of(context).primaryColor),
                ),
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
            ),
            _buildDrawerItem(Icons.dashboard_rounded, 'Dashboard', 0),
            _buildDrawerItem(Icons.people_alt_rounded, 'Customers', 1),
            _buildDrawerItem(Icons.delivery_dining_rounded, 'Delivery Staff', 2),
            _buildDrawerItem(Icons.admin_panel_settings_rounded, 'Administrators', 3),
            _buildDrawerItem(Icons.inventory_2_rounded, 'Manage Items', 4),
            _buildDrawerItem(Icons.photo_library_rounded, 'Manage Banners', 5),
            _buildDrawerItem(Icons.local_offer_rounded, 'Special Offers', 6),
            _buildDrawerItem(Icons.receipt_long_rounded, 'All Orders', 7),
            _buildDrawerItem(Icons.person_add_alt_1_rounded, 'Add Delivery Partner', 8),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.exit_to_app_rounded),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.pop(context);
                await authProvider.signOut();
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon, color: _selectedIndex == index ? Theme.of(context).primaryColor : Colors.grey[700]),
      title: Text(title, style: TextStyle(color: _selectedIndex == index ? Theme.of(context).primaryColor : Colors.black87)),
      selected: _selectedIndex == index,
      selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
      onTap: () => _onItemTapped(index),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    const double cardAspectRatio = 1.8;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard Overview',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : (MediaQuery.of(context).size.width > 700 ? 4 : 2),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: cardAspectRatio,
            children: [
              _buildStreamDashboardCard(
                stream: dashboardProvider.totalOrdersCountStream,
                title: 'Total Orders',
                icon: Icons.shopping_cart_rounded,
                color: Colors.blue.shade700,
                iconBgColor: Colors.blue.shade100,
              ),
              _buildStreamDashboardCard(
                stream: dashboardProvider.pendingOrdersCountStream,
                title: 'Pending Orders',
                icon: Icons.pending_actions_rounded,
                color: Colors.orange.shade700,
                iconBgColor: Colors.orange.shade100,
              ),
              _buildStreamDashboardCard(
                stream: dashboardProvider.ordersInProcessCountStream,
                title: 'Orders In Process',
                icon: Icons.data_usage_rounded,
                color: Colors.teal.shade700,
                iconBgColor: Colors.teal.shade100,
              ),
              _buildStreamDashboardCard(
                stream: dashboardProvider.deliveredOrdersCountStream,
                title: 'Delivered Orders',
                icon: Icons.local_shipping_rounded,
                color: Colors.green.shade700,
                iconBgColor: Colors.green.shade100,
              ),
              _buildStreamDashboardCard(
                stream: dashboardProvider.totalRevenueStream,
                title: 'Total Revenue',
                icon: Icons.monetization_on_rounded,
                color: Colors.purple.shade700,
                iconBgColor: Colors.purple.shade100,
                isCurrency: true,
                formatter: currencyFormatter,
              ),
              _buildStreamDashboardCard(
                stream: dashboardProvider.pendingQuickOrdersCountStream,
                title: 'Pending Quick Orders',
                icon: Icons.flash_on_rounded,
                color: Colors.red.shade700,
                iconBgColor: Colors.red.shade100,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Order Status Overview',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildOrderStatusOverview(context, dashboardProvider.orderStatusOverviewStream),
          
          const SizedBox(height: 24),
          Text(
            'Pickup vs Delivery Comparison',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 3)],
            ),
            child: const Center(child: Text('Pickup vs Delivery Comparison - Coming Soon')),
          )
        ],
      ),
    );
  }

  Widget _buildStreamDashboardCard<T> ({
    required Stream<T> stream,
    required String title,
    required IconData icon,
    required Color color,
    required Color iconBgColor,
    bool isCurrency = false,
    NumberFormat? formatter,
  }) {
    return StreamBuilder<T>(
      stream: stream,
      builder: (context, snapshot) {
        String valueText;
        if (snapshot.connectionState == ConnectionState.waiting) {
          valueText = '-';
        } else if (snapshot.hasError) {
          valueText = 'Error';
          print('Dashboard Card Error ($title): ${snapshot.error}');
        } else if (!snapshot.hasData) {
          valueText = '0';
        } else {
          if (isCurrency && formatter != null) {
            valueText = formatter.format(snapshot.data);
          } else {
            valueText = snapshot.data.toString();
          }
        }

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: iconBgColor,
                  child: Icon(icon, size: 24, color: color),
                ),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        valueText,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderStatusOverview(BuildContext context, Stream<Map<String, int>> stream) {
    final List<Color> itemColors = [
      Colors.blue.shade400,
      Colors.orange.shade400,
      Colors.teal.shade400,
      Colors.purple.shade400,
      Colors.red.shade400,
      Colors.green.shade400,
    ];

    return StreamBuilder<Map<String, int>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading status: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No order status data available.'));
        }

        final overviewData = snapshot.data!;
        final displayOrder = ['New Orders', 'Pending Ironing', 'In Delivery', 'In Hand', 'In Process'];
        List<Widget> statusItems = [];
        int colorIndex = 0;

        for (String key in displayOrder) {
          if (overviewData.containsKey(key)) {
            statusItems.add(_buildStatusOverviewItem(key, overviewData[key]!, itemColors[colorIndex % itemColors.length]));
            colorIndex++;
          }
        }

        return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 3)],
            ),
            child: Column(children: statusItems.isNotEmpty ? statusItems : [const Text('No data for overview.')]),
        );
      },
    );
  }

  Widget _buildStatusOverviewItem(String statusName, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(statusName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          ),
          Text(
            count.toString(),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
