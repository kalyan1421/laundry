import 'package:flutter/material.dart';
import '../../services/admin_token_service.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class AdminTokenDebugScreen extends StatefulWidget {
  const AdminTokenDebugScreen({super.key});

  @override
  State<AdminTokenDebugScreen> createState() => _AdminTokenDebugScreenState();
}

class _AdminTokenDebugScreenState extends State<AdminTokenDebugScreen> {
  final AdminTokenService _tokenService = AdminTokenService();
  List<Map<String, dynamic>> _adminTokenInfo = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTokenInfo();
  }

  Future<void> _loadTokenInfo() async {
    setState(() => _loading = true);
    try {
      final tokenInfo = await _tokenService.getAdminTokensWithInfo();
      setState(() {
        _adminTokenInfo = tokenInfo;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading token info: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Notification Tokens'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTokenInfo,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Info card
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Notification Token Status',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Admins need FCM tokens to receive notifications. '
                          'Tokens are automatically generated when admins log in to this app.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              await authProvider.refreshFCMToken();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Your notification token has been refreshed'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _loadTokenInfo();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to refresh token: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh My Token'),
                        ),
                      ],
                    ),
                  ),
                ),

                // Admin list
                Expanded(
                  child: _adminTokenInfo.isEmpty
                      ? const Center(
                          child: Text('No admin accounts found'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _adminTokenInfo.length,
                          itemBuilder: (context, index) {
                            final admin = _adminTokenInfo[index];
                            final hasToken = admin['hasToken'] as bool;
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: hasToken ? Colors.green : Colors.red,
                                  child: Icon(
                                    hasToken ? Icons.check : Icons.close,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  admin['name'] ?? 'Unknown Admin',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Phone: ${admin['phoneNumber']}'),
                                    Text('ID: ${admin['adminId']}'),
                                    Text(
                                      'Token: ${admin['fcmToken']}',
                                      style: TextStyle(
                                        color: hasToken ? Colors.green[700] : Colors.red[700],
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (admin['lastUpdated'] != null)
                                      Text(
                                        'Updated: ${_formatTimestamp(admin['lastUpdated'])}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: hasToken
                                    ? const Icon(Icons.notifications_active, color: Colors.green)
                                    : const Icon(Icons.notifications_off, color: Colors.red),
                              ),
                            );
                          },
                        ),
                ),

                // Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem(
                        'Total Admins',
                        _adminTokenInfo.length.toString(),
                        Colors.blue,
                      ),
                      _buildSummaryItem(
                        'With Tokens',
                        _adminTokenInfo.where((admin) => admin['hasToken'] as bool).length.toString(),
                        Colors.green,
                      ),
                      _buildSummaryItem(
                        'Missing Tokens',
                        _adminTokenInfo.where((admin) => !(admin['hasToken'] as bool)).length.toString(),
                        Colors.red,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      if (timestamp == null) return 'Never';
      DateTime dateTime;
      if (timestamp is DateTime) {
        dateTime = timestamp;
      } else {
        dateTime = timestamp.toDate();
      }
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }
} 