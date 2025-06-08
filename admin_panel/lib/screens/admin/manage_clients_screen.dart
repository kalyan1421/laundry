import 'package:admin_panel/screens/admin/edit_user_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';

class ManageClientsScreen extends StatelessWidget {
  final String? roleFilter;
  final String pageTitle;

  const ManageClientsScreen({
    super.key,
    this.roleFilter,
    required this.pageTitle,
  });

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      body: StreamBuilder<List<UserModel>>(
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
          List<UserModel> filteredUsers;

          if (roleFilter != null && roleFilter!.isNotEmpty) {
            filteredUsers = users.where((user) => user.role == roleFilter).toList();
          } else {
            filteredUsers = users;
          }

          if (filteredUsers.isEmpty) {
            return Center(child: Text('No users found for role: ${roleFilter ?? "All Users"}'));
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              bool isWideScreen = constraints.maxWidth > 700;
              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = filteredUsers[index];
                  return UserCard(user: user, isWideScreen: isWideScreen);
                },
              );
            }
          );
        },
      ),
    );
  }
}

class UserCard extends StatelessWidget {
  final UserModel user;
  final bool isWideScreen;

  const UserCard({super.key, required this.user, required this.isWideScreen});

  void _showQrDialog(BuildContext context, String userId, String userName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('QR Code for $userName'),
          content: SizedBox(
            width: 200,
            height: 200,
            child: Center(
              child: QrImageView(
                data: userId,
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

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    Widget actionButtons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.blue),
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => EditUserScreen(user: user),
            ));
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () async {
            final confirm = await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Confirm Deletion'),
                content: Text('Are you sure you want to delete ${user.name}?'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
                ],
              ),
            );
            if (confirm == true) {
              try {
                await userProvider.deleteUser(user.uid, user.role);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User deleted successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete user: $e')),
                );
              }
            }
          },
        ),
      ],
    );

    Widget userInfoSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(user.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('ID: ${user.uid}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 8),
        InfoRow(icon: Icons.email_rounded, text: user.email),
        InfoRow(icon: Icons.phone_rounded, text: user.phoneNumber),
        InfoRow(icon: Icons.person_pin_rounded, text: 'Role: ${user.role}'),
        if (user.createdAt != null)
            InfoRow(icon: Icons.calendar_today_rounded, text: 'Joined: ${user.createdAt!.toDate().toLocal().toString().substring(0,10)}')
        // Add location here if available
        // if (user.location != null) InfoRow(icon: Icons.location_on_rounded, text: user.location!),
      ],
    );

    Widget orderInfoSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FutureBuilder<int>(
          future: userProvider.getTotalOrdersForUser(user.uid),
          builder: (context, snapshot) {
            return InfoRow(icon: Icons.shopping_bag_rounded, text: 'Total Orders: ${snapshot.hasData ? snapshot.data : 'Loading...'}');
          },
        ),
        FutureBuilder<int>(
          future: userProvider.getActiveOrdersForUser(user.uid),
          builder: (context, snapshot) {
            return InfoRow(icon: Icons.local_shipping_rounded, text: 'Active Orders: ${snapshot.hasData ? snapshot.data : 'Loading...'}');
          },
        ),
      ],
    );

    Widget qrCodeButton = IconButton(
        icon: const Icon(Icons.qr_code_2_rounded, size: 30, color: Colors.blueGrey),
        tooltip: 'View QR Code',
        onPressed: () => _showQrDialog(context, user.uid, user.name),
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
                Expanded(flex: 2, child: userInfoSection),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: orderInfoSection),
                const SizedBox(width: 16),
                qrCodeButton,
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
                    Expanded(child: userInfoSection),
                    qrCodeButton,
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                orderInfoSection,
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