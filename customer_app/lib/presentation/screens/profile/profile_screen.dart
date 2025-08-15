// screens/profile/profile_screen.dart
import 'package:customer_app/core/routes/app_routes.dart';
import 'package:customer_app/core/utils/address_formatter.dart';
import 'package:customer_app/data/models/user_model.dart';
import 'package:customer_app/presentation/providers/auth_provider.dart';
import 'package:customer_app/presentation/widgets/theme_selector_widget.dart';
import 'package:customer_app/services/qr_code_service.dart';
import 'package:customer_app/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../orders/order_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  int _orderCount = 0;
  bool _isLoadingOrders = true;

  // QR Code state variables
  String? _qrCodeUrl;
  bool _isLoadingQRCode = false;
  bool _hasCheckedQRCode = false;

  @override
  void initState() {
    super.initState();
    _fetchOrderCount();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!_hasCheckedQRCode && authProvider.userModel != null) {
      _checkAndLoadQRCode(authProvider.userModel!);
    }
  }

  Future<void> _checkAndLoadQRCode(UserModel user) async {
    if (_hasCheckedQRCode) return;

    setState(() {
      _hasCheckedQRCode = true;
      _isLoadingQRCode = true;
    });

    try {
      // Auto-generate/ensure QR code exists
      String? qrUrl = await QRCodeService.ensureUserQRCodeExists(
        user.uid,
        user.name.isNotEmpty ? user.name : user.displayName,
        user.phoneNumber,
      );

      setState(() {
        _qrCodeUrl = qrUrl;
        _isLoadingQRCode = false;
      });
    } catch (e) {
      print('Error loading QR code: $e');
      setState(() {
        _isLoadingQRCode = false;
      });
    }
  }

  Future<void> _loadQRCode(UserModel user) async {
    if (user.name.isEmpty || user.phoneNumber.isEmpty) {
      return; // Don't load QR if profile is incomplete
    }

    setState(() {
      _isLoadingQRCode = true;
    });

    try {
      // Auto-generate/ensure QR code exists
      String? qrUrl = await QRCodeService.ensureUserQRCodeExists(
        user.uid,
        user.name.isNotEmpty ? user.name : user.displayName,
        user.phoneNumber,
      );

      if (qrUrl != null) {
        setState(() {
          _qrCodeUrl = qrUrl;
          _isLoadingQRCode = false;
        });
      } else {
        setState(() {
          _isLoadingQRCode = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingQRCode = false;
      });
      print('Error loading QR code: $e');
    }
  }

  Future<void> _fetchOrderCount() async {
    try {
      firebase_auth.User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Try both customerId and userId fields to ensure compatibility
        QuerySnapshot customerIdQuery = await _firestore
            .collection('orders')
            .where('customerId', isEqualTo: currentUser.uid)
            .get();

        if (customerIdQuery.docs.isNotEmpty) {
          setState(() {
            _orderCount = customerIdQuery.docs.length;
            _isLoadingOrders = false;
          });
        } else {
          // Fallback to userId if customerId returns no results
          QuerySnapshot userIdQuery = await _firestore
              .collection('orders')
              .where('userId', isEqualTo: currentUser.uid)
              .get();

          setState(() {
            _orderCount = userIdQuery.docs.length;
            _isLoadingOrders = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching order count: $e');
      setState(() {
        _orderCount = 0;
        _isLoadingOrders = false;
      });
    }
  }

  Future<String> _getFormattedAddress(Address address) async {
    try {
      // Get the address document from Firestore to get all fields including doorNumber and floorNumber
      DocumentSnapshot doc = await _firestore
          .collection('customer')
          .doc(_auth.currentUser?.uid)
          .collection('addresses')
          .doc(address.id)
          .get();

      if (doc.exists) {
        Map<String, dynamic> addressData = doc.data() as Map<String, dynamic>;
        return AddressFormatter.formatAddressLayout(addressData);
      } else {
        // Fallback to basic address display
        return address.fullAddress;
      }
    } catch (e) {
      print('Error formatting address: $e');
      return address.fullAddress;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final UserModel? user = authProvider.userModel;

    // Debug: Print address information
    if (user != null) {
      print('🏠 Profile Screen - User addresses: ${user.addresses.length}');
      for (int i = 0; i < user.addresses.length; i++) {
        final addr = user.addresses[i];
        print(
            '🏠 Address $i: ${addr.type} (Primary: ${addr.isPrimary}) - ${addr.addressLine1}, ${addr.city}');
      }
      print(
          '🏠 Primary address: ${user.primaryAddress?.addressLine1 ?? 'None'}');
    }

    // The AppBar title ('My Profile') is typically handled by MainWrapper.
    // The design shows 'Profile' and an edit icon. We'll add the edit icon here
    // if MainWrapper doesn't provide a direct way to customize actions per screen.
    // For now, assuming MainWrapper handles the title, and we add an edit action.

    if (user == null) {
      // If user is null and we're not authenticated, navigate to login
      if (authProvider.authStatus == AuthStatus.unauthenticated ||
          authProvider.authStatus == AuthStatus.failed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.login,
              (route) => false,
            );
          }
        });
      }

      // Show loading only if we're still authenticating
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
      backgroundColor: context.backgroundColor,
      // Theme-aware background
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
            // _buildQRCodeSection(context, user),
            // Theme Selector Section
            const ThemeSelectorWidget(),
            // _buildDefaultAddressSection(context, user.primaryAddress),
            _buildMenuSection(
              context,
              'Account',
              [
                _buildMenuItem(
                  context,
                  Icons.home_outlined,
                  'Saved Addresses',
                  () async {
                    await Navigator.pushNamed(
                        context, AppRoutes.manageAddresses);
                    // Refresh user data when returning from address management
                    if (mounted) {
                      Provider.of<AuthProvider>(context, listen: false)
                          .refreshUserData();
                    }
                  },
                ),
                // _buildMenuItem(
                //   context,
                //   Icons.payment_outlined,
                //   'Payment Methods',
                //   () => Navigator.pushNamed(context, AppRoutes.paymentMethods),
                // ),
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
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OrderHistoryScreen(),
                    ),
                  ),
                ),
                // _buildMenuItem(
                //   context,
                //   Icons.favorite_border_outlined,
                //   'Saved Items',
                //   () => Navigator.pushNamed(context, AppRoutes.savedItems),
                // ),
                _buildMenuItem(
                  context,
                  Icons.card_giftcard_outlined, // Or Icons.share_outlined
                  'Refer & Earn',
                  () {
                    /* TODO: Navigate to Refer & Earn Screen */
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Refer & Earn: TBD')));
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
                  () => Navigator.pushNamed(context, AppRoutes.helpSupport),
                ),
                _buildMenuItem(
                  context,
                  Icons.shield_outlined, // Or Icons.privacy_tip_outlined
                  'Privacy & Terms',
                  () {
                    /* TODO: Navigate to Privacy & Terms Screen */
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Privacy & Terms: TBD')));
                  },
                ),
                // _buildMenuItem(
                //   context,
                //   Icons.settings_outlined,
                //   'App Settings',
                //   () => Navigator.pushNamed(context, AppRoutes.appSettings),
                // ),
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
    Widget profileImageWidget;
    if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty) {
      profileImageWidget = CachedNetworkImage(
        imageUrl: user.profileImageUrl!,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: 40,
          backgroundImage: imageProvider,
        ),
        placeholder: (context, url) =>
            const CircleAvatar(radius: 40, child: CircularProgressIndicator()),
        errorWidget: (context, url, error) => CircleAvatar(
            radius: 40,
            backgroundColor: context.backgroundColor,
            child: Icon(Icons.person, size: 40, color: Colors.grey[800])),
      );
    } else {
      profileImageWidget = CircleAvatar(
          radius: 40,
          backgroundColor: Colors.grey[200],
          child: Icon(Icons.person, size: 40, color: Colors.grey[800]));
    }

    return Container(
      color: context.backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          // Edit button at the top
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profile Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.onBackgroundColor,
                ),
              ),
              Spacer(),
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.editProfile);
                },
                icon: Icon(Icons.edit, color: Colors.blue[600]),
                tooltip: 'Edit Profile',
              ),
              IconButton(
                onPressed: () => _showQRCodeDialog(context),
                icon: Icon(Icons.qr_code, color: Colors.blue[600]),
                tooltip: 'Open Qr',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              profileImageWidget,
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name.isNotEmpty ? user.name : user.displayName,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (user.phoneNumber.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.phone_outlined,
                              size: 16, color: Colors.grey[700]),
                          const SizedBox(width: 6),
                          Text(user.formattedPhoneNumber,
                              style: TextStyle(
                                  fontSize: 15, color: Colors.grey[700])),
                        ],
                      ),
                    const SizedBox(height: 4),
                    if (user.email.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.email_outlined,
                              size: 16, color: Colors.grey[700]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(user.email,
                                style: TextStyle(
                                    fontSize: 15, color: Colors.grey[700])),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Member since ${_formatDate(user.createdAt)}',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (user.clientId != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: context.infoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code, size: 16, color: context.infoColor),
                  const SizedBox(width: 6),
                  Text(
                    'Client ID: ${user.phoneNumber.replaceAll('+91', '')}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.infoColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Show address section or no address message
          if (user.addresses.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.yellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.yellow[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_off, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No Address Found',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Please add an address to complete your profile',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await Navigator.pushNamed(
                          context, AppRoutes.manageAddresses);
                      // Refresh user data when returning from address management
                      if (mounted) {
                        Provider.of<AuthProvider>(context, listen: false)
                            .refreshUserData();
                      }
                    },
                    child: const Text('Add Address'),
                  ),
                ],
              ),
            ),
          ] else if (user.primaryAddress != null) ...[
            // Address section with primary badge
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.green[600]),
                const SizedBox(width: 6),
                Text(
                  'Primary Address: ',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 12, color: Colors.green[700]),
                      const SizedBox(width: 4),
                      Text(
                        user.primaryAddress!.typeDisplayName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Structured address display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Address name/identifier
                  if (user.primaryAddress!.doorNumber.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.location_city_outlined,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          '${user.primaryAddress!.addressLine1.length > 50 ? user.primaryAddress!.addressLine1.substring(0, 50) + '...' : user.primaryAddress!.addressLine1}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: context.onSurfaceColor,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Floor number
                  if (user.primaryAddress!.addressLine2.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.layers_outlined,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          '${user.primaryAddress!.addressLine2}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: context.onSurfaceColor,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Landmark
                  if (user.primaryAddress!.landmark.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.place_outlined,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          '${user.primaryAddress!.landmark}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: context.onSurfaceColor,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // City, State, Pincode
                  if (user.primaryAddress!.city.isNotEmpty ||
                      user.primaryAddress!.state.isNotEmpty ||
                      user.primaryAddress!.pincode.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.home_outlined,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Full Address:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: context.onSurfaceColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user.primaryAddress!.fullAddress,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: context.onSurfaceColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],

                  // GPS coordinates if available
                  if (user.primaryAddress!.latitude != null &&
                      user.primaryAddress!.longitude != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.gps_fixed,
                            size: 14, color: Colors.green[600]),
                        const SizedBox(width: 6),
                        Text(
                          'GPS Location Available',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Recently';
    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else {
        return 'Recently';
      }

      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays < 30) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return '$months month${months > 1 ? 's' : ''} ago';
      } else {
        final years = (difference.inDays / 365).floor();
        return '$years year${years > 1 ? 's' : ''} ago';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  Widget _buildStatsBar(BuildContext context, UserModel user) {
    return Container(
      color: context.backgroundColor,
      padding:
          const EdgeInsets.only(top: 10, bottom: 16.0, left: 16.0, right: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            _isLoadingOrders ? '...' : _orderCount.toString(),
            'Orders',
            Icons.shopping_bag_outlined,
            () => Provider.of<BottomNavigationProvider>(context, listen: false)
                .selectedIndex = 1,
          ),
          const SizedBox(width: 10),
          _buildStatItem(
            user.addresses.length.toString(),
            'Addresses',
            Icons.location_on_outlined,
            () async {
              await Navigator.pushNamed(context, AppRoutes.manageAddresses);
              // Refresh user data when returning from address management
              if (mounted) {
                Provider.of<AuthProvider>(context, listen: false)
                    .refreshUserData();
              }
            },
          ),
          const SizedBox(width: 10),
          _buildStatItem(
            '₹0',
            'Wallet',
            Icons.account_balance_wallet_outlined,
            () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Wallet feature coming soon!')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String value, String label, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: context.backgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 20,
                    color: Theme.of(context).brightness == Brightness.light
                        ? context.primaryColor
                        : context.onSurfaceColor),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.light
                        ? context.primaryColor
                        : context.onSurfaceColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAddressSection(
      BuildContext context, Address? primaryAddress) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8.0),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal[50],
                  shape: BoxShape.circle,
                ),
                child:
                    Icon(Icons.location_on, color: Colors.teal[600], size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Default Address',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  await Navigator.pushNamed(context, AppRoutes.manageAddresses);
                  // Refresh user data when returning from address management
                  if (mounted) {
                    Provider.of<AuthProvider>(context, listen: false)
                        .refreshUserData();
                  }
                },
                child:
                    const Text('Manage', style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (primaryAddress != null) ...[
            // Address type badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                primaryAddress.typeDisplayName.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Address display with door number, floor number, and full address
            FutureBuilder<String>(
              future: _getFormattedAddress(primaryAddress),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(
                    snapshot.data!,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: Colors.black87,
                    ),
                  );
                } else {
                  return Text(
                    primaryAddress.fullAddress,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: Colors.black87,
                    ),
                  );
                }
              },
            ),

            // GPS coordinates if available
            if (primaryAddress.latitude != null &&
                primaryAddress.longitude != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.gps_fixed, size: 14, color: Colors.green[600]),
                  const SizedBox(width: 4),
                  Text(
                    'GPS Location Available',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ] else ...[
            // No address placeholder
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.location_off, size: 32, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  const Text(
                    'No default address set',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add an address for delivery and pickup',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Action button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await Navigator.pushNamed(context, AppRoutes.manageAddresses);
                // Refresh user data when returning from address management
                if (mounted) {
                  Provider.of<AuthProvider>(context, listen: false)
                      .refreshUserData();
                }
              },
              icon: Icon(
                primaryAddress != null
                    ? Icons.edit_location
                    : Icons.add_location,
                size: 18,
              ),
              label: Text(
                  primaryAddress != null ? 'Manage Addresses' : 'Add Address'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.teal[600],
                side: BorderSide(color: Colors.teal[300]!),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(
      BuildContext context, String title, List<Widget> items) {
    return Container(
      margin: const EdgeInsets.only(top: 8.0),
      color: context.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
                left: 16.0, top: 16.0, bottom: 8.0, right: 16.0),
            child: Text(
              title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600]),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) => items[index],
            separatorBuilder: (context, index) => const Divider(
                height: 1,
                indent: 56,
                endIndent: 16), // Indent matches icon + padding
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return Material(
      color: context.backgroundColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey[700], size: 24),
              const SizedBox(width: 16),
              Expanded(
                  child: Text(title,
                      style: TextStyle(
                          fontSize: 16, color: context.onBackgroundColor))),
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
        label: Text('Sign Out',
            style: TextStyle(
                color: context.errorColor,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
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
                    child: const Text('Sign Out',
                        style: TextStyle(color: Colors.red)),
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              );
            },
          );

          if (confirmSignOut == true) {
            await authProvider.signOut();
            // Navigate to login screen and clear all routes
            if (mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.login,
                (route) => false,
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildQRCodeSection(BuildContext context, UserModel user) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8.0),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.qr_code, color: Colors.blue[600], size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'My QR Code',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (_qrCodeUrl != null)
                TextButton(
                  onPressed: () => _showQRCodeDialog(context),
                  child: const Text('View Full',
                      style: TextStyle(color: Colors.blue)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingQRCode)
            Container(
              height: 120,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            )
          else if (_qrCodeUrl != null)
            Row(
              children: [
                // QR Code thumbnail
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: _qrCodeUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[100],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[100],
                        child: const Icon(Icons.error, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Personal QR Code',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Show this QR code to delivery partners and staff for quick identification',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Automatically generated for your account',
                        style: TextStyle(color: Colors.blue[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.qr_code_2, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  const Text(
                    'QR Code Not Available',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Please complete your profile to automatically generate your QR code',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showQRCodeDialog(BuildContext context) {
    if (_qrCodeUrl == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'My QR Code',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: _qrCodeUrl!,
                    width: 250,
                    height: 250,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Container(
                      width: 250,
                      height: 250,
                      color: Colors.grey[100],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 250,
                      height: 250,
                      color: Colors.grey[100],
                      child:
                          const Icon(Icons.error, size: 48, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Show this QR code to our delivery partners and staff for quick identification',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
