// presentation/providers/allied_service_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/allied_service_model.dart';

class AlliedServiceProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<AlliedServiceModel> _alliedServices = [];
  bool _isLoading = false;
  String? _error;

  List<AlliedServiceModel> get alliedServices => _alliedServices;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AlliedServiceProvider() {
    loadAlliedServices();
  }

  Future<void> loadAlliedServices() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final snapshot = await _firestore
          .collection('allied_services')
          .where('isActive', isEqualTo: true)
          .get();

      _alliedServices = snapshot.docs
          .map((doc) => AlliedServiceModel.fromMap(doc.id, doc.data()))
          .toList();

      // Sort services by position (sortOrder), then by name
      _alliedServices.sort((a, b) {
        if (a.sortOrder != b.sortOrder) {
          return a.sortOrder.compareTo(b.sortOrder);
        }
        return a.name.compareTo(b.name);
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      print('Error loading allied services: $e');
    }
  }

  Stream<List<AlliedServiceModel>> get alliedServicesStream {
    return _firestore
        .collection('allied_services')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final services = snapshot.docs
          .map((doc) => AlliedServiceModel.fromMap(doc.id, doc.data()))
          .toList();
      
      // Sort services by position (sortOrder), then by name
      services.sort((a, b) {
        if (a.sortOrder != b.sortOrder) {
          return a.sortOrder.compareTo(b.sortOrder);
        }
        return a.name.compareTo(b.name);
      });
      
      return services;
    });
  }

  // Filter methods
  List<AlliedServiceModel> getActiveServices() {
    return _alliedServices.where((service) => service.isActive).toList();
  }

  List<AlliedServiceModel> getServicesByCategory(String category) {
    return _alliedServices.where((service) => 
        service.category == category && service.isActive).toList();
  }

  AlliedServiceModel? getServiceById(String id) {
    try {
      return _alliedServices.firstWhere((service) => service.id == id);
    } catch (e) {
      return null;
    }
  }

  List<AlliedServiceModel> getServicesWithOffers() {
    return _alliedServices.where((service) => 
        service.isActive && service.hasOffer).toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> refreshServices() async {
    await loadAlliedServices();
  }
}