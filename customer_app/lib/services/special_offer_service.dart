import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer_app/data/models/offer_model.dart';
import 'package:customer_app/core/constants/firebase_constants.dart';

class SpecialOfferService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<OfferModel>> getActiveSpecialOffers() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> offerSnapshot = await _firestore
          .collection(FirebaseConstants.offersCollection)
          .where('isActive', isEqualTo: true) // Fetch only active offers
          .where('validTo', isGreaterThanOrEqualTo: Timestamp.now()) // Changed from validUntil
          .orderBy('validTo') // Changed from validUntil
          .orderBy('createdAt', descending: true)
          .get();

      return offerSnapshot.docs
          .map((doc) => OfferModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    } catch (e) {
      print('Error fetching special offers: $e');
      return [];
    }
  }

  // Optional: Stream for real-time updates if needed in the future
  // Stream<List<SpecialOfferModel>> getActiveSpecialOffersStream() {
  //   return _firestore
  //       .collection('specialOffers')
  //       .where('isActive', isEqualTo: true)
  //       .where('validTo', isGreaterThanOrEqualTo: Timestamp.now())
  //       .orderBy('validTo')
  //       .orderBy('createdAt', descending: true)
  //       .snapshots()
  //       .map((snapshot) => snapshot.docs
  //           .map((doc) => SpecialOfferModel.fromFirestore(doc))
  //           .toList());
  // }
} 