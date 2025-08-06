import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'admin_management_service.dart';
import 'add_admin_screen.dart';

class ManageAdminsScreen extends StatefulWidget {
  const ManageAdminsScreen({super.key});

  @override
  State<ManageAdminsScreen> createState() => _ManageAdminsScreenState();
}

class _ManageAdminsScreenState extends State<ManageAdminsScreen> {
  final AdminManagementService _adminService = AdminManagementService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AdminModel> _filterAdmins(List<AdminModel> admins) {
    if (_searchQuery.isEmpty) return admins;
    
    return admins.where((admin) {
      final query = _searchQuery.toLowerCase();
      return admin.name.toLowerCase().contains(query) ||
             admin.email.toLowerCase().contains(query) ||
             admin.phoneNumber.toLowerCase().contains(query);
    }).toList();
  }

  void _showAdminActions(AdminModel admin) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              admin.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                admin.isActive ? Icons.block : Icons.check_circle,
                color: admin.isActive ? Colors.red : Colors.green,
              ),
              title: Text(admin.isActive ? 'Deactivate Admin' : 'Activate Admin'),
              onTap: () async {
                Navigator.pop(context);
                await _toggleAdminStatus(admin);
              },
            ),
            if (admin.isActive)
              ListTile(
                leading: const Icon(Icons.security, color: Colors.blue),
                title: const Text('Manage Permissions'),
                onTap: () {
                  Navigator.pop(context);
                  _showPermissionsDialog(admin);
                },
              ),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.grey),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _showAdminDetails(admin);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleAdminStatus(AdminModel admin) async {
    try {
      await _adminService.toggleAdminStatus(admin.uid, !admin.isActive);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            admin.isActive 
              ? 'Admin deactivated successfully' 
              : 'Admin activated successfully'
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPermissionsDialog(AdminModel admin) {
    final availablePermissions = [
      'all',
      'order_management',
      'user_management',
      'item_management',
      'delivery_management',
      'workshop_management',
      'banner_management',
      'offer_management',
      'reports',
    ];

    List<String> selectedPermissions = List.from(admin.permissions);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Manage Permissions - ${admin.name}'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Select permissions for this admin:'),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availablePermissions.map((permission) {
                    bool isSelected = selectedPermissions.contains(permission);
                    return FilterChip(
                      label: Text(
                        permission.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontSize: 12,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (permission == 'all') {
                            if (selected) {
                              selectedPermissions = ['all'];
                            } else {
                              selectedPermissions.clear();
                            }
                          } else {
                            if (selected) {
                              selectedPermissions.remove('all');
                              selectedPermissions.add(permission);
                            } else {
                              selectedPermissions.remove(permission);
                            }
                            
                            if (selectedPermissions.isEmpty) {
                              selectedPermissions = ['all'];
                            }
                          }
                        });
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: Colors.blue,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _adminService.updateAdminPermissions(
                    admin.uid,
                    selectedPermissions,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Permissions updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating permissions: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdminDetails(AdminModel admin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(admin.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Email', admin.email),
            _buildDetailRow('Phone', admin.phoneNumber),
            _buildDetailRow('Role', admin.role),
            _buildDetailRow('Status', admin.isActive ? 'Active' : 'Inactive'),
            _buildDetailRow('Created', 
              DateFormat('MMM dd, yyyy at hh:mm a').format(admin.createdAt.toDate())),
            _buildDetailRow('Last Updated', 
              DateFormat('MMM dd, yyyy at hh:mm a').format(admin.updatedAt.toDate())),
            if (admin.createdBy != null)
              _buildDetailRow('Created By', admin.createdBy!),
            const SizedBox(height: 8),
            const Text('Permissions:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: admin.permissions.map((permission) => Chip(
                label: Text(
                  permission.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(fontSize: 10),
                ),
                backgroundColor: Colors.blue[100],
              )).toList(),
            ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Administrators'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddAdminScreen(),
            ),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search admins by name, email, or phone...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Admin List
          Expanded(
            child: StreamBuilder<List<AdminModel>>(
              stream: _adminService.getAdmins(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 64),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final admins = snapshot.data ?? [];
                final filteredAdmins = _filterAdmins(admins);

                if (filteredAdmins.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person_off, color: Colors.grey, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No administrators found'
                              : 'No administrators match your search',
                          style: const TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        if (_searchQuery.isEmpty) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const AddAdminScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.person_add),
                            label: const Text('Add First Admin'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredAdmins.length,
                  itemBuilder: (context, index) {
                    final admin = filteredAdmins[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: admin.isActive ? Colors.blue : Colors.grey,
                          child: Text(
                            admin.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          admin.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(admin.email),
                            Text(admin.phoneNumber),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: admin.isActive ? Colors.green : Colors.red,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    admin.isActive ? 'Active' : 'Inactive',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Created: ${DateFormat('MMM dd, yyyy').format(admin.createdAt.toDate())}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () => _showAdminActions(admin),
                        ),
                        onTap: () => _showAdminDetails(admin),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}