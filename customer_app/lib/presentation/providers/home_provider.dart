import 'package:flutter/foundation.dart';
import 'package:customer_app/data/models/banner_model.dart';
import 'package:customer_app/data/models/offer_model.dart';
import 'package:customer_app/data/models/item_model.dart';
import 'package:customer_app/data/models/order_model.dart';
import 'package:customer_app/services/home_service.dart';
import 'package:customer_app/services/order_service.dart';

class HomeProvider extends ChangeNotifier {
  final HomeService _homeService = HomeService();
  final OrderService _orderService = OrderService();

  // Streams for UI to listen to
  Stream<List<BannerModel>>? _bannersStream;
  Stream<List<OfferModel>>? _offersStream;
  Stream<List<ItemModel>>? _itemsStream;

  Stream<List<BannerModel>> get bannersStream => _bannersStream ??= _homeService.getBanners();
  Stream<List<OfferModel>> get offersStream => _offersStream ??= _homeService.getOffers();
  Stream<List<ItemModel>> get itemsStream => _itemsStream ??= _homeService.getItems(); // Initially get all items

  // State for last active order
  OrderModel? _lastActiveOrder;
  bool _isLoadingLastActiveOrder = false;
  String? _lastActiveOrderError;

  OrderModel? get lastActiveOrder => _lastActiveOrder;
  bool get isLoadingLastActiveOrder => _isLoadingLastActiveOrder;
  String? get lastActiveOrderError => _lastActiveOrderError;

  void fetchItemsByCategory(String? category) {
    _itemsStream = _homeService.getItems(categoryFilter: category);
    notifyListeners(); 
  }

  Future<void> fetchLastActiveOrder(String userId) async {
    if (userId.isEmpty) {
      _lastActiveOrderError = "User ID is required to fetch active orders.";
      _lastActiveOrder = null;
      notifyListeners();
      return;
    }
    _isLoadingLastActiveOrder = true;
    _lastActiveOrderError = null;
    _lastActiveOrder = null; // Clear previous order while fetching new one
    notifyListeners();

    try {
      _lastActiveOrder = await _orderService.getLastActiveOrder(userId);
    } catch (e) {
      print('[HomeProvider] Error fetching last active order: $e');
      _lastActiveOrderError = e.toString();
    } finally {
      _isLoadingLastActiveOrder = false;
      notifyListeners();
    }
  }

  // If you need to hold the latest data from streams directly in the provider:
  // List<BannerModel> _banners = [];
  // List<OfferModel> _offers = [];
  // List<ItemModel> _items = [];
  // bool _isLoadingBanners = false;
  // bool _isLoadingOffers = false;
  // bool _isLoadingItems = false;

  // List<BannerModel> get banners => _banners;
  // List<OfferModel> get offers => _offers;
  // List<ItemModel> get items => _items;
  // bool get isLoadingBanners => _isLoadingBanners;
  // bool get isLoadingOffers => _isLoadingOffers;
  // bool get isLoadingItems => _isLoadingItems;

  // HomeProvider() {
  //   _init();
  // }

  // void _init() {
  //   // If you prefer to manage lists and loading states:
  //   // _fetchBanners();
  //   // _fetchOffers();
  //   // _fetchItems();
  // }

  // Example for managing lists directly (instead of just exposing streams):
  // Future<void> _fetchBanners() async {
  //   _isLoadingBanners = true;
  //   notifyListeners();
  //   _homeService.getBanners().listen((bannersData) {
  //     _banners = bannersData;
  //     _isLoadingBanners = false;
  //     notifyListeners();
  //   }, onError: (error) {
  //     print("Error in Banner stream: $error");
  //     _isLoadingBanners = false;
  //     notifyListeners();
  //   });
  // }

  // ... similar methods for _fetchOffers and _fetchItems
} 