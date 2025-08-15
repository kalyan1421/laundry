// providers/allied_service_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../models/allied_service_model.dart';
import '../services/database_service.dart';

class AlliedServiceProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  
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

      final snapshot = await FirebaseFirestore.instance
          .collection('allied_services')
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
    }
  }

  Stream<List<AlliedServiceModel>> alliedServicesStream() {
    return FirebaseFirestore.instance
        .collection('allied_services')
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

  Future<bool> addAlliedService(AlliedServiceModel service, {File? imageFile}) async {
    try {
      _error = null;
      notifyListeners();

      await _databaseService.addAlliedService(service, imageFile: imageFile);
      
      // Reload services to get the updated list with the new service
      await loadAlliedServices();
      
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAlliedService(String serviceId, Map<String, dynamic> data, {File? newImageFile, bool removeImage = false}) async {
    try {
      _error = null;
      notifyListeners();

      await _databaseService.updateAlliedService(serviceId, data, newImageFile: newImageFile, removeImage: removeImage);
      
      // Reload services to get the updated list
      await loadAlliedServices();
      
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAlliedService(String serviceId, String? imageUrl) async {
    try {
      _error = null;
      notifyListeners();

      await _databaseService.deleteAlliedService(serviceId, imageUrl);
      
      // Reload services to get the updated list
      await loadAlliedServices();
      
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleServiceStatus(String serviceId, bool isActive) async {
    try {
      _error = null;
      notifyListeners();

      await _databaseService.updateAlliedService(serviceId, {
        'isActive': isActive,
        'updatedAt': DateTime.now(),
      });
      
      // Update local list
      final index = _alliedServices.indexWhere((service) => service.id == serviceId);
      if (index != -1) {
        _alliedServices[index] = _alliedServices[index].copyWith(
          isActive: isActive,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateServiceOrder(String serviceId, int newOrder) async {
    try {
      _error = null;
      notifyListeners();

      await _databaseService.updateAlliedService(serviceId, {
        'sortOrder': newOrder,
        'updatedAt': DateTime.now(),
      });
      
      // Reload services to get the updated order
      await loadAlliedServices();
      
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Filter methods
  List<AlliedServiceModel> getActiveServices() {
    return _alliedServices.where((service) => service.isActive).toList();
  }

  List<AlliedServiceModel> getServicesByCategory(String category) {
    return _alliedServices.where((service) => service.category == category).toList();
  }

  AlliedServiceModel? getServiceById(String id) {
    try {
      return _alliedServices.firstWhere((service) => service.id == id);
    } catch (e) {
      return null;
    }
  }
}