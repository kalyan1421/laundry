import 'package:flutter/foundation.dart';
import 'package:customer_app/services/special_offer_service.dart';
import 'package:customer_app/data/models/offer_model.dart';

class SpecialOfferProvider with ChangeNotifier {
  final SpecialOfferService _offerService = SpecialOfferService();

  List<OfferModel> _offers = [];
  bool _isLoading = false;
  String? _error;

  List<OfferModel> get offers => _offers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  SpecialOfferProvider() {
    fetchSpecialOffers();
  }

  Future<void> fetchSpecialOffers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _offers = await _offerService.getActiveSpecialOffers();
    } catch (e) {
      _error = e.toString();
      print('Error in SpecialOfferProvider fetching offers: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 