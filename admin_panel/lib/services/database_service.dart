// services/database_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/item_model.dart';
import '../models/order_model.dart';
import '../models/banner_model.dart';
import '../models/offer_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Items Management
  Stream<List<ItemModel>> getItems() {
    return _firestore
        .collection('items')
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ItemModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<String?> uploadItemImage(File imageFile, String itemName) async {
    try {
      // Create a unique filename
      String fileName = 'items/${DateTime.now().millisecondsSinceEpoch}_${itemName.replaceAll(' ', '_')}.jpg';
      
      // Upload image to Firebase Storage
      Reference storageRef = _storage.ref().child(fileName);
      UploadTask uploadTask = storageRef.putFile(imageFile);
      
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> deleteItemImage(String imageUrl) async {
    try {
      Reference storageRef = _storage.refFromURL(imageUrl);
      await storageRef.delete();
    } catch (e) {
      print('Error deleting image: $e');
    }
  }

  Future<void> addItem(ItemModel item, {File? imageFile}) async {
    try {
      String? imageUrl;
      
      // Upload image if provided
      if (imageFile != null) {
        imageUrl = await uploadItemImage(imageFile, item.name);
      }
      
      // Create item map with image URL
      Map<String, dynamic> itemData = item.toMap();
      if (imageUrl != null) {
        itemData['imageUrl'] = imageUrl;
      }
      
      await _firestore.collection('items').add(itemData);
    } catch (e) {
      throw Exception('Failed to add item: $e');
    }
  }

  Future<void> updateItem(String itemId, Map<String, dynamic> data, {File? newImageFile, String? oldImageUrl}) async {
    try {
      // If new image is provided
      if (newImageFile != null) {
        // Delete old image if exists
        if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
          await deleteItemImage(oldImageUrl);
        }
        
        // Upload new image
        String itemName = data['name'] ?? 'item';
        String? newImageUrl = await uploadItemImage(newImageFile, itemName);
        if (newImageUrl != null) {
          data['imageUrl'] = newImageUrl;
        }
      }
      
      data['updatedAt'] = DateTime.now();
      await _firestore.collection('items').doc(itemId).update(data);
    } catch (e) {
      throw Exception('Failed to update item: $e');
    }
  }

  Future<void> deleteItem(String itemId) async {
    try {
      // Get item data to retrieve image URL
      DocumentSnapshot doc = await _firestore.collection('items').doc(itemId).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String? imageUrl = data['imageUrl'];
        
        // Delete image from storage if exists
        if (imageUrl != null && imageUrl.isNotEmpty) {
          await deleteItemImage(imageUrl);
        }
      }
      
      // Delete item document
      await _firestore.collection('items').doc(itemId).delete();
    } catch (e) {
      throw Exception('Failed to delete item: $e');
    }
  }

  // Orders Management
  Stream<List<OrderModel>> getAllOrders() {
    return _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Stream<List<OrderModel>> getDeliveryPersonOrders(String deliveryId) {
    return _firestore
        .collection('orders')
        .where('assignedTo', isEqualTo: deliveryId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': status,
      'updatedAt': DateTime.now(),
    });
  }

  Future<void> assignOrder(String orderId, String deliveryPersonId) async {
    await _firestore.collection('orders').doc(orderId).update({
      'assignedTo': deliveryPersonId,
      'status': 'assigned',
    });
  }

  // Banners Management
  Stream<List<BannerModel>> getBanners() {
    return _firestore
        .collection('banners')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BannerModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  Future<void> addBanner(BannerModel banner) async {
    await _firestore.collection('banners').add(banner.toMap());
  }

  Future<void> updateBanner(String bannerId, Map<String, dynamic> data) async {
    await _firestore.collection('banners').doc(bannerId).update(data);
  }

  Future<void> deleteBanner(String bannerId) async {
    await _firestore.collection('banners').doc(bannerId).delete();
  }

  // Offers Management
  Stream<List<OfferModel>> getOffers() {
    return _firestore
        .collection('offers')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => OfferModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> addOffer(OfferModel offer) async {
    await _firestore.collection('offers').add(offer.toMap());
  }

  Future<void> updateOffer(String offerId, Map<String, dynamic> data) async {
    await _firestore.collection('offers').doc(offerId).update(data);
  }

  Future<void> deleteOffer(String offerId) async {
    await _firestore.collection('offers').doc(offerId).delete();
  }

  // Quick Order Notifications
  Stream<List<Map<String, dynamic>>> getQuickOrderNotifications() {
    return _firestore
        .collection('quickOrderNotifications')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  Future<void> updateQuickOrderStatus(String notificationId, String status) async {
    await _firestore.collection('quickOrderNotifications').doc(notificationId).update({
      'status': status,
      'updatedAt': DateTime.now(),
    });
  }
}