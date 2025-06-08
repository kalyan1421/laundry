import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/offer_model.dart'; // Adjust path as per your project structure

class OfferService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'offers';

  // Get a stream of all offers
  Stream<List<OfferModel>> getOffers() {
    return _firestore.collection(_collectionPath)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => OfferModel.fromFirestore(doc)).toList();
    });
  }

  // Get a single offer by ID (if needed, for an edit screen perhaps)
  Future<OfferModel?> getOfferById(String id) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(_collectionPath).doc(id).get();
      if (doc.exists) {
        return OfferModel.fromFirestore(doc);
      }
    } catch (e) {
      print('Error fetching offer by ID: $e');
    }
    return null;
  }

  // Add a new offer
  Future<String?> addOffer(OfferModel offer) async {
    try {
      DocumentReference docRef = await _firestore.collection(_collectionPath).add(offer.toJson());
      return docRef.id;
    } catch (e) {
      print('Error adding offer: $e');
      return null;
    }
  }

  // Update an existing offer
  Future<bool> updateOffer(OfferModel offer) async {
    if (offer.id == null) {
      print('Error: Offer ID is null, cannot update.');
      return false;
    }
    try {
      await _firestore.collection(_collectionPath).doc(offer.id).update(offer.toJson());
      return true;
    } catch (e) {
      print('Error updating offer: $e');
      return false;
    }
  }

  // Delete an offer
  Future<bool> deleteOffer(String id) async {
    try {
      await _firestore.collection(_collectionPath).doc(id).delete();
      return true;
    } catch (e) {
      print('Error deleting offer: $e');
      return false;
    }
  }
} 