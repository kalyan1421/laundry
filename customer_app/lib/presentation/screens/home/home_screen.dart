import 'package:carousel_slider/carousel_slider.dart';
import 'package:customer_app/data/models/item_model.dart';
import 'package:customer_app/data/models/offer_model.dart';
import 'package:customer_app/presentation/providers/auth_provider.dart';
import 'package:customer_app/presentation/providers/banner_provider.dart';
import 'package:customer_app/presentation/providers/home_provider.dart';
import 'package:customer_app/presentation/providers/item_provider.dart';
import 'package:customer_app/presentation/providers/special_offer_provider.dart';
import 'package:customer_app/presentation/screens/orders/schedule_pickup_delivery_screen.dart';
import 'package:customer_app/presentation/screens/home/allied_services_screen.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/data/models/order_model.dart'
    as customer_order_model;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Logger _logger = Logger();
  Map<String, int> itemQuantities = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialData();
    });
  }

  void _fetchInitialData() {
    _logger.d('Fetching initial data for HomeScreen');
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userModel != null) {
      Provider.of<HomeProvider>(context, listen: false)
          .fetchLastActiveOrder(authProvider.userModel!.uid);
    }
    Provider.of<BannerProvider>(context, listen: false).fetchBanners();
    Provider.of<SpecialOfferProvider>(context, listen: false)
        .fetchSpecialOffers();
    Provider.of<ItemProvider>(context, listen: false).loadAllItemData();
  }

  void _incrementQuantity(String itemId) {
    setState(() {
      itemQuantities[itemId] = (itemQuantities[itemId] ?? 0) + 1;
    });
  }

  void _decrementQuantity(String itemId) {
    setState(() {
      if ((itemQuantities[itemId] ?? 0) > 0) {
        itemQuantities[itemId] = (itemQuantities[itemId] ?? 0) - 1;
      }
    });
  }

  double get totalAmount {
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    return itemQuantities.entries.fold<double>(0.0, (sum, entry) {
      try {
        final item = itemProvider.items.firstWhere((i) => i.id == entry.key);
        final effectivePrice = item.offerPrice ?? item.pricePerPiece;
        return sum + (effectivePrice * entry.value);
      } catch (e) {
        return sum;
      }
    });
  }

  int get totalItems =>
      itemQuantities.values.fold(0, (sum, quantity) => sum + quantity);

  void _scrollToItemsSection() {
    // Scroll to items section (approximate position)
    _scrollController.animateTo(
      600.0, // Approximate position of items section
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    );
  }

  void _navigateToSchedulePickup() {
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);

    final selectedItems = Map.fromEntries(
        itemQuantities.entries.where((entry) => entry.value > 0).map((entry) {
      final item = itemProvider.items.firstWhere((i) => i.id == entry.key);
      return MapEntry(item, entry.value);
    }));

    if (selectedItems.isEmpty) {
      _logger.w('No items selected for pickup.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one item.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _logger.i('Navigating to schedule pickup with items: $selectedItems');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SchedulePickupDeliveryScreen(
          selectedItems: selectedItems,
          totalAmount: totalAmount,
          isAlliedServices: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomSheet: totalItems > 0 ? _buildBottomSheet() : null,
      //   bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      surfaceTintColor: Colors.white,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'Cloud Ironing',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: () async => _fetchInitialData(),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // _buildSearchBar(),
            _buildBanners(),
            _buildQuickActions(),
            // _buildRevenueTracking(),
            // _buildSpecialOffers(),
            _buildItemsSection(),
            // _buildActiveOrders(),
            // _buildRecentOrders(),
            const SizedBox(height: 100), // Space for bottom sheet
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            'Search for services...',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildBanners() {
    return Consumer<BannerProvider>(
      builder: (context, bannerProvider, child) {
        if (bannerProvider.isLoading) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (bannerProvider.error != null) {
          return Container(
            height: 200,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(child: Text('Error: ${bannerProvider.error}')),
          );
        }

        if (bannerProvider.banners.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: CarouselSlider(
            options: CarouselOptions(
              height: 180,
              autoPlay: true,
              enlargeCenterPage: true,
              viewportFraction: 1.0,
            ),
            items: bannerProvider.banners.map((banner) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(banner.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        banner.title ?? 'Professional Ironing',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Text(
                      //   banner.description ?? 'Crisp & Fresh Clothes',
                      //   style: const TextStyle(
                      //     color: Colors.white,
                      //     fontSize: 14,
                      //   ),
                      // ),
                      // const Spacer(),
                      // Add offer text if available in your banner model
                      // Container(
                      //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      //   decoration: BoxDecoration(
                      //     color: Colors.blue,
                      //     borderRadius: BorderRadius.circular(20),
                      //   ),
                      //   child: const Text(
                      //     '30% OFF First Order',
                      //     style: TextStyle(
                      //       color: Colors.white,
                      //       fontSize: 12,
                      //       fontWeight: FontWeight.w600,
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Our Services',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Scroll to items section for placing order
                    // _scrollToItemsSection();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue.shade50,
                          Colors.white,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.iron,
                              color: Colors.blue[600], size: 28),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Placing Order',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Select items for ironing',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AlliedServicesScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.green.shade50,
                          Colors.white,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.home_repair_service,
                              color: Colors.green[600], size: 28),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Allied Services',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bed sheets, stain removal',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueTracking() {
    final firebase_auth.User? currentUser =
        firebase_auth.FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<List<QuerySnapshot>>(
      future: Future.wait([
        FirebaseFirestore.instance
            .collection('orders')
            .where('customerId', isEqualTo: currentUser.uid)
            .where('status', whereIn: ['completed', 'delivered']).get(),
        FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: currentUser.uid)
            .where('status', whereIn: ['completed', 'delivered']).get(),
      ]),
      builder: (context, snapshot) {
        double totalRevenue = 0.0;
        int completedOrdersCount = 0;
        Set<String> processedOrderIds = {};

        if (snapshot.hasData) {
          // Process both query results and avoid duplicates
          for (QuerySnapshot querySnapshot in snapshot.data!) {
            for (QueryDocumentSnapshot doc in querySnapshot.docs) {
              if (!processedOrderIds.contains(doc.id)) {
                processedOrderIds.add(doc.id);
                final data = doc.data() as Map<String, dynamic>;
                final amount = (data['totalAmount'] ?? 0.0).toDouble();
                totalRevenue += amount;
                completedOrdersCount++;
              }
            }
          }
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.purple.shade50,
                    Colors.white,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.account_balance_wallet,
                          color: Colors.purple[600],
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Total Spending',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹${totalRevenue.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'From $completedOrdersCount completed orders',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpecialOffers() {
    return Consumer<SpecialOfferProvider>(
      builder: (context, specialOfferProvider, child) {
        if (specialOfferProvider.isLoading) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (specialOfferProvider.error != null) {
          return Container(
            height: 200,
            child: Center(child: Text('Error: ${specialOfferProvider.error}')),
          );
        }

        if (specialOfferProvider.offers.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Special Offers',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: specialOfferProvider.offers.length,
                itemBuilder: (context, index) {
                  final offer = specialOfferProvider.offers[index];
                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 12),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12)),
                                image: DecorationImage(
                                  image: CachedNetworkImageProvider(
                                      offer.imageUrl ?? ''),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  // Add discount badge if you have discount field in your model
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'Save ₹75',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  offer.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                if (offer.description != null)
                                  Text(
                                    offer.description!,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildItemsSection() {
    return Consumer<ItemProvider>(
      builder: (context, itemProvider, child) {
        if (itemProvider.isLoading) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (itemProvider.error != null) {
          return Container(
            height: 200,
            child: Center(child: Text('Error: ${itemProvider.error}')),
          );
        }

        if (itemProvider.items.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Items for Ironing',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: itemProvider.items.length,
              itemBuilder: (context, index) {
                final item = itemProvider.items[index];
                final quantity = itemQuantities[item.id] ?? 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child:
                            item.imageUrl != null && item.imageUrl!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: item.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorWidget: (context, url, error) {
                                        return Icon(_getItemIcon(item.name),
                                            color: Colors.grey[400]);
                                      },
                                    ),
                                  )
                                : Icon(_getItemIcon(item.name),
                                    color: Colors.grey[400]),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            // Price display with original and offer prices
                            Row(
                              children: [
                                // Original Price (strikethrough) - Show first if there's an offer
                                if (item.originalPrice != null &&
                                    item.originalPrice! >
                                        (item.offerPrice ?? item.pricePerPiece))
                                  Text(
                                    '₹${item.originalPrice!.toInt()}',
                                    style: const TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                // Add spacing between original and offer price
                                if (item.originalPrice != null &&
                                    item.originalPrice! >
                                        (item.offerPrice ?? item.pricePerPiece))
                                  const SizedBox(width: 8),
                                // Current/Offer Price
                                Text(
                                  '₹${(item.offerPrice ?? item.pricePerPiece).toInt()} per piece',
                                  style: TextStyle(
                                    color: item.offerPrice != null
                                        ? Colors.green[700]
                                        : Colors.grey[600],
                                    fontSize: 14,
                                    fontWeight: item.offerPrice != null
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                                // Offer badge
                                // if (item.offerPrice != null && item.originalPrice != null && item.originalPrice! > item.offerPrice!)
                                //   Container(
                                //     margin: const EdgeInsets.only(left: 8),
                                //     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                //     decoration: BoxDecoration(
                                //       color: Colors.red,
                                //       borderRadius: BorderRadius.circular(4),
                                //     ),
                                //     child: Text(
                                //       '${(((item.originalPrice! - item.offerPrice!) / item.originalPrice!) * 100).toInt()}% OFF',
                                //       style: const TextStyle(
                                //         color: Colors.white,
                                //         fontSize: 10,
                                //         fontWeight: FontWeight.bold,
                                //       ),
                                //     ),
                                //   ),
                              ],
                            ),
                            // Position indicator (if needed)
                            // if (item.order > 0)
                            //   Text(
                            //     'Position: ${item.order}',
                            //     style: TextStyle(
                            //       color: Colors.blue[600],
                            //       fontSize: 10,
                            //     ),
                            //   ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: quantity > 0
                                ? () => _decrementQuantity(item.id)
                                : null,
                            icon: Icon(
                              Icons.remove,
                              color: quantity > 0
                                  ? Colors.grey[600]
                                  : Colors.grey[300],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            child: Text(
                              '$quantity',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _incrementQuantity(item.id),
                            icon: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // Widget _buildActiveOrders() {
  //   return Consumer<HomeProvider>(
  //     builder: (context, homeProvider, child) {
  //       return Column(
  //         children: [
  //           Padding(
  //             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  //             child: Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //               children: [
  //                 const Text(
  //                   'Active Orders',
  //                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  //                 ),
  //                 TextButton(
  //                   onPressed: () {},
  //                   child: const Text('View All'),
  //                 ),
  //               ],
  //             ),
  //           ),
  //           Container(
  //             margin: const EdgeInsets.symmetric(horizontal: 16),
  //             padding: const EdgeInsets.all(32),
  //             decoration: BoxDecoration(
  //               color: Colors.white,
  //               borderRadius: BorderRadius.circular(8),
  //               border: Border.all(color: Colors.grey[200]!),
  //             ),
  //             child: Column(
  //               children: [
  //                 Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[400]),
  //                 const SizedBox(height: 12),
  //                 Text(
  //                   'Your orders will appear here',
  //                   style: TextStyle(color: Colors.grey[600]),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  Widget _buildRecentOrders() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Orders',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mar 15, 2025',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '₹250',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Delivered',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {},
                          child: const Text('Reorder'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mar 10, 2025',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '₹180',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 32), // Space for delivered status
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {},
                          child: const Text('Reorder'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSheet() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20), // 20px from bottom
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Items: $totalItems',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Total Amount: ₹${totalAmount.toInt()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 120,
              child: ElevatedButton(
                onPressed: _navigateToSchedulePickup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F3057),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long),
          label: 'Orders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.location_on),
          label: 'Track',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  IconData _getItemIcon(String itemName) {
    final name = itemName.toLowerCase();
    if (name.contains('shirt')) return Icons.checkroom;
    if (name.contains('pant') || name.contains('trouser'))
      return Icons.checkroom;
    if (name.contains('churidar')) return Icons.checkroom;
    if (name.contains('saree') || name.contains('sare')) return Icons.checkroom;
    if (name.contains('blouse') || name.contains('blows'))
      return Icons.checkroom;
    if (name.contains('special')) return Icons.star;
    return Icons.checkroom;
  }
}
