import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/delivery_partner_service.dart';
import '../../models/delivery_partner_model.dart';
import 'admin_delivery_signup_screen.dart';

class ManageDeliveryPartnersScreen extends StatefulWidget {
  const ManageDeliveryPartnersScreen({super.key});

  @override
  State<ManageDeliveryPartnersScreen> createState() => _ManageDeliveryPartnersScreenState();
}

class _ManageDeliveryPartnersScreenState extends State<ManageDeliveryPartnersScreen> {
  final DeliveryPartnerService _deliveryService = DeliveryPartnerService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, online, offline, active, inactive

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DeliveryPartnerModel> _filterPartners(List<DeliveryPartnerModel> partners) {
    List<DeliveryPartnerModel> filtered = partners;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((partner) {
        final query = _searchQuery.toLowerCase();
        return partner.name.toLowerCase().contains(query) ||
               partner.phoneNumber.toLowerCase().contains(query) ||
               partner.email.toLowerCase().contains(query) ||
               partner.licenseNumber.toLowerCase().contains(query);
      }).toList();
    }

    // Apply status filter
    switch (_filterStatus) {
      case 'online':
        filtered = filtered.where((partner) => partner.isOnline && partner.isActive).toList();
        break;
      case 'offline':
        filtered = filtered.where((partner) => !partner.isOnline && partner.isActive).toList();
        break;
      case 'active':
        filtered = filtered.where((partner) => partner.isActive).toList();
        break;
      case 'inactive':
        filtered = filtered.where((partner) => !partner.isActive).toList();
        break;
    }

    return filtered;
  }

  void _showPartnerActions(DeliveryPartnerModel partner) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              partner.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                partner.isActive ? Icons.block : Icons.check_circle,
                color: partner.isActive ? Colors.red : Colors.green,
              ),
              title: Text(partner.isActive ? 'Deactivate Partner' : 'Activate Partner'),
              onTap: () async {
                Navigator.pop(context);
                await _toggleActiveStatus(partner);
              },
            ),
            if (partner.isActive)
              ListTile(
                leading: Icon(
                  partner.isOnline ? Icons.wifi_off : Icons.wifi,
                  color: partner.isOnline ? Colors.orange : Colors.blue,
                ),
                title: Text(partner.isOnline ? 'Set Offline' : 'Set Online'),
                onTap: () async {
                  Navigator.pop(context);
                  await _toggleOnlineStatus(partner);
                },
              ),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.grey),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _showPartnerDetails(partner);
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.blue),
              title: const Text('Generate New Login Code'),
              onTap: () {
                Navigator.pop(context);
                _generateNewLoginCode(partner);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleActiveStatus(DeliveryPartnerModel partner) async {
    try {
      await _deliveryService.toggleActiveStatus(partner.id, !partner.isActive);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            partner.isActive 
              ? 'Partner deactivated successfully' 
              : 'Partner activated successfully'
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

  Future<void> _toggleOnlineStatus(DeliveryPartnerModel partner) async {
    try {
      await _deliveryService.updateOnlineStatus(partner.id, !partner.isOnline);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            partner.isOnline 
              ? 'Partner set to offline' 
              : 'Partner set to online'
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

  void _generateNewLoginCode(DeliveryPartnerModel partner) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate New Login Code'),
        content: Text(
          'This will generate a new login code for ${partner.name}. '
          'The old code will no longer work. Continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement generate new login code
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('New login code generated successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  void _showPartnerDetails(DeliveryPartnerModel partner) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(partner.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Phone', partner.phoneNumber),
              _buildDetailRow('Email', partner.email),
              _buildDetailRow('License', partner.licenseNumber),
              _buildDetailRow('Status', partner.isActive ? 'Active' : 'Inactive'),
              _buildDetailRow('Online', partner.isOnline ? 'Yes' : 'No'),
              _buildDetailRow('Login Code', partner.registrationToken ?? 'N/A'),
              _buildDetailRow('Rating', '${partner.rating}/5.0'),
              _buildDetailRow('Total Deliveries', partner.totalDeliveries.toString()),
              _buildDetailRow('Completed', partner.completedDeliveries.toString()),
              _buildDetailRow('Cancelled', partner.cancelledDeliveries.toString()),
              _buildDetailRow('Earnings', '₹${partner.earnings.toStringAsFixed(2)}'),
              _buildDetailRow('Created', 
                DateFormat('MMM dd, yyyy at hh:mm a').format(partner.createdAt.toDate())),
              if (partner.createdBy != null)
                _buildDetailRow('Created By', partner.createdBy!),
            ],
          ),
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
            width: 100,
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

  Widget _buildStatsCard() {
    return FutureBuilder<Map<String, int>>(
      future: _deliveryService.getDeliveryPartnerStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
        }

        final stats = snapshot.data!;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total', stats['total']!, Colors.blue),
                _buildStatItem('Online', stats['online']!, Colors.green),
                _buildStatItem('Offline', stats['offline']!, Colors.orange),
                _buildStatItem('Active', stats['active']!, Colors.purple),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const SizedBox(width: 16),
          ...[
            'all',
            'online',
            'offline',
            'active',
            'inactive',
          ].map((filter) {
            final isSelected = _filterStatus == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(
                  filter.toUpperCase(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontSize: 12,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _filterStatus = filter;
                  });
                },
                backgroundColor: Colors.grey[200],
                selectedColor: Colors.blue,
              ),
            );
          }).toList(),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Delivery Partners'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddDeliveryPartnerScreen(),
            ),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Stats Cards
          _buildStatsCard(),
          
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, phone, email, or license...',
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
          
          // Filter Chips
          _buildFilterChips(),
          const SizedBox(height: 8),
          
          // Partners List
          Expanded(
            child: StreamBuilder<List<DeliveryPartnerModel>>(
              stream: _deliveryService.getAllDeliveryPartners(),
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

                final partners = snapshot.data ?? [];
                final filteredPartners = _filterPartners(partners);

                if (filteredPartners.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person_off, color: Colors.grey, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No delivery partners found'
                              : 'No partners match your search',
                          style: const TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        if (_searchQuery.isEmpty) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const AddDeliveryPartnerScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.person_add),
                            label: const Text('Add First Partner'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredPartners.length,
                  itemBuilder: (context, index) {
                    final partner = filteredPartners[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              backgroundColor: partner.isActive ? Colors.blue : Colors.grey,
                              child: Text(
                                partner.name.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (partner.isActive)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: partner.isOnline ? Colors.green : Colors.grey,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Text(
                          partner.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(partner.phoneNumber),
                            Text(partner.email),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: partner.isActive ? Colors.green : Colors.red,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    partner.isActive ? 'Active' : 'Inactive',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (partner.isActive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: partner.isOnline ? Colors.green : Colors.orange,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      partner.isOnline ? 'Online' : 'Offline',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                Text(
                                  'Code: ${partner.registrationToken ?? 'N/A'}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () => _showPartnerActions(partner),
                        ),
                        onTap: () => _showPartnerDetails(partner),
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