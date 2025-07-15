import 'package:flutter/material.dart';
import '../../models/workshop_worker_model.dart';
import '../../services/workshop_worker_service.dart';
import 'add_workshop_worker_screen.dart';

class ManageWorkshopWorkersScreen extends StatefulWidget {
  const ManageWorkshopWorkersScreen({super.key});

  @override
  State<ManageWorkshopWorkersScreen> createState() => _ManageWorkshopWorkersScreenState();
}

class _ManageWorkshopWorkersScreenState extends State<ManageWorkshopWorkersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final WorkshopWorkerService _workerService = WorkshopWorkerService();
  String _searchQuery = '';
  String _statusFilter = 'all'; // all, active, inactive
  String _shiftFilter = 'all'; // all, morning, afternoon, night, full_day

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<WorkshopWorkerModel> _filterWorkers(List<WorkshopWorkerModel> workers) {
    List<WorkshopWorkerModel> filteredWorkers = workers;

    // Filter by status
    if (_statusFilter != 'all') {
      bool isActive = _statusFilter == 'active';
      filteredWorkers = filteredWorkers.where((worker) => worker.isActive == isActive).toList();
    }

    // Filter by shift
    if (_shiftFilter != 'all') {
      filteredWorkers = filteredWorkers.where((worker) => 
        worker.shift.toLowerCase() == _shiftFilter.replaceAll('_', ' ')).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filteredWorkers = filteredWorkers.where((worker) {
        final query = _searchQuery.toLowerCase();
        return worker.name.toLowerCase().contains(query) ||
               worker.email?.toLowerCase().contains(query) == true ||
               worker.phoneNumber.toLowerCase().contains(query) ||
               worker.employeeId.toLowerCase().contains(query) ||
               worker.workshopLocation.toLowerCase().contains(query);
      }).toList();
    }

    return filteredWorkers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Workshop Workers'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddWorkshopWorkerScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[100],
            child: Column(
              children: [
                // Search Field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name, email, phone, employee ID, or location...',
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
                        : null,
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
                const SizedBox(height: 12),
                
                // Filter Row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _statusFilter,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Status')),
                          DropdownMenuItem(value: 'active', child: Text('Active')),
                          DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _statusFilter = value ?? 'all';
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _shiftFilter,
                        decoration: InputDecoration(
                          labelText: 'Shift',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Shifts')),
                          DropdownMenuItem(value: 'morning', child: Text('Morning')),
                          DropdownMenuItem(value: 'afternoon', child: Text('Afternoon')),
                          DropdownMenuItem(value: 'night', child: Text('Night')),
                          DropdownMenuItem(value: 'full_day', child: Text('Full Day')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _shiftFilter = value ?? 'all';
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Workers List
          Expanded(
            child: StreamBuilder<List<WorkshopWorkerModel>>(
              stream: _workerService.getAllWorkshopWorkersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  print('Error fetching workshop workers: ${snapshot.error}');
                  return Center(child: Text('Error fetching workers: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.engineering,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No workshop workers found.',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const AddWorkshopWorkerScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add First Worker'),
                        ),
                      ],
                    ),
                  );
                }

                List<WorkshopWorkerModel> workers = snapshot.data!;
                List<WorkshopWorkerModel> filteredWorkers = _filterWorkers(workers);

                if (filteredWorkers.isEmpty) {
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
                              ? 'No workers found matching "$_searchQuery"'
                              : 'No workers found for selected filters',
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
                      padding: const EdgeInsets.all(16.0),
                      itemCount: filteredWorkers.length,
                      itemBuilder: (context, index) {
                        final worker = filteredWorkers[index];
                        return SimplifiedWorkerCard(
                          worker: worker,
                          onEdit: () => _editWorker(worker),
                          onDelete: () => _deleteWorker(worker),
                          onToggleStatus: () => _toggleWorkerStatus(worker),
                        );
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

  void _editWorker(WorkshopWorkerModel worker) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddWorkshopWorkerScreen(worker: worker),
      ),
    );
  }

  Future<void> _deleteWorker(WorkshopWorkerModel worker) async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete ${worker.name}?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _workerService.deleteWorkshopWorker(worker.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Workshop worker deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete worker: $e')),
          );
        }
      }
    }
  }

  Future<void> _toggleWorkerStatus(WorkshopWorkerModel worker) async {
    try {
      await _workerService.updateWorkshopWorkerStatus(worker.id, !worker.isActive);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Worker ${worker.isActive ? 'deactivated' : 'activated'} successfully'
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update worker status: $e')),
        );
      }
    }
  }
}

