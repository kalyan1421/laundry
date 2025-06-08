import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_controller.dart';
import 'package:carousel_slider/carousel_options.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:customer_app/data/models/banner_model.dart';
import 'package:customer_app/presentation/providers/banner_provider.dart';
import 'package:customer_app/presentation/providers/special_offer_provider.dart';
import 'package:customer_app/data/models/offer_model.dart';
import 'package:customer_app/presentation/providers/item_provider.dart';
import 'package:customer_app/data/models/item_model.dart';
import 'package:customer_app/presentation/screens/orders/Schedule_PickupDelivery_Screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/presentation/providers/home_provider.dart';
import 'package:customer_app/core/theme/app_colors.dart';
import 'package:customer_app/core/theme/app_text_theme.dart';
import 'package:customer_app/presentation/widgets/common/loading_widget.dart';

// Added for Active Order Display
import 'package:customer_app/presentation/providers/auth_provider.dart'; // Assuming AuthProvider path
import 'package:customer_app/data/models/order_model.dart' as CustomerOrderModel; // Aliased to avoid conflict if admin OrderModel is ever imported here
import 'package:intl/intl.dart';
// import 'package:customer_app/presentation/screens/orders/order_details_screen.dart'; // Uncomment if you have this

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentBannerIndex = 0;
  Map<String, int> itemQuantities = {};
  final CarouselSliderController _carouselController = CarouselSliderController();

  @override
  void initState() {
    super.initState();
    // Initial item quantities are implicitly zero
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialData();
    });
  }

  void _fetchInitialData() {
    if (mounted) {
      // Fetch banners and offers (assuming these are still fetched like this)
      Provider.of<BannerProvider>(context, listen: false).fetchBanners();
      Provider.of<SpecialOfferProvider>(context, listen: false).fetchSpecialOffers();
      Provider.of<ItemProvider>(context, listen: false).loadAllItemData();

      // Fetch last active order
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);
      if (authProvider.authStatus == AuthStatus.authenticated && authProvider.firebaseUser?.uid != null) {
        homeProvider.fetchLastActiveOrder(authProvider.firebaseUser!.uid);
      } else {
        print('[HomeScreen] User not authenticated or UID is null, cannot fetch active order.');
      }
    }
  }

  int getTotalItems() {
    return itemQuantities.values.fold(0, (sum, quantity) => sum + quantity);
  }

  int getTotalPrice() {
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    int total = 0;
    final List<ItemModel> allItems = itemProvider.items;

    if (allItems.isEmpty && itemQuantities.isNotEmpty) {
      print("Warning: Trying to calculate total price but no items loaded in ItemProvider, or itemQuantities map is stale.");
    }

    itemQuantities.forEach((itemId, quantity) {
      if (quantity <= 0) return;
      try {
        final item = allItems.firstWhere((i) => i.id == itemId);
        total += (quantity * item.pricePerPiece).round();
      } catch (e) {
        print("Error calculating price for item ID '$itemId': Item not found in ItemProvider.items. Error: $e");
      }
    });
    return total;
  }

  void showQuickOrderPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return QuickOrderDialog(
          onOrderSelected: (orderType) {
            showConfirmationPopup(orderType);
          },
        );
      },
    );
  }

  void showConfirmationPopup(String orderType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ConfirmationDialog();
      },
    );
  }

  Widget _buildSectionTitle(String title, {VoidCallback? onViewAllPressed}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10.0, 10.0, 16.0, 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F3057), 
            ),
          ),
          if (onViewAllPressed != null)
            TextButton(
              onPressed: onViewAllPressed,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                alignment: Alignment.centerRight,
              ),
              child: const Text(
                'View All',
                style: TextStyle(
                  color: Color(0xFF007AFF), // A standard blue for "View All"
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBannerSlider(BuildContext context) {
    final bannerProvider = Provider.of<BannerProvider>(context);

    if (bannerProvider.isLoading) {
      return Container(
        height: 180,
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    if (bannerProvider.error != null || bannerProvider.banners.isEmpty) {
      return Container(
        height: 180,
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          bannerProvider.banners.isEmpty ? 'No promotions available' : 'Failed to load promotions',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return Column(
      children: [
        Container(
          height: 180,
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: CarouselSlider.builder(
            carouselController: _carouselController,
            itemCount: bannerProvider.banners.length,
            itemBuilder: (context, index, realIndex) {
              final banner = bannerProvider.banners[index];
              return Container(
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(banner.imageUrl),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.3),
                      BlendMode.darken,
                    ),
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      banner.title ?? 'Professional Ironing',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      banner.subtitle ?? 'Crisp & Fresh Clothes',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    if (banner.promoText != null && banner.promoText!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          banner.promoText!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
            options: CarouselOptions(
              height: 180,
              viewportFraction: 1.0,
              enlargeCenterPage: false,
              autoPlay: bannerProvider.banners.length > 1,
              reverse: true,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentBannerIndex = index;
                });
              },
            ),
          ),
        ),
        if (bannerProvider.banners.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              bannerProvider.banners.length,
              (index) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentBannerIndex == index ? Colors.blue : Colors.grey[300],
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSpecialOffersSection(BuildContext context) {
    final offerProvider = Provider.of<SpecialOfferProvider>(context);

    if (offerProvider.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (offerProvider.error != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(child: Text('Failed to load offers: ${offerProvider.error}')),
      );
    }

    if (offerProvider.offers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Special Offers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F3057),
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Implement view all offers
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                ),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: offerProvider.offers.length,
            itemBuilder: (context, index) {
              final offer = offerProvider.offers[index];
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                      child: SizedBox(
                        width: 100,
                        height: double.infinity,
                        child: offer.imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: offer.imageUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[200],
                                  child: const Center(child: CircularProgressIndicator()),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image_not_supported_outlined),
                                ),
                              )
                            : Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.image_not_supported_outlined),
                              ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Save ₹${offer.discountAmount?.toStringAsFixed(0) ?? "75"}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              offer.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F3057),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              offer.description,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow(ItemModel item, int quantity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: (item.iconUrl != null && item.iconUrl!.isNotEmpty)
                ? CachedNetworkImage(
                    imageUrl: item.iconUrl!,
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const SizedBox(
                        width: 24, 
                        height: 24, 
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2.0))
                    ),
                    errorWidget: (context, url, error) => 
                        const Icon(Icons.broken_image_outlined, size: 24, color: Colors.grey),
                  )
                : const Icon(Icons.help_outline_outlined, size: 24, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0F3057)
                  ),
                ),
                Text(
                  '₹${item.pricePerPiece.toStringAsFixed(0)} per piece',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                color: Colors.grey[400],
                iconSize: 28,
                onPressed: quantity > 0
                    ? () {
                        setState(() {
                          itemQuantities[item.id] = (itemQuantities[item.id] ?? 1) - 1;
                        });
                      }
                    : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              SizedBox(
                width: 30,
                child: Text(
                  quantity.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0F3057),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle),
                color: Colors.blue,
                iconSize: 28,
                onPressed: () {
                  setState(() {
                    itemQuantities[item.id] = (itemQuantities[item.id] ?? 0) + 1;
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectItemsSection(BuildContext context) {
    final itemProvider = Provider.of<ItemProvider>(context);

    if (itemProvider.isLoading && itemProvider.items.isEmpty) { // Check items, not groupedByCategory for this view
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Error check can remain similar
    if (itemProvider.error != null && itemProvider.items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(child: Text('Failed to load items: ${itemProvider.error}', textAlign: TextAlign.center)),
      );
    }

    // Changed to check itemProvider.items directly
    if (itemProvider.items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(child: Text('No items available at the moment.', style: TextStyle(color: Colors.grey[600]))),
      );
    }

    // All items from the provider, not grouped by category for this section as per new UI
    final List<ItemModel> allDisplayItems = itemProvider.items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'Select Items for Ironing',
          onViewAllPressed: () {
            // TODO: Implement navigation to all items screen or filter
            print('View All Items tapped');
          },
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: allDisplayItems.length,
          itemBuilder: (context, index) {
            final item = allDisplayItems[index];
            final quantity = itemQuantities[item.id] ?? 0;
            return _buildItemRow(item, quantity);
          },
        ),
      ],
    );
  }

  // NEW Active Orders Section
  Widget _buildActiveOrdersSection(BuildContext context) {
    final homeProvider = Provider.of<HomeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false); // For retrying

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Active Order', onViewAllPressed: () {
          // TODO: Navigate to a full list of user's orders
          print('View all orders pressed');
        }),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _buildActiveOrderCard(context, homeProvider, authProvider),
        ),
        const SizedBox(height: 24), // Spacing after the section
      ],
    );
  }

  Widget _buildActiveOrderCard(BuildContext context, HomeProvider homeProvider, AuthProvider authProvider) {
    if (homeProvider.isLoadingLastActiveOrder) {
      return const Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        child: SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ),
      );
    }

    if (homeProvider.lastActiveOrderError != null) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        color: Colors.red[50],
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error: ${homeProvider.lastActiveOrderError}',
                style: TextStyle(color: Colors.red[700], fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
                onPressed: () {
                   if (authProvider.authStatus == AuthStatus.authenticated && authProvider.firebaseUser?.uid != null) {
                     homeProvider.fetchLastActiveOrder(authProvider.firebaseUser!.uid);
                   }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              )
            ],
          ),
        ),
      );
    }

    final CustomerOrderModel.OrderModel? order = homeProvider.lastActiveOrder;

    if (order == null) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        child: Container(
          height: 100,
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'No active orders at the moment.',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 3,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    'Order #${order.orderNumber ?? order.id.substring(0, 6)}',
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    order.status,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.calendar_today_outlined,
              'Ordered On:',
              DateFormat('EEE, MMM d, yyyy').format(order.orderTimestamp.toDate()),
            ),
            const SizedBox(height: 6),
            _buildDetailRow(
              Icons.local_laundry_service_outlined, // Changed icon
              'Service:',
              order.serviceType,
            ),
             const SizedBox(height: 6),
            _buildDetailRow(
              Icons.currency_rupee_outlined, // Changed icon
              'Total:',
              '₹${order.totalAmount.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.visibility_outlined, size: 20),
                label: const Text('View Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  // TODO: Navigate to OrderDetailsScreen if it exists
                  // Example: if OrderDetailsScreen.routeName is defined
                  // Navigator.pushNamed(context, OrderDetailsScreen.routeName, arguments: order.id);
                  // Or direct navigation:
                  // Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: order)));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Navigate to details for order: ${order.id}')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Text('$label ', style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w500)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F3057)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    final bannerProvider = Provider.of<BannerProvider>(context);
    bool showBottomBar = getTotalItems() > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBannerSlider(context),
            _buildSpecialOffersSection(context),
            _buildSelectItemsSection(context),
            _buildActiveOrdersSection(context),
            if (showBottomBar) const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: showBottomBar
          ? Container(
              height: 110,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 0,
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Items: ${getTotalItems()}',
                          style: TextStyle(fontSize: 18, color: Color(0xFF4B5563), fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Total Amount: ₹${getTotalPrice()}',
                          style: const TextStyle(fontSize: 18, color: Color(0xFF4B5563), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SchedulePickupDeliveryScreen(
                            selectedItems: itemQuantities.entries.where((e) => e.value > 0).fold<Map<ItemModel, int>>({}, (map, entry) {
                              final itemProvider = Provider.of<ItemProvider>(context, listen: false);
                              try {
                                final item = itemProvider.items.firstWhere((i) => i.id == entry.key);
                                map[item] = entry.value;
                              } catch (e) {
                                print("Error finding item ${entry.key} for schedule screen: $e");
                              }
                              return map;
                            }),
                            totalAmount: getTotalPrice().toDouble(),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      // padding: const EdgeInsets.symmetric(horizontal: 120, vertical: 12),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    child: const Text('Continue', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

// Quick Order Dialog
class QuickOrderDialog extends StatefulWidget {
  final Function(String) onOrderSelected;

  const QuickOrderDialog({Key? key, required this.onOrderSelected})
    : super(key: key);

  @override
  State<QuickOrderDialog> createState() => _QuickOrderDialogState();
}

class _QuickOrderDialogState extends State<QuickOrderDialog> {
  String? selectedOption;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Order Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F3057),
              ),
            ),
            const SizedBox(height: 20),
            CheckboxListTile(
              title: const Text('Order with Delivery Partner'),
              subtitle: const Text('Professional pickup & delivery service'),
              value: selectedOption == 'delivery',
              onChanged: (bool? value) {
                setState(() {
                  selectedOption = value! ? 'delivery' : null;
                });
              },
              activeColor: const Color(0xFF00A8E8),
            ),
            CheckboxListTile(
              title: const Text('Order by Calling User'),
              subtitle: const Text('We will call you to confirm details'),
              value: selectedOption == 'call',
              onChanged: (bool? value) {
                setState(() {
                  selectedOption = value! ? 'call' : null;
                });
              },
              activeColor: const Color(0xFF00A8E8),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFF6E7A8A)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        selectedOption != null
                            ? () {
                              Navigator.of(context).pop();
                              widget.onOrderSelected(selectedOption!);
                            }
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A8E8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Confirmation Dialog
class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00A8E8).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Color(0xFF00A8E8),
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Order Confirmed!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F3057),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'We will contact you soon to confirm your order details and arrange pickup/delivery.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6E7A8A), fontSize: 14),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 150,
              height: 40,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A8E8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
