import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer_app/data/models/banner_model.dart';
import 'package:customer_app/data/models/offer_model.dart';
import 'package:customer_app/data/models/item_model.dart';

class HomeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch active banners, ordered by 'order' field
  Stream<List<BannerModel>> getBanners() {
    return _firestore
        .collection('banners')
        .where('isActive', isEqualTo: true)
        .orderBy('order', descending: false) // Assuming lower numbers come first
        .snapshots()
        .map((snapshot) {
      try {
        return snapshot.docs.map((doc) => BannerModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>)).toList();
      } catch (e) {
        print('Error fetching banners: $e');
        return []; // Return empty list on error
      }
    });
  }

  // Fetch active offers, ordered by 'order' field
  Stream<List<OfferModel>> getOffers() {
    return _firestore
        .collection('offers') // Assuming your collection is named 'offers'
        .where('isActive', isEqualTo: true)
        // .where('validUntil', isGreaterThanOrEqualTo: Timestamp.now()) // Optional: filter out expired offers
        .orderBy('order', descending: false)
        .snapshots()
        .map((snapshot) {
      try {
        return snapshot.docs.map((doc) => OfferModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>)).toList();
      } catch (e) {
        print('Error fetching offers: $e');
        return [];
      }
    });
  }

  // Fetch active items, optionally filtered by category, ordered by 'order' field
  Stream<List<ItemModel>> getItems({String? categoryFilter}) {
    Query query = _firestore
        .collection('items')
        .where('isActive', isEqualTo: true);

    if (categoryFilter != null && categoryFilter.isNotEmpty) {
      query = query.where('category', isEqualTo: categoryFilter);
    }

    return query.snapshots().map((snapshot) {
      try {
        final items = snapshot.docs.map((doc) => ItemModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>)).toList();
        
        // Sort items by position (order), then by name
        items.sort((a, b) {
          if (a.order != b.order) {
            return a.order.compareTo(b.order);
          }
          return a.name.compareTo(b.name);
        });
        
        return items;
      } catch (e) {
        print('Error fetching items (category: $categoryFilter): $e');
        return [];
      }
    });
  }
} 