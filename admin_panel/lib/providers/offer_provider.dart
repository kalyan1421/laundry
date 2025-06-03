
// providers/offer_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/offer_model.dart';

class OfferProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<OfferModel> _offers = [];
  bool _isLoading = false;
  String? _error;
  
  List<OfferModel> get offers => _offers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Stream<List<OfferModel>> getOffersStream() {
    return _firestore
        .collection('offers')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      _offers = snapshot.docs
          .map((doc) => OfferModel.fromMap(doc.id, doc.data()))
          .toList();
      return _offers;
    });
  }
  
  Future<void> addOffer(OfferModel offer) async {
    try {
      await _firestore.collection('offers').add(offer.toMap());
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  Future<void> updateOffer(String offerId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('offers').doc(offerId).update(data);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  Future<void> deleteOffer(String offerId) async {
    try {
      await _firestore.collection('offers').doc(offerId).delete();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}