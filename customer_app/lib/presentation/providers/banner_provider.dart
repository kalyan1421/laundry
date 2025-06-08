import 'package:flutter/foundation.dart';
import '../../data/models/banner_model.dart';
import '../../services/banner_service.dart';

class BannerProvider with ChangeNotifier {
  final BannerService _bannerService = BannerService();

  List<BannerModel> _banners = [];
  bool _isLoading = false;
  String? _error;

  List<BannerModel> get banners => _banners;
  bool get isLoading => _isLoading;
  String? get error => _error;

  BannerProvider() {
    fetchBanners();
  }

  Future<void> fetchBanners() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _banners = await _bannerService.getBanners();
    } catch (e) {
      _error = e.toString();
      print('Error in BannerProvider fetching banners: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
