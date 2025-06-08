import 'package:customer_app/data/models/order_model.dart';
import 'package:customer_app/presentation/screens/orders/order_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:timelines_plus/timelines_plus.dart'; // Changed to timelines_plus

class TrackOrdersScreen extends StatefulWidget {
  const TrackOrdersScreen({Key? key}) : super(key: key);

  @override
  State<TrackOrdersScreen> createState() => _TrackOrdersScreenState();
}

class _TrackOrdersScreenState extends State<TrackOrdersScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  OrderModel? _lastOrder;
  bool _isLoading = true;
  String _error = '';

  // Define order stages for the tracker UI - these should match major statuses
  final List<String> _progressStages = [
    'Confirmed',
    'Picked Up',
    'Processing', // or In Progress
    'Ready',      // Assuming a 'Ready for Delivery' or similar status
    'Delivered'   // or Completed
  ];

  @override
  void initState() {
    super.initState();
    _fetchLastOrder();
  }

  Future<void> _fetchLastOrder() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        final snapshot = await _firestore
            .collection('orders')
            .where('userId', isEqualTo: currentUser.uid)
            .orderBy('orderTimestamp', descending: true)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          _lastOrder = OrderModel.fromFirestore(snapshot.docs.first);
        } else {
          _lastOrder = null;
        }
      } catch (e) {
        print('Error fetching last order: $e');
        _error = 'Failed to load order details. Please try again.';
      }
    } else {
      _error = 'Please log in to track your orders.';
    }
    setState(() {
      _isLoading = false;
    });
  }

  // Helper to get the current index in _progressStages based on order status
  int _getCurrentProgressIndex(String currentStatus) {
    String normalizedStatus = currentStatus.toLowerCase();
    if (normalizedStatus == 'confirmed') return 0;
    if (normalizedStatus == 'picked up' || normalizedStatus == 'pickup completed') return 1;
    if (normalizedStatus == 'processing' || normalizedStatus == 'in progress') return 2;
    if (normalizedStatus == 'ready' || normalizedStatus == 'ready for delivery') return 3;
    if (normalizedStatus == 'delivered' || normalizedStatus == 'completed') return 4;
    // If status is pending or something before confirmed, show as before confirmed (index -1 effectively)
    if (normalizedStatus == 'pending') return -1; 
    return 0; // Default or if unknown, show at confirmed or first stage
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(backgroundColor: Color(0xFFF5F7FA), body: Center(child: CircularProgressIndicator()));
    }
    if (_error.isNotEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(_error, style: const TextStyle(fontSize: 16, color: Colors.red), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _fetchLastOrder, child: const Text('Retry'))
            ]))));
    }
    if (_lastOrder == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.track_changes_outlined, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 20),
              const Text('No Orders to Track', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF0F3057))),
              const SizedBox(height: 8),
              Text('Once you place an order, its progress will appear here.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.grey[600])),
              const SizedBox(height: 30),
              ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003B73), padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                onPressed: () { Navigator.of(context).popUntil((route) => route.isFirst); },
                child: const Text('Place New Order', style: TextStyle(fontSize: 16, color: Colors.white)))]))));
    }

    // --- Main UI for displaying the last order ---
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light greyish background from image
      body: RefreshIndicator(
        onRefresh: _fetchLastOrder,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 80), // Padding for FAB if it overlaps
            child: Column(
              children: [
                _buildTopOrderBar(_lastOrder!),
                _buildProgressStepper(_lastOrder!),
                _buildStatusUpdatesSection(_lastOrder!),
                _buildOrderDetailsCard(_lastOrder!),
                _buildPickupDeliveryCard(_lastOrder!),
                _buildActionButtons(_lastOrder!),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'contact_support_fab',
        onPressed: () {
          // TODO: Implement contact support action
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact support tapped (not implemented)')));
        },
        backgroundColor: Colors.blueAccent, // Color from image
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTopOrderBar(OrderModel order) {
    return Container(
      color: Colors.white, // Assuming a white top bar background
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Order #${order.orderNumber}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F3057)),
          ),
          IconButton(
            icon: const Icon(Icons.headset_mic_outlined, color: Color(0xFF0F3057), size: 28),
            onPressed: () {
              // TODO: Implement contact support action
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact support tapped (not implemented)')));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStepper(OrderModel order) {
    int currentStep = _getCurrentProgressIndex(order.status);
    Color activeColor = const Color(0xFF28B5B5); // Teal color from image
    Color inactiveColor = Colors.grey[300]!;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Row(
        children: List.generate(_progressStages.length, (index) {
          bool isActive = index <= currentStep;
          bool isCurrent = index == currentStep;
          
          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (index > 0)
                      Expanded(child: Container(height: 2, color: isActive ? activeColor : inactiveColor)),
                    Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        color: isCurrent ? activeColor : (isActive ? activeColor.withOpacity(0.7) : Colors.white),
                        shape: BoxShape.circle,
                        border: Border.all(color: isActive ? activeColor : inactiveColor, width: 2),
                      ),
                      child: isCurrent 
                          ? const Padding(padding: EdgeInsets.all(4.0), child: CircleAvatar(backgroundColor: Colors.white, radius: 4)) 
                          : (isActive ? const Icon(Icons.check, color: Colors.white, size: 14) : null)
                    ),
                    if (index < _progressStages.length - 1)
                      Expanded(child: Container(height: 2, color: (index < currentStep) ? activeColor : inactiveColor)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _progressStages[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: isActive ? (isCurrent ? activeColor : Colors.black87) : Colors.grey[600],
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

 Widget _buildStatusUpdatesSection(OrderModel order) {
    if (order.statusHistory.isEmpty) {
      // Show current status if history is empty, or a placeholder
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Status Updates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F3057))),
                const SizedBox(height: 10),
                Text('Current Status: ${order.status}', style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 5),
                Text(DateFormat('MMM d, yyyy hh:mm a').format(order.orderTimestamp.toDate()), style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            )
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Status Updates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F3057))),
              const SizedBox(height: 15),
              FixedTimeline.tileBuilder(
                theme: TimelineThemeData(
                  nodePosition: 0.05, // Position of the dot from the left
                  color: const Color(0xFF28B5B5), // Teal color for dots and lines
                  indicatorTheme: const IndicatorThemeData(size: 10.0),
                  connectorTheme: const ConnectorThemeData(thickness: 2.0),
                ),
                builder: TimelineTileBuilder.connected(
                  connectionDirection: ConnectionDirection.before, // Line comes from top
                  itemCount: order.statusHistory.length,
                  contentsBuilder: (_, index) {
                    final historyItem = order.statusHistory[index];
                    final statusMessage = historyItem['status_message'] as String? ?? 'Status Updated';
                    final timestamp = historyItem['timestamp'] as Timestamp?;
                    return Padding(
                      padding: const EdgeInsets.only(left: 12.0, bottom: 16.0, top: 0, right: 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            statusMessage,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
                          ),
                          if (timestamp != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                DateFormat('MMM d, yyyy hh:mm a').format(timestamp.toDate()),
                                style: const TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                  indicatorBuilder: (_, index) {
                    // Optional: Customize indicator based on index or status
                    return DotIndicator(
                       border: Border.all(color: const Color(0xFF28B5B5), width: 2),
                    );
                  },
                  connectorBuilder: (_, index, type) {
                    return const SolidLineConnector();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderDetailsCard(OrderModel order) {
    bool _isExpanded = false; // Local state for expansion, ideally manage in State

    return StatefulBuilder( // To manage expansion state locally for this card
      builder: (BuildContext context, StateSetter setStateCard) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Order Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F3057))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.local_laundry_service_outlined, color: Colors.grey[600], size: 30),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order.serviceType, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                            Text('${order.items.length} items • ₹${order.totalAmount.toStringAsFixed(0)}', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.blueAccent),
                      label: const Text('View Items', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600)),
                      onPressed: () {
                        setStateCard(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                    ),
                  ),
                  if (_isExpanded)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: order.items.length,
                        itemBuilder: (context, index) {
                          final item = order.items[index];
                          return ListTile(
                            dense: true,
                            title: Text(item['name'] ?? 'N/A', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            trailing: Text('Qty: ${item['quantity'] ?? 0}'),
                            subtitle: Text('₹${(item['pricePerPiece'] ?? 0).toStringAsFixed(0)}/pc', style: const TextStyle(fontSize: 13)),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildPickupDeliveryCard(OrderModel order) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pickup & Delivery', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F3057))),
              const SizedBox(height: 12),
              _buildAddressRow(Icons.calendar_today_outlined, 'Pickup', DateFormat('EEE, MMM d • hh:mm a').format(order.pickupDate.toDate()), order.pickupTimeSlot, order.pickupAddress),
              const Divider(height: 20),
              _buildAddressRow(Icons.calendar_today_outlined, 'Delivery', DateFormat('EEE, MMM d • hh:mm a').format(order.deliveryDate.toDate()), order.deliveryTimeSlot, order.deliveryAddress),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressRow(IconData icon, String type, String date, String timeSlot, String address) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blueAccent, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$date • $timeSlot', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(address, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(OrderModel order) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.headset_mic_outlined, color: Colors.blueAccent),
            label: const Text('Contact Support', style: TextStyle(color: Colors.blueAccent, fontSize: 16)),
            onPressed: () {
              // TODO: Implement contact support action
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact support tapped (not implemented)')));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey[300]!)),
              elevation: 1,
            ),
          ),
          const SizedBox(height: 12),
          // Only show cancel if order is in a cancellable state (e.g., Pending, Confirmed)
          if (order.status.toLowerCase() == 'pending' || order.status.toLowerCase() == 'confirmed')
            ElevatedButton.icon(
              icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
              label: const Text('Cancel Order', style: TextStyle(color: Colors.redAccent, fontSize: 16)),
              onPressed: () {
                // TODO: Implement cancel order action with confirmation
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cancel order tapped (not implemented)')));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.red[200]!)),
                elevation: 1,
              ),
            ),
        ],
      ),
    );
  }
} 