// providers/item_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../models/item_model.dart';
import '../services/database_service.dart';

class ItemProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  
  List<ItemModel> _items = [];
  bool _isLoading = false;
  String? _error;

  List<ItemModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ItemProvider() {
    loadItems();
  }

  Future<void> loadItems() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final snapshot = await FirebaseFirestore.instance
          .collection('items')
          .get();

      _items = snapshot.docs
          .map((doc) => ItemModel.fromMap(doc.id, doc.data()))
          .toList();

      // Sort items by position (sortOrder), then by name
      _items.sort((a, b) {
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

  Future<bool> addItem(ItemModel item, {File? imageFile}) async {
    try {
      _error = null;
      notifyListeners();

      await _databaseService.addItem(item, imageFile: imageFile);
      
      // Reload items to get the updated list with the new item
      await loadItems();
      
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateItem(String itemId, Map<String, dynamic> data, {File? newImageFile, bool removeImage = false}) async {
    try {
      _error = null;
      notifyListeners();

      // Get old image URL if updating image
      String? oldImageUrl;
      final itemIndex = _items.indexWhere((item) => item.id == itemId);
      if (itemIndex != -1) {
        oldImageUrl = _items[itemIndex].imageUrl;
      }

      await _databaseService.updateItem(
        itemId, 
        data, 
        newImageFile: newImageFile, 
        oldImageUrl: oldImageUrl,
        removeImage: removeImage
      );

      // Reload items to get updated data
      await loadItems();
      
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateItemPrice(String itemId, double newPrice) async {
    try {
      _error = null;
      notifyListeners();

      await _databaseService.updateItem(itemId, {
        'price': newPrice,
        'updatedAt': DateTime.now(),
      });

      // Update local list
      final index = _items.indexWhere((item) => item.id == itemId);
      if (index != -1) {
        _items[index] = _items[index].copyWith(
          price: newPrice,
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

  Future<bool> deleteItem(String itemId) async {
    try {
      _error = null;
      notifyListeners();

      await _databaseService.deleteItem(itemId);
      
      // Remove from local list
      _items.removeWhere((item) => item.id == itemId);
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleItemStatus(String itemId) async {
    try {
      _error = null;
      
      final index = _items.indexWhere((item) => item.id == itemId);
      if (index == -1) return false;
      
      final currentStatus = _items[index].isActive;
      
      await _databaseService.updateItem(itemId, {
        'isActive': !currentStatus,
        'updatedAt': DateTime.now(),
      });

      // Update local list
      _items[index] = _items[index].copyWith(
        isActive: !currentStatus,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Get items by category
  List<ItemModel> getItemsByCategory(String category) {
    return _items.where((item) => 
      item.category.toLowerCase() == category.toLowerCase() && 
      item.isActive
    ).toList();
  }

  // Search items by name
  List<ItemModel> searchItems(String query) {
    if (query.isEmpty) return _items;
    
    return _items.where((item) => 
      item.name.toLowerCase().contains(query.toLowerCase()) ||
      item.category.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  // Get active items only
  List<ItemModel> get activeItems {
    return _items.where((item) => item.isActive).toList();
  }

  // Stream of items for real-time updates
  Stream<List<ItemModel>> itemsStream() {
    return _databaseService.getItems();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}