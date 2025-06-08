// screens/profile/profile_screen.dart
import 'package:customer_app/core/routes/app_routes.dart';
import 'package:customer_app/data/models/user_model.dart';
import 'package:customer_app/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final UserModel? user = authProvider.userModel;

    // The AppBar title ('My Profile') is typically handled by MainWrapper.
    // The design shows 'Profile' and an edit icon. We'll add the edit icon here
    // if MainWrapper doesn't provide a direct way to customize actions per screen.
    // For now, assuming MainWrapper handles the title, and we add an edit action.

    if (user == null) {
      // This case should ideally be handled by MainWrapper redirecting to login if unauthenticated.
      // Or if authStatus is unknown but userModel is still loading.
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text("Loading profile..."),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100], // Light background color from design
      // AppBar is handled by MainWrapper, but we might want to add an edit action.
      // For demonstration, let's imagine adding it here if it were a standalone screen.
      // In MainWrapper, the AppBar actions are global. If a specific edit icon is needed
      // for ProfileScreen only, MainWrapper's AppBar would need dynamic actions based on selectedIndex.
      // Or, ProfileScreen itself could have a SliverAppBar if MainWrapper's AppBar is removed for this tab.
      // For now, the edit button will be placed conceptually.

      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildUserInfoHeader(context, user),
            SizedBox(height: 10),
            _buildStatsBar(context, user),
            _buildDefaultAddressSection(context, user.primaryAddress),
            _buildMenuSection(
              context,
              'Account',
              [
                _buildMenuItem(
                  context,
                  Icons.person_outline,
                  'Personal Information',
                  () => Navigator.pushNamed(context, AppRoutes.editProfile),
                ),
                _buildMenuItem(
                  context,
                  Icons.home_outlined,
                  'Saved Addresses',
                  () => Navigator.pushNamed(context, AppRoutes.manageAddresses),
                ),
                _buildMenuItem(
                  context,
                  Icons.payment_outlined,
                  'Payment Methods',
                  () { /* TODO: Navigate to Payment Methods Screen */ 
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment Methods: TBD')));
                  },
                ),
              ],
            ),
            _buildMenuSection(
              context,
              'Preferences',
              [
                _buildMenuItem(
                  context,
                  Icons.notifications_none_outlined,
                  'Notifications',
                  () { /* TODO: Navigate to Notifications Screen */ 
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notifications: TBD')));
                  },
                ),
                _buildMenuItem(
                  context,
                  Icons.calendar_today_outlined,
                  'Preferred Pickup Times',
                  () { /* TODO: Navigate to Preferred Pickup Times Screen */ 
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preferred Pickup Times: TBD')));
                  },
                ),
                _buildMenuItem(
                  context,
                  Icons.star_border_outlined,
                  'Ironing Preferences',
                  () { /* TODO: Navigate to Ironing Preferences Screen */ 
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ironing Preferences: TBD')));
                  },
                ),
              ],
            ),
            _buildMenuSection(
              context,
              'Activities',
              [
                _buildMenuItem(
                  context,
                  Icons.history_outlined,
                  'Order History',
                  // Navigate to OrdersScreen - it shows all orders by default
                  () => Provider.of<BottomNavigationProvider>(context, listen: false).selectedIndex = 1,

                ),
                _buildMenuItem(
                  context,
                  Icons.favorite_border_outlined,
                  'Saved Items',
                  () { /* TODO: Navigate to Saved Items Screen */ 
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved Items: TBD')));
                  },
                ),
                _buildMenuItem(
                  context,
                  Icons.card_giftcard_outlined, // Or Icons.share_outlined
                  'Refer & Earn',
                  () { /* TODO: Navigate to Refer & Earn Screen */ 
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Refer & Earn: TBD')));
                  },
                ),
              ],
            ),
            _buildMenuSection(
              context,
              'Support',
              [
                _buildMenuItem(
                  context,
                  Icons.help_outline_outlined,
                  'Help & Support',
                  () { /* TODO: Navigate to Help & Support Screen */ 
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Help & Support: TBD')));
                  },
                ),
                _buildMenuItem(
                  context,
                  Icons.shield_outlined, // Or Icons.privacy_tip_outlined
                  'Privacy & Terms',
                  () { /* TODO: Navigate to Privacy & Terms Screen */ 
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Privacy & Terms: TBD')));
                  },
                ),
                _buildMenuItem(
                  context,
                  Icons.settings_outlined,
                  'App Settings',
                  () { /* TODO: Navigate to App Settings Screen */ 
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('App Settings: TBD')));
                  },
                ),
              ],
            ),
            _buildSignOutButton(context, authProvider),
            const SizedBox(height: 20), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoHeader(BuildContext context, UserModel user) {
    // Edit icon for the header conceptually (actual AppBar action might be in MainWrapper)
    // For this self-contained example, adding it directly in the body for visual representation.
    // If MainWrapper's AppBar is used, this edit button might be redundant or placed differently.
    
    Widget profileImageWidget;
    if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty) {
      profileImageWidget = CachedNetworkImage(
        imageUrl: user.profileImageUrl!,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: 40,
          backgroundImage: imageProvider,
        ),
        placeholder: (context, url) => const CircleAvatar(radius: 40, child: CircularProgressIndicator()),
        errorWidget: (context, url, error) => CircleAvatar(
            radius: 40, 
            backgroundColor: Colors.grey[200], 
            child: Icon(Icons.person, size: 40, color: Colors.grey[800])
        ),
      );
    } else {
      profileImageWidget = CircleAvatar(
        radius: 40, 
        backgroundColor: Colors.grey[200], 
        child: Icon(Icons.person, size: 40, color: Colors.grey[800])
      );
    }
    
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children:[
        const SizedBox(height: 10),
          profileImageWidget,
          const SizedBox(width: 30),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
        children: [
         
          
          const SizedBox(height: 12),
          Text(
            user.name.isNotEmpty ? user.name : 'N/A',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          if (user.phoneNumber.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.phone_outlined, size: 16, color: Colors.grey[700]),
                const SizedBox(width: 6),
                Text(user.formattedPhoneNumber, style: TextStyle(fontSize: 15, color: Colors.grey[700])),
              ],
            ),
          const SizedBox(height: 4),
          if (user.email.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.email_outlined, size: 16, color: Colors.grey[700]),
                const SizedBox(width: 6),
                Text(user.email, style: TextStyle(fontSize: 15, color: Colors.grey[700])),
              ],
            ),
        ],
      ),
      ]),
      
    );
  }

  Widget _buildStatsBar(BuildContext context, UserModel user) {
    // Static data for now for Orders and Credits
    // Address count can be dynamic
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top:0, bottom: 16.0, left: 16.0, right: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(user.orderCount.toString(), 'Orders'), // Use user.orderCount
          _buildStatItem(user.addresses.length.toString(), 'Addresses'),
          _buildStatItem('₹0', 'Credits'), // Placeholder - TODO: Implement credits
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F3057))),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildDefaultAddressSection(BuildContext context, Address? primaryAddress) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, AppRoutes.manageAddresses),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal[50], // Light teal background for icon
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.location_on_outlined, color: Colors.teal[600]),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        primaryAddress != null ? (primaryAddress.type.isNotEmpty ? primaryAddress.type : 'Default Address') : 'No Default Address',
                        style: const TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        primaryAddress?.fullAddress ?? 'Tap to add or select an address',
                        style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, String title, List<Widget> items) {
    return Container(
      margin: const EdgeInsets.only(top: 8.0),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0, right: 16.0),
            child: Text(
              title,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[600]),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) => items[index],
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 56, endIndent: 16), // Indent matches icon + padding
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey[700], size: 24),
              const SizedBox(width: 16),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 16, color: Colors.black87))),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context, AuthProvider authProvider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextButton.icon(
        icon: const Icon(Icons.logout, color: Colors.redAccent),
        label: const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.w600)),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          minimumSize: const Size(double.infinity, 40), // Full width
          backgroundColor: Colors.red[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.red[100]!),
          ),
        ),
        onPressed: () async {
          // Show confirmation dialog
          bool? confirmSignOut = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Sign Out'),
                content: const Text('Are you sure you want to sign out?'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  TextButton(
                    child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              );
            },
          );

          if (confirmSignOut == true) {
            await authProvider.signOut();
            // MainWrapper should handle navigation to login screen based on AuthStatus change
            // No explicit navigation needed here if MainWrapper listens correctly.
          }
        },
      ),
    );
  }
}

// Dummy provider for BottomNavigation to make "Order History" navigation work conceptually
// In a real app, this would be your actual BottomNavigationBar state manager
class BottomNavigationProvider extends ChangeNotifier {
  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;
  set selectedIndex(int index) {
    _selectedIndex = index;
    print("BottomNavigationProvider: Selected index set to $index");
    // In a real app, this would trigger the UI to switch tabs.
    // For this example, it's just for the ProfileScreen's "Order History" to conceptually navigate.
    notifyListeners();
  }
}