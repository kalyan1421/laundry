// screens/admin/admin_home.dart
import 'package:admin_panel/screens/admin/item_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'manage_items.dart';
import 'manage_banners.dart';
import 'manage_offers.dart';
import 'quick_orders.dart';
import 'all_orders.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const AdminDashboard(),
    const ItemListScreen(),
    const ManageBanners(),
    const ManageOffers(),
    const QuickOrders(),
    const AllOrders(),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Manage Items',
    'Manage Banners',
    'Special Offers',
    'Quick Orders',
    'All Orders',
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
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
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.admin_panel_settings, size: 35, color: Colors.blue),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    authProvider.userData?['name'] ?? 'Admin Panel',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(Icons.dashboard, 'Dashboard', 0),
            _buildDrawerItem(Icons.inventory, 'Manage Items', 1),
            _buildDrawerItem(Icons.image, 'Manage Banners', 2),
            _buildDrawerItem(Icons.local_offer, 'Special Offers', 3),
            _buildDrawerItem(Icons.notifications, 'Quick Orders', 4),
            _buildDrawerItem(Icons.list_alt, 'All Orders', 5),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: _selectedIndex == index,
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        Navigator.pop(context);
      },
    );
  }
}

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildDashboardCard(
            'Total Orders',
            '156',
            Icons.shopping_cart,
            Colors.blue,
          ),
          _buildDashboardCard(
            'Active Orders',
            '23',
            Icons.pending_actions,
            Colors.orange,
          ),
          _buildDashboardCard(
            'Quick Orders',
            '8',
            Icons.flash_on,
            Colors.green,
          ),
          _buildDashboardCard(
            'Revenue',
            '₹12,450',
            Icons.monetization_on,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