class WorkshopWorkerCard extends StatelessWidget {
  final WorkshopWorkerModel worker;
  final bool isWideScreen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  const WorkshopWorkerCard({
    super.key,
    required this.worker,
    required this.isWideScreen,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    Widget actionButtons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            worker.isActive ? Icons.pause_circle : Icons.play_circle,
            color: worker.isActive ? Colors.orange : Colors.green,
          ),
          onPressed: onToggleStatus,
          tooltip: worker.isActive ? 'Deactivate Worker' : 'Activate Worker',
        ),
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.blue),
          onPressed: onEdit,
          tooltip: 'Edit Worker',
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: onDelete,
          tooltip: 'Delete Worker',
        ),
      ],
    );

    Widget workerInfoSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                worker.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: worker.isActive ? Colors.green[100] : Colors.red[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                worker.isActive ? 'ACTIVE' : 'INACTIVE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: worker.isActive ? Colors.green[800] : Colors.red[800],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text('ID: ${worker.employeeId}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 8),
        InfoRow(icon: Icons.email_rounded, text: worker.emailText),
        InfoRow(icon: Icons.phone_rounded, text: worker.phoneNumber),
        InfoRow(icon: Icons.access_time_rounded, text: 'Shift: ${worker.shift}'),
        InfoRow(icon: Icons.location_on_rounded, text: 'Location: ${worker.workshopLocation}'),
        InfoRow(
          icon: worker.isOnline ? Icons.circle : Icons.circle_outlined,
          text: worker.isOnline ? 'Online' : 'Offline',
          textColor: worker.isOnline ? Colors.green : Colors.grey,
        ),
      ],
    );

    Widget skillsAndStatsSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Work Details:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        InfoRow(
          icon: Icons.location_on_rounded,
          text: 'Location: ${worker.workshopLocation.isNotEmpty ? worker.workshopLocation : 'Not specified'}',
        ),
        const SizedBox(height: 8),
        InfoRow(
          icon: Icons.attach_money_rounded,
          text: 'Rate: ₹${worker.hourlyRate.toStringAsFixed(0)}/hr',
        ),
        InfoRow(
          icon: Icons.star_rounded,
          text: 'Rating: ${worker.rating.toStringAsFixed(1)} ⭐',
        ),
        InfoRow(
          icon: Icons.assignment_turned_in_rounded,
          text: 'Completed: ${worker.completedOrders}/${worker.totalOrders}',
        ),
        if (worker.earnings > 0)
          InfoRow(
            icon: Icons.account_balance_wallet_rounded,
            text: 'Earnings: ₹${worker.earnings.toStringAsFixed(0)}',
          ),
        if (worker.createdAt != null)
          InfoRow(
            icon: Icons.calendar_today_rounded,
            text: 'Joined: ${worker.createdAt!.toDate().toLocal().toString().substring(0, 10)}',
          ),
      ],
    );

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isWideScreen 
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: workerInfoSection),
                const SizedBox(width: 16),
                Expanded(flex: 3, child: skillsAndStatsSection),
                const SizedBox(width: 16),
                actionButtons,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: workerInfoSection),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                skillsAndStatsSection,
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: actionButtons,
                ),
              ],
          )
      ),
    );
  }
}

class SimplifiedWorkerCard extends StatelessWidget {
  final WorkshopWorkerModel worker;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  const SimplifiedWorkerCard({
    super.key,
    required this.worker,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  });

  void _showWorkerDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => WorkerDetailsDialog(
        worker: worker,
        onEdit: onEdit,
        onDelete: onDelete,
        onToggleStatus: onToggleStatus,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => _showWorkerDetails(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: worker.isActive ? Colors.green : Colors.grey,
                child: Text(
                  worker.name.isNotEmpty ? worker.name[0].toUpperCase() : '?',
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
                      worker.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${worker.employeeId}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: worker.isActive 
                    ? Colors.green.withOpacity(0.1) 
                    : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  worker.isActive ? 'ACTIVE' : 'INACTIVE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: worker.isActive ? Colors.green : Colors.grey,
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
}

class WorkerDetailsDialog extends StatelessWidget {
  final WorkshopWorkerModel worker;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  const WorkerDetailsDialog({
    super.key,
    required this.worker,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: worker.isActive ? Colors.green : Colors.grey,
                      child: Text(
                        worker.name.isNotEmpty ? worker.name[0].toUpperCase() : '?',
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
                            worker.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: worker.isActive 
                                ? Colors.green.withOpacity(0.1) 
                                : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              worker.availabilityStatus,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: worker.isActive ? Colors.green : Colors.grey,
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
                
                // Worker Details
                _buildDetailRow(Icons.badge, 'Employee ID', worker.employeeId),
                _buildDetailRow(Icons.email, 'Email', worker.emailText),
                _buildDetailRow(Icons.phone, 'Phone', worker.formattedPhone),
                _buildDetailRow(Icons.access_time, 'Shift', worker.shiftText),
                _buildDetailRow(Icons.location_on, 'Location', worker.workshopLocation),
                if (worker.aadharNumber != null && worker.aadharNumber!.isNotEmpty)
                  _buildDetailRow(Icons.credit_card, 'Aadhar Number', worker.aadharNumber!),
                if (worker.aadharCardUrl != null)
                  _buildDetailRow(Icons.attachment, 'Aadhar Card', 'Uploaded'),
                _buildDetailRow(Icons.attach_money, 'Hourly Rate', '₹${worker.hourlyRate.toStringAsFixed(0)}'),
                _buildDetailRow(Icons.calendar_today, 'Joined', 
                  worker.createdAt.toDate().toLocal().toString().substring(0, 10)),
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                
                // Statistics
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Orders',
                        '${worker.totalOrders}',
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Completed',
                        '${worker.completedOrders}',
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Rating',
                        worker.rating.toStringAsFixed(1),
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onToggleStatus();
                        },
                        icon: Icon(
                          worker.isActive ? Icons.pause_circle : Icons.play_circle,
                          color: worker.isActive ? Colors.orange : Colors.green,
                        ),
                        label: Text(worker.isActive ? 'Deactivate' : 'Activate'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onEdit();
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
            width: 100,
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
      padding: const EdgeInsets.all(12),
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? textColor;
  
  const InfoRow({
    super.key,
    required this.icon,
    required this.text,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: textColor ?? Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 