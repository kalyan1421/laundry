// screens/admin/admin_home.dart
import 'package:admin_panel/screens/admin/manage_customer_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import 'offers_list_screen.dart';
import 'manage_items.dart';
import 'manage_banners.dart';
import 'all_orders.dart';
import 'admin_delivery_signup_screen.dart';
import 'admin_token_debug_screen.dart';
import 'add_workshop_worker_screen.dart';
import 'manage_workshop_workers_screen.dart';
import 'order_notifications_screen.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/delivery_partner_service.dart';
import 'test_delivery_notification_screen.dart';
import 'debug_delivery_assignment_screen.dart';
import 'manage_admins_screen.dart';
import 'manage_delivery_partners_screen.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    const AdminDashboard(),
    const AllOrders(),
    // const OrderNotificationsScreen(),
    const ManageClientsScreen(roleFilter: 'customer', pageTitle: 'Customers'),
    const ManageClientsScreen(roleFilter: 'delivery', pageTitle: 'Delivery Staff'),
    const ManageAdminsScreen(),
    const ManageClientsScreen(roleFilter: 'supervisor', pageTitle: 'Supervisors'),
    const ManageItems(),
    const ManageBanners(),
    const OffersListScreen(),
    AddDeliveryPartnerScreen(),
    const AddDeliveryPartnerScreen(),
    const AddWorkshopWorkerScreen(),
    const ManageWorkshopWorkersScreen(),
  ];

  static final List<String> _titles = <String>[
    'Dashboard',
    'All Orders',
    // 'Order Notifications',
    'Customers',
    'Delivery Staff',
    'Administrators',
    'Supervisors',
    'Manage Items',
    'Manage Banners',
    'Special Offers',
    'Add Delivery Person',
    'Add Workshop Worker',
    'Manage Workshop Workers',
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              if (value == 'refresh_notifications') {
                try {
                  await authProvider.refreshFCMToken();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notification token refreshed successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to refresh notification token: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else if (value == 'logout') {
                await authProvider.signOut();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'refresh_notifications',
                child: Row(
                  children: [
                    Icon(Icons.notifications_active),
                    SizedBox(width: 8),
                    Text('Refresh Notifications'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Sign Out'),
                  ],
                ),
              ),
            ],
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
            _buildDrawerItem(Icons.shopping_cart_rounded, 'All Orders', 1),
            // _buildDrawerItemWithBadge(Icons.notifications_rounded, 'Order Notifications', 2),
            _buildDrawerItem(Icons.people_alt_rounded, 'Customers', 2),
            _buildDrawerItem(Icons.delivery_dining_rounded, 'Delivery Staff',  3),
            ListTile(
              leading: const Icon(Icons.add_road_rounded),
              title: const Text('Manage Delivery Partners'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/manage-delivery-partners');
              },
            ),
            _buildDrawerItem(Icons.admin_panel_settings_rounded, 'Administrators', 4),
            ListTile(
              leading: const Icon(Icons.person_add_rounded),
              title: const Text('Add New Admin'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/add-admin');
              },
            ),
            _buildDrawerItem(Icons.groups_rounded, 'Supervisors', 5),
              _buildDrawerItem(Icons.inventory_2_rounded, 'Manage Items', 6),
            _buildDrawerItem(Icons.photo_library_rounded, 'Manage Banners', 7),
            _buildDrawerItem(Icons.local_offer_rounded, 'Special Offers', 8),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.notifications_active),
              title: const Text('Notification Tokens'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AdminTokenDebugScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.send),
              title: const Text('Test Delivery Notifications'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const TestDeliveryNotificationScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('Debug Order Assignments'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const DebugDeliveryAssignmentScreen(),
                  ),
                );
              },
            ),
            // _buildDrawerItem(Icons.receipt_long_rounded, 'All Orders', 7),
            _buildDrawerItem(Icons.person_add_alt_1_rounded, 'Add Delivery Person', 10),
            const Divider(),
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 4.0),
              child: Text(
                'Workshop Management',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            ),
            _buildDrawerItem(Icons.engineering_rounded, 'Add Workshop Worker', 11),
            _buildDrawerItem(Icons.groups_rounded, 'Manage Workshop Workers', 12),
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

  Widget _buildDrawerItemWithBadge(IconData icon, String title, int index) {
    return StreamBuilder<int>(
      stream: _getUnreadNotificationsCount(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        
        return ListTile(
          leading: Stack(
            children: [
              Icon(icon),
              if (unreadCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
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
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
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
          ),
          title: Text(title),
          selected: _selectedIndex == index,
          onTap: () => _onItemTapped(index),
        );
      },
    );
  }

  Stream<int> _getUnreadNotificationsCount() {
    return FirebaseFirestore.instance
        .collectionGroup('notifications')
        .where('forAdmin', isEqualTo: true)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
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
          _buildMigrationSection(context),

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

  Widget _buildMigrationSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.system_update, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'System Migration',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Migrate existing delivery partners to the new phone index system for faster authentication.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _runMigration(context),
              icon: const Icon(Icons.upgrade),
              label: const Text('Migrate Delivery Partners'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runMigration(BuildContext context) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Migrate Delivery Partners'),
        content: const Text(
          'This will create phone index entries for existing delivery partners to enable faster authentication. This is safe to run multiple times.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Start Migration'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Migrating delivery partners...'),
              ],
            ),
          ),
        );

                 // Run migration using the service
         final deliveryPartnerService = DeliveryPartnerService();
         await deliveryPartnerService.migrateExistingDeliveryPartnersToPhoneIndex();

        // Close loading dialog
        Navigator.of(context).pop();

        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Migration Completed'),
            content: const Text('Delivery partners have been successfully migrated to the new authentication system.'),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } catch (e) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Migration Failed'),
            content: Text('Error: ${e.toString()}'),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}
