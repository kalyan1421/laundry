import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/banner_model.dart';

class BannerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<BannerModel>> getBanners() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> bannerSnapshot = await _firestore
          .collection('banners')
          .orderBy('createdAt', descending: true)
          .get();

      return bannerSnapshot.docs.map((doc) {
        return BannerModel.fromFirestore(doc);
      }).toList();
    } catch (e) {
      print('Error fetching banners: $e');
      return [];
    }
  }
} 