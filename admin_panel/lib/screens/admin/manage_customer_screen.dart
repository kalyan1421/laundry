import 'package:admin_panel/screens/admin/edit_user_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../services/pdf_generation_service.dart';
import '../../services/delivery_partner_service.dart';
import '../../services/customer_deletion_service.dart';
import '../../utils/phone_formatter.dart';
import 'customer_detail_screen.dart';
import 'add_customer_screen.dart';
import 'place_order_for_customer_screen.dart';

class ManageClientsScreen extends StatefulWidget {
  final String? roleFilter;
  final String pageTitle;

  const ManageClientsScreen({
    super.key,
    this.roleFilter,
    required this.pageTitle,
  });

  @override
  State<ManageClientsScreen> createState() => _ManageClientsScreenState();
}

class _ManageClientsScreenState extends State<ManageClientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'newest'; // newest, oldest, name_asc, name_desc
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserModel> _filterUsers(List<UserModel> users) {
    List<UserModel> filteredUsers;

    // Filter by role first
    if (widget.roleFilter != null && widget.roleFilter!.isNotEmpty) {
      filteredUsers = users.where((user) => user.role == widget.roleFilter).toList();
    } else {
      filteredUsers = users;
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filteredUsers = filteredUsers.where((user) {
        final query = _searchQuery.toLowerCase();
        return user.name.toLowerCase().contains(query) ||
               user.email.toLowerCase().contains(query) ||
               user.phoneNumber.toLowerCase().contains(query);
      }).toList();
    }

    // Filter by date range
    if (_startDate != null || _endDate != null) {
      filteredUsers = filteredUsers.where((user) {
        if (user.createdAt == null) return false;
        
        final userDate = user.createdAt!.toDate();
        
        if (_startDate != null && userDate.isBefore(_startDate!)) {
          return false;
        }
        
        if (_endDate != null && userDate.isAfter(_endDate!.add(const Duration(days: 1)))) {
          return false;
        }
        
        return true;
      }).toList();
    }

    // Sort the filtered users
    switch (_sortBy) {
      case 'newest':
        filteredUsers.sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });
        break;
      case 'oldest':
        filteredUsers.sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return a.createdAt!.compareTo(b.createdAt!);
        });
        break;
      case 'name_asc':
        filteredUsers.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'name_desc':
        filteredUsers.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
    }

    return filteredUsers;
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _navigateToAddCustomer(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddCustomerScreen(),
      ),
    );

    if (result == true) {
      // Refresh the user list after adding a customer
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.refreshUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final deliveryPartnerService = DeliveryPartnerService(); // Add this line

    return Scaffold(
      floatingActionButton: widget.roleFilter == 'customer'
          ? FloatingActionButton.extended(
              onPressed: () => _navigateToAddCustomer(context),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Add Customer'),
            )
          : null,
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.grey[100],
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, email, or phone...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : IconButton(
                        icon: Icon(Icons.refresh, color: Colors.blue[700]),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                          // Trigger refresh by notifying the provider
                          Provider.of<UserProvider>(context, listen: false).refreshUsers();
                        },
                        tooltip: 'Refresh Customers',
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Filter Controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            color: Colors.grey[50],
            child: Column(
              children: [
                // Sort and Date Filter Row
                Row(
                  children: [
                    // Sort Dropdown
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _sortBy,
                        decoration: const InputDecoration(
                          labelText: 'Sort By',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'newest', child: Text('Newest First')),
                          DropdownMenuItem(value: 'oldest', child: Text('Oldest First')),
                          DropdownMenuItem(value: 'name_asc', child: Text('Name A-Z')),
                          DropdownMenuItem(value: 'name_desc', child: Text('Name Z-A')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _sortBy = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Date Range Buttons
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _selectDateRange(),
                              icon: const Icon(Icons.date_range, size: 16),
                              label: Text(
                                _startDate != null || _endDate != null 
                                  ? 'Date Filter On' 
                                  : 'Date Filter',
                                style: const TextStyle(fontSize: 12),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                foregroundColor: _startDate != null || _endDate != null 
                                  ? Colors.blue 
                                  : Colors.grey[700],
                              ),
                            ),
                          ),
                          if (_startDate != null || _endDate != null) ...[
                            const SizedBox(width: 4),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _startDate = null;
                                  _endDate = null;
                                });
                              },
                              icon: const Icon(Icons.clear, size: 16),
                              tooltip: 'Clear Date Filter',
                              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Active filters display
                if (_startDate != null || _endDate != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Text(
                      'Showing users from ${_startDate != null ? "${_startDate!.day}/${_startDate!.month}/${_startDate!.year}" : "beginning"} to ${_endDate != null ? "${_endDate!.day}/${_endDate!.month}/${_endDate!.year}" : "today"}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Users List
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: userProvider.allUsersStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  print('Error fetching users: ${snapshot.error}');
                  return Center(child: Text('Error fetching users: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No users found.'));
                }

                List<UserModel> users = snapshot.data!;
                List<UserModel> filteredUsers = _filterUsers(users);

                if (filteredUsers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty 
                              ? 'No users found matching "$_searchQuery"'
                              : 'No users found for role: ${widget.roleFilter ?? "All Users"}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    bool isWideScreen = constraints.maxWidth > 700;
                    return ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        return SimplifiedUserCard(user: user);
                      },
                    );
                  }
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SimplifiedUserCard extends StatelessWidget {
  final UserModel user;

  const SimplifiedUserCard({super.key, required this.user});

  void _showUserDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDetailScreen(customer: user),
      ),
    );
  }

  void _showDeleteCustomerDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => CustomerDeletionDialog(
        user: user,
        onDeleted: () {
          // Refresh the user list after deletion
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          userProvider.refreshUsers();
        },
      ),
    );
  }

  void _navigateToEdit(BuildContext context, UserModel user) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditUserScreen(user: user),
      ),
    );
    if (result == true) {
      // Refresh the user list after editing
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.refreshUsers();
    }
  }

  void _navigateToPlaceOrder(BuildContext context, UserModel user) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaceOrderForCustomerScreen(customer: user),
      ),
    );
    if (result == true) {
      // Order was placed successfully
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order placed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  static void navigateToPlaceOrder(BuildContext context, UserModel user) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaceOrderForCustomerScreen(customer: user),
      ),
    );
    if (result == true) {
      // Order was placed successfully
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order placed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    
    
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () => _showUserDetails(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: _getRoleColor(user.role),
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name.isNotEmpty ? user.name : 'Unknown Name',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Client ID: ${PhoneFormatter.getClientId(user.phoneNumber)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (user.email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getRoleColor(user.role).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  user.role.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _getRoleColor(user.role),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              
              // Action buttons for customers
              if (user.role.toLowerCase() == 'customer') ...[
                // Quick delete button
                GestureDetector(
                  onTap: () {
                    // Prevent the card tap from being triggered
                  },
                  child: IconButton(
                    onPressed: () => _showDeleteCustomerDialog(context, user),
                    icon: Icon(
                      Icons.delete_forever,
                      size: 18,
                      color: Colors.red[600],
                    ),
                    tooltip: 'Delete Customer Forever',
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                  ),
                ),
                
                // More actions menu
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  tooltip: 'More Actions',
                  padding: const EdgeInsets.all(4),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _navigateToEdit(context, user);
                        break;
                      case 'details':
                        _showUserDetails(context);
                        break;
                      case 'place_order':
                        _navigateToPlaceOrder(context, user);
                        break;
                      case 'delete':
                        _showDeleteCustomerDialog(context, user);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Edit Customer'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'details',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, size: 16, color: Colors.green),
                          SizedBox(width: 8),
                          Text('View Details'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'place_order',
                      child: Row(
                        children: [
                          Icon(Icons.shopping_cart_outlined, size: 16, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Place Order'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_forever, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete Forever'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
              ] else ...[
                // For non-customers, just show the arrow
                const SizedBox(width: 8),
              ],
              
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'supervisor':
        return Colors.purple;
      case 'delivery':
        return Colors.blue;
      case 'customer':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class UserDetailsDialog extends StatelessWidget {
  final UserModel user;

  const UserDetailsDialog({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(24),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: _getRoleColor(user.role),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getRoleColor(user.role).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user.role.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getRoleColor(user.role),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            
            // User Details
            _buildDetailRow(Icons.badge, 'Client ID', PhoneFormatter.getClientId(user.phoneNumber)),
            _buildDetailRow(Icons.email, 'Email', user.email),
            if (user.createdAt != null)
              _buildDetailRow(
                Icons.calendar_today,
                'Joined',
                user.createdAt!.toDate().toLocal().toString().substring(0, 10),
              ),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            
            // Order Statistics
            Row(
              children: [
                Expanded(
                  child: FutureBuilder<int>(
                    future: userProvider.getTotalOrdersForUser(user.uid),
                    builder: (context, snapshot) {
                      return _buildStatCard(
                        'Total Orders',
                        snapshot.hasData ? '${snapshot.data}' : '...',
                        Colors.blue,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FutureBuilder<int>(
                    future: userProvider.getActiveOrdersForUser(user.uid),
                    builder: (context, snapshot) {
                      return _buildStatCard(
                        'Active Orders',
                        snapshot.hasData ? '${snapshot.data}' : '...',
                        Colors.orange,
                      );
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
                            // Action Buttons
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              final result = await Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => EditUserScreen(user: user),
                              ));
                              if (result == true) {
                                // Refresh the user list
                                final userProvider = Provider.of<UserProvider>(context, listen: false);
                                userProvider.refreshUsers();
                              }
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showQrDialog(context, user),
                            icon: const Icon(Icons.qr_code),
                            label: const Text('QR Code'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CustomerDetailScreen(customer: user),
                            ),
                          );
                        },
                        icon: const Icon(Icons.person),
                        label: const Text('View Details'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _downloadCustomerPdf(context, user),
                        icon: const Icon(Icons.download),
                        label: const Text('Download PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          SimplifiedUserCard.navigateToPlaceOrder(context, user);
                        },
                        icon: const Icon(Icons.shopping_cart_rounded),
                        label: const Text('Place Order'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showDeleteCustomerDialog(context, user);
                        },
                        icon: const Icon(Icons.delete_forever),
                        label: const Text('Delete Customer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
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
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showQrDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('QR Code for ${user.name}'),
          content: SizedBox(
            width: 200,
            height: 200,
            child: Center(
              child: QrImageView(
                data: 'Customer ID: ${user.uid}\nName: ${user.name}\nClient ID: ${PhoneFormatter.getClientId(user.phoneNumber)}\nPhone: ${user.phoneNumber}\nEmail: ${user.email}',
                version: QrVersions.auto,
                size: 180.0,
                gapless: false,
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _downloadCustomerPdf(BuildContext context, UserModel user) async {
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
              Text('Generating PDF...'),
            ],
          ),
        ),
      );

      // Generate and download PDF
      await PdfGenerationService.downloadCustomerPdf(user);

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF generated for ${user.name}'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Close',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.of(context).pop();
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Close',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  // Show comprehensive customer deletion dialog
  void _showDeleteCustomerDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => CustomerDeletionDialog(
        user: user,
        onDeleted: () {
          // Refresh the user list after deletion
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          userProvider.refreshUsers();
        },
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'supervisor':
        return Colors.purple;
      case 'delivery':
        return Colors.blue;
      case 'customer':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

// Comprehensive Customer Deletion Dialog
class CustomerDeletionDialog extends StatefulWidget {
  final UserModel user;
  final VoidCallback onDeleted;

  const CustomerDeletionDialog({
    super.key,
    required this.user,
    required this.onDeleted,
  });

  @override
  State<CustomerDeletionDialog> createState() => _CustomerDeletionDialogState();
}

class _CustomerDeletionDialogState extends State<CustomerDeletionDialog> {
  final CustomerDeletionService _deletionService = CustomerDeletionService();
  CustomerDeletionPreview? _preview;
  bool _isLoadingPreview = true;
  bool _isDeleting = false;
  
  @override
  void initState() {
    super.initState();
    _loadDeletionPreview();
  }

  Future<void> _loadDeletionPreview() async {
    try {
      final preview = await _deletionService.getCustomerDeletionPreview(widget.user.uid);
      setState(() {
        _preview = preview;
        _isLoadingPreview = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPreview = false;
      });
    }
  }

  void _showFinalConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red[700]),
            const SizedBox(width: 8),
            const Text('Confirm Deletion'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this customer?',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Customer: ${widget.user.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Phone: ${widget.user.phoneNumber}'),
                  Text('Email: ${widget.user.email}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                color: Colors.red[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close confirmation dialog
              _executeCustomerDeletion();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeCustomerDeletion() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      final result = await _deletionService.deleteCustomerCompletely(
        customerId: widget.user.uid,
        customerName: widget.user.name,
        customerPhone: widget.user.phoneNumber,
      );

      if (mounted) {
        Navigator.pop(context);
        
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
          widget.onDeleted();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deletion failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.delete_forever, color: Colors.red[700]),
          const SizedBox(width: 8),
          const Text('Delete Customer Forever'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: _isLoadingPreview
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading deletion preview...'),
                ],
              )
            : _preview == null
                ? const Text('Error loading customer data.')
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Customer Info
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Customer: ${widget.user.name}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text('Phone: ${widget.user.phoneNumber}'),
                              Text('Email: ${widget.user.email}'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // What will be deleted
                        const Text(
                          'What will be deleted:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('✓ Customer account'),
                              Text('✓ ${_preview!.addressCount} addresses'),
                              if (_preview!.orderCount > 0)
                                Text('⚠️ ${_preview!.orderCount} orders (marked as deleted, not removed)'),
                            ],
                          ),
                        ),
                        
                        // Orders breakdown
                        if (_preview!.ordersByStatus.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Orders by status:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _preview!.ordersByStatus.entries
                                  .map((entry) => Text('• ${entry.key}: ${entry.value} orders'))
                                  .toList(),
                            ),
                          ),
                        ],
                        
                        // Warnings
                        if (_preview!.warnings.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Warnings:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _preview!.warnings
                                  .map((warning) => Text('⚠️ $warning'))
                                  .toList(),
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 24),
                        
                        // Final warning
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[300]!, width: 2),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning, color: Colors.red[700], size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'This action cannot be undone!',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red[700],
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'Customer account and all addresses will be permanently deleted.',
                                      style: TextStyle(
                                        color: Colors.red[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isDeleting ? null : _showFinalConfirmation,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[700],
            foregroundColor: Colors.white,
          ),
          child: _isDeleting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('DELETE CUSTOMER'),
        ),
      ],
    );
  }
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const InfoRow({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 14, color: Colors.grey[800]))),
        ],
      ),
    );
  }
} 