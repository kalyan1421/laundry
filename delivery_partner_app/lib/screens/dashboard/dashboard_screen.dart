// screens/dashboard/dashboard_screen.dart - Delivery Partner Dashboard
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/delivery_partner_model.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../tasks/task_detail_screen.dart';
import '../../widgets/custom_bottom_navigation.dart';
import '../../services/delivery_partner_service.dart';
import '../../services/location_service.dart';

class DashboardScreen extends StatefulWidget {
  final DeliveryPartnerModel deliveryPartner;

  const DashboardScreen({
    super.key,
    required this.deliveryPartner,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTabIndex = 0; // 0 for Pickups, 1 for Deliveries
  Map<String, dynamic> _stats = {};
  // PHASE 3: Updated for broadcast offers stream
  StreamSubscription<List<OrderModel>>? _offerSubscription;
  String? _activeOfferId;
  
  // Location tracking service & Online/Offline state
  final LocationService _locationService = LocationService();
  bool _isOnline = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    print('🚚 🎯 Dashboard: Initializing for delivery partner ID: ${widget.deliveryPartner.id}');
    print('🚚 🎯 Dashboard: Delivery partner name: ${widget.deliveryPartner.name}');
    _loadStats();
    _listenForOffers();
    _loadCurrentStatus();
    _setupFcmNotificationListener(); // ZOMATO-STYLE: Instant dialog trigger
  }

  /// ZOMATO-STYLE: Setup FCM listener for instant order offer dialogs
  /// This triggers the dialog IMMEDIATELY when notification arrives
  void _setupFcmNotificationListener() {
    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data['type'] == 'order_offer') {
        final orderId = message.data['orderId'];
        print('🔔 📢 FCM: Instant offer notification for Order: $orderId');
        
        // Show the offer dialog immediately
        if (mounted && _activeOfferId != orderId && orderId != null) {
          setState(() {
            _activeOfferId = orderId;
          });
          _showOrderOfferDialog(orderId);
        }
      }
    });

    // Handle when app is opened from background via notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data['type'] == 'order_offer') {
        final orderId = message.data['orderId'];
        print('🔔 📢 FCM: App opened from background for Order: $orderId');
        
        if (mounted && _activeOfferId != orderId && orderId != null) {
          setState(() {
            _activeOfferId = orderId;
          });
          _showOrderOfferDialog(orderId);
        }
      }
    });

    print('🔔 Dashboard: FCM notification listener setup complete');
  }

  /// Check Firebase for current status on load
  Future<void> _loadCurrentStatus() async {
    final doc = await FirebaseFirestore.instance
        .collection('delivery')
        .doc(widget.deliveryPartner.id)
        .get();
    
    if (doc.exists && mounted) {
      setState(() {
        _isOnline = doc.data()?['isOnline'] ?? false;
      });
      // If database says we are online, restart tracking automatically
      if (_isOnline) {
        _locationService.initialize().then((_) => 
            _locationService.goOnline(widget.deliveryPartner.id));
        print('🚚 📍 Dashboard: Restored online status from database');
      }
    }
  }

  /// Toggle Work Status (Online/Offline)
  Future<void> _toggleWorkStatus(bool value) async {
    setState(() => _isLoading = true);
    
    try {
      if (value) {
        // Turning ON
        bool hasPermission = await _locationService.initialize();
        if (hasPermission) {
          await _locationService.goOnline(widget.deliveryPartner.id);
          setState(() => _isOnline = true);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text("🟢 You are ONLINE. Expect orders!"),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.location_off, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(child: Text("Location permission required to work.")),
                  ],
                ),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
          }
        }
      } else {
        // Turning OFF
        await _locationService.goOffline(widget.deliveryPartner.id);
        setState(() => _isOnline = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.power_settings_new, color: Colors.white),
                  SizedBox(width: 8),
                  Text("You are now Offline."),
                ],
              ),
              backgroundColor: Colors.grey[700],
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      }
    } catch (e) {
      print('🚚 ❌ Dashboard: Error toggling work status: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadStats() async {
    final orderProvider = context.read<OrderProvider>();
    
    print('🚚 🆕 Dashboard: Loading stats with NEW simplified approach');
    
    final stats = await orderProvider.getDeliveryPartnerStats(widget.deliveryPartner.id);
    if (mounted) {
      setState(() {
        _stats = stats;
      });
    }
  }

  /// PHASE 3: Updated for BROADCAST system
  /// Listens to orders where this driver is in offeredDriverIds array
  /// Much more efficient than listening to individual driver document
  void _listenForOffers() {
    _offerSubscription?.cancel();
    
    final orderProvider = context.read<OrderProvider>();
    
    // Listen to the broadcast offers stream
    _offerSubscription = orderProvider
        .getNewOffersStream(widget.deliveryPartner.id)
        .listen((orders) {
      
      if (orders.isNotEmpty) {
        // Show the freshest/closest offer (first in list)
        final newestOffer = orders.first;
        
        // Prevent showing the same dialog repeatedly if already open
        if (_activeOfferId != newestOffer.id) {
          _activeOfferId = newestOffer.id;
          
          print('🚚 📢 Dashboard: New broadcast offer received: ${newestOffer.id}');
          
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showOrderOfferDialog(newestOffer.id!);
            });
          }
        }
      } else {
        // Close dialog if the order was taken by another driver
        if (_activeOfferId != null && mounted) {
          // Check if dialog is currently showing
          if (Navigator.of(context, rootNavigator: true).canPop()) {
            Navigator.of(context, rootNavigator: true).pop();
          }
          
          _activeOfferId = null;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Order was accepted by another driver.'),
                ],
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () async {
          print('🚚 🔄 Dashboard: Manual refresh triggered');
          
          // Refresh stats
          await _loadStats();
          
          // Force refresh all order data via OrderProvider
          final orderProvider = context.read<OrderProvider>();
          await orderProvider.forceRefreshAllData(widget.deliveryPartner.id);
          
          // Show feedback
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.refresh, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Dashboard refreshed'),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
          }
        },
        child: Column(
          children: [
            // Custom header without AppBar
            _buildModernHeader(),
            
            // Content section
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Online/Offline Toggle Button
                   // _buildOnlineToggle(),
                    
                    // Today's stats cards
                    _buildTodayStats(),
                    
                    // Today's schedule section
                    _buildTodaysSchedule(),
                    
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            
            // Enhanced Bottom navigation
            EnhancedBottomNavigation(
              currentIndex: 0,
              deliveryPartner: widget.deliveryPartner,
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1E3A8A),
      foregroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'Dashboard',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontFamily: 'SFProDisplay',
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            // TODO: Navigate to notifications
          },
        ),

        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'profile':
                _showProfileDialog();
                break;
              case 'debug':
                _runDiagnostics();
                break;
              case 'logout':
                _showLogoutDialog();
                break;
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person_outline),
                  SizedBox(width: 8),
                  Text('Profile'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'debug',
              child: Row(
                children: [
                  Icon(Icons.bug_report),
                  SizedBox(width: 8),
                  Text('Debug Orders'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout),
                  SizedBox(width: 8),
                  Text('Logout'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showOrderOfferDialog(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_shipping, color: Color(0xFF1E3A8A)),
            ),
            const SizedBox(width: 12),
            const Text('New Order Request'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Order #$orderId is available nearby.'),
            const SizedBox(height: 8),
            Text(
              'Would you like to accept this pickup?',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() {
                _activeOfferId = null;
              });
              try {
                await DeliveryPartnerService().respondToOrderOffer(
                  driverId: widget.deliveryPartner.id,
                  orderId: orderId,
                  accepted: false,
                  driverName: widget.deliveryPartner.name,
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to reject offer: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Reject'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() {
                _activeOfferId = null;
              });
              try {
                await DeliveryPartnerService().respondToOrderOffer(
                  driverId: widget.deliveryPartner.id,
                  orderId: orderId,
                  accepted: true,
                  driverName: widget.deliveryPartner.name,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Order accepted! Check your tasks.'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to accept offer: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Accept', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _offerSubscription?.cancel();
    // Dispose location service (don't auto-offline on dispose, let user control it)
    _locationService.dispose();
    super.dispose();
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF87CEEB), Color(0xFFB8E6FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Top row with logo and notifications
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.iron,
                    color: Color(0xFF1E3A8A),
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Cloud Ironing Factory',
                    style: TextStyle(
                      color: Color(0xFF1E3A8A),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SFProDisplay',
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  // Online Status Indicator
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isOnline 
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isOnline ? Colors.green : Colors.red,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _isOnline ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          _isOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                            color: _isOnline ? Colors.green[800] : Colors.red[800],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'SFProDisplay',
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.notifications_outlined,
                      color: Color(0xFF1E3A8A),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 30),
          
          // Profile section
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  Icons.person,
                  color: Color(0xFF1E3A8A),
                  size: 30,
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.deliveryPartner.name,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'SFProDisplay',
                      ),
                    ),
                   
                  //  _buildOnlineToggle(),
                    SizedBox(height: 4),
                    Text(
                      _isOnline 
                          ? '📍 Ready to receive orders'
                          : '⚠️ Go online to receive orders',
                      style: TextStyle(
                        color: _isOnline ? Colors.green[800] : Colors.orange[800],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'SFProDisplay',
                      ),
                    ),
                  ],
                ),
              ), _isLoading
              ? SizedBox(
                  width: 48,
                  height: 48,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: _isOnline ? Colors.green : Colors.red,
                    ),
                  ),
                )
              : Transform.scale(
                  scale: 1.2,
                  child: Switch(
                    value: _isOnline,
                    onChanged: _toggleWorkStatus,
                    activeColor: Colors.green,
                    activeTrackColor: Colors.green[200],
                    inactiveThumbColor: Colors.red,
                    inactiveTrackColor: Colors.red[200],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build the Online/Offline Toggle Widget
  Widget _buildOnlineToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isOnline ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isOnline ? Colors.green : Colors.red,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (_isOnline ? Colors.green : Colors.red).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _isOnline 
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _isOnline ? Icons.power_settings_new : Icons.power_off,
                  color: _isOnline ? Colors.green[700] : Colors.red[700],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isOnline ? "You're Online" : "You're Offline",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _isOnline ? Colors.green[800] : Colors.red[800],
                      fontFamily: 'SFProDisplay',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isOnline 
                        ? "Waiting for orders..." 
                        : "Go online to start receiving orders",
                    style: TextStyle(
                      fontSize: 12,
                      color: _isOnline ? Colors.green[600] : Colors.red[600],
                      fontFamily: 'SFProDisplay',
                    ),
                  ),
                ],
              ),
            ],
          ),
          _isLoading
              ? SizedBox(
                  width: 48,
                  height: 48,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: _isOnline ? Colors.green : Colors.red,
                    ),
                  ),
                )
              : Transform.scale(
                  scale: 1.2,
                  child: Switch(
                    value: _isOnline,
                    onChanged: _toggleWorkStatus,
                    activeColor: Colors.green,
                    activeTrackColor: Colors.green[200],
                    inactiveThumbColor: Colors.red,
                    inactiveTrackColor: Colors.red[200],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 20,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'SFProDisplay',
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontFamily: 'SFProDisplay',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTodayStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontFamily: 'SFProDisplay',
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color(0xFFE8F5E8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Color(0xFFC8E6C9), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Completed\nOrders',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'SFProDisplay',
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        _stats['todayCompleted']?.toString() ?? '20',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'SFProDisplay',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Color(0xFFFFE082), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pending\nOrders',
                        style: TextStyle(
                          color: Color(0xFFF57F17),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'SFProDisplay',
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        _stats['todayPending']?.toString() ?? '5',
                        style: TextStyle(
                          color: Color(0xFFF57F17),
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'SFProDisplay',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String period, String value, String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                period,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontFamily: 'SFProDisplay',
                ),
              ),
              Icon(
                icon,
                color: color,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'SFProDisplay',
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontFamily: 'SFProDisplay',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysSchedule() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Today \'s Schedule',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SFProDisplay',
                  color: Colors.black,
                ),
              ),
              Text(
                DateFormat('dd MMM yyyy').format(DateTime.now()),
                style: const TextStyle(
                  color: Color(0xFF9E9E9E),
                  fontSize: 14,
                  fontFamily: 'SFProDisplay',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Tab buttons for Pickups/Deliveries
          Container(
            decoration: BoxDecoration(
              color: Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTabIndex = 0;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTabIndex == 0 ? Color(0xFF1E3A8A) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Pickups',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _selectedTabIndex == 0 ? Colors.white : Color(0xFF9E9E9E),
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SFProDisplay',
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTabIndex = 1;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTabIndex == 1 ? Color(0xFF1E3A8A) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Deliveries',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _selectedTabIndex == 1 ? Colors.white : Color(0xFF9E9E9E),
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SFProDisplay',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Orders list
          StreamBuilder<List<OrderModel>>(
            stream: _selectedTabIndex == 0
                ? context.read<OrderProvider>().getPickupTasksStream(widget.deliveryPartner.id)
                : context.read<OrderProvider>().getDeliveryTasksStream(widget.deliveryPartner.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No tasks scheduled',
                      style: TextStyle(
                        color: Color(0xFF9E9E9E),
                        fontFamily: 'SFProDisplay',
                      ),
                    ),
                  ),
                );
              }
              
              return Column(
                children: snapshot.data!.take(3).map((order) {
                  return _buildModernTaskItem(order);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModernTaskItem(OrderModel order) {
    // Match the same statuses used in OrderProvider.getPickupTasksStream
    final pickupStatuses = ['assigned', 'confirmed', 'ready_for_pickup'];
    bool isPickup = pickupStatuses.contains(order.status);
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailScreen(order: order),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFE0E0E0), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isPickup ? Color(0xFFFFF3E0) : Color(0xFFE8F5E8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isPickup ? Icons.north_east : Icons.south_east,
                color: isPickup ? Color(0xFFFF8F00) : Color(0xFF4CAF50),
                size: 18,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.orderNumber ?? 'N/A',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      fontFamily: 'SFProDisplay',
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${isPickup ? 'Pickup' : 'Delivery'} Assigned',
                    style: const TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 14,
                      fontFamily: 'SFProDisplay',
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Color(0xFF9E9E9E),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton('Pickups', 0),
          ),
          Expanded(
            child: _buildTabButton('Deliveries', 1),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E3A8A) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.w600,
            fontFamily: 'SFProDisplay',
          ),
        ),
      ),
    );
  }

  Widget _buildTaskList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: StreamBuilder<List<OrderModel>>(
        stream: _selectedTabIndex == 0
            ? context.read<OrderProvider>().getPickupTasksStream(widget.deliveryPartner.id)
            : context.read<OrderProvider>().getDeliveryTasksStream(widget.deliveryPartner.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      _selectedTabIndex == 0 
                          ? Icons.arrow_upward 
                          : Icons.arrow_downward,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _selectedTabIndex == 0 
                          ? 'No pickup tasks available'
                          : 'No delivery tasks available',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                        fontFamily: 'SFProDisplay',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final order = snapshot.data![index];
              return _buildTaskItem(order);
            },
          );
        },
      ),
    );
  }

  Widget _buildTaskItem(OrderModel order) {
    // Match the same statuses used in OrderProvider.getPickupTasksStream
    final pickupStatuses = ['assigned', 'confirmed', 'ready_for_pickup'];
    bool isPickup = pickupStatuses.contains(order.status);
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isPickup ? Colors.orange[100] : Colors.green[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isPickup ? Icons.arrow_upward : Icons.arrow_downward,
          color: isPickup ? Colors.orange[700] : Colors.green[700],
        ),
      ),
      title: Text(
        order.orderNumber ?? 'N/A',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontFamily: 'SFProDisplay',
        ),
      ),
      subtitle: Text(
        '${isPickup ? 'Pickup' : 'Delivery'} • ${order.status.replaceAll('_', ' ').toUpperCase()}',
        style: const TextStyle(
          fontSize: 12,
          fontFamily: 'SFProDisplay',
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailScreen(order: order),
          ),
        );
      },
    );
  }

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${widget.deliveryPartner.name}'),
            Text('Phone: ${widget.deliveryPartner.phoneNumber}'),
            Text('Email: ${widget.deliveryPartner.email}'),
            Text('License: ${widget.deliveryPartner.licenseNumber}'),
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

  void _runDiagnostics() async {
    final orderProvider = context.read<OrderProvider>();
    
    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('🔍 Running diagnostics...'),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
    
    // Run full diagnostic and refresh
    await orderProvider.forceRefreshAllData(widget.deliveryPartner.id);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔍 Diagnostics completed. Check console logs for details.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().signOut();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }



} 
