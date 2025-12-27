// providers/banner_provider.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/banner_model.dart';

class BannerProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _bannersCollection = 'banners';
  final ImagePicker _picker = ImagePicker();
  
  List<BannerModel> _banners = [];
  bool _isLoading = false;
  String? _error;
  
  List<BannerModel> get banners => _banners;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Stream<List<BannerModel>> getBannersStream() {
    return _firestore
        .collection(_bannersCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BannerModel.fromMap(doc.data(), doc.id))
            .toList());
  }
  
  /// Picks an image and returns XFile for cross-platform compatibility (web + mobile)
  Future<XFile?> pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    return pickedFile;
  }
  
  /// Uploads image using bytes (works on both web and mobile)
  Future<String?> _uploadImage(XFile imageFile, String bannerId) async {
    try {
      String fileName = 'banner_${bannerId}_${DateTime.now().millisecondsSinceEpoch}.png';
      Reference storageRef = _storage.ref().child('banner_images/$fileName');
      
      // Read as bytes for cross-platform compatibility (web + mobile)
      Uint8List imageBytes = await imageFile.readAsBytes();
      
      // Use putData instead of putFile for web compatibility
      UploadTask uploadTask = storageRef.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/png'),
      );
      TaskSnapshot taskSnapshot = await uploadTask;
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }
  
  Future<void> addBanner({
    required XFile imageFile,
  }) async {
    try {
      DocumentReference docRef = _firestore.collection(_bannersCollection).doc();
      String bannerId = docRef.id;

      String? imageUrl = await _uploadImage(imageFile, bannerId);
      if (imageUrl == null) {
        throw Exception("Image upload failed. Banner not added.");
      }

      BannerModel newBanner = BannerModel(
        id: bannerId,
        imageUrl: imageUrl,
        order: _banners.length, // Auto-assign order based on current count
        isActive: true,
        createdAt: Timestamp.now(),
      );
      await docRef.set(newBanner.toMap());
      notifyListeners();
    } catch (e) {
      print("Error adding banner: $e");
      rethrow;
    }
  }
  
  Future<void> updateBanner(String bannerId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = Timestamp.now();
      await _firestore.collection(_bannersCollection).doc(bannerId).update(data);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  Future<void> deleteBanner(String bannerId, String imageUrl) async {
    try {
      await _firestore.collection(_bannersCollection).doc(bannerId).delete();
      
      if (imageUrl.isNotEmpty) {
        try {
          Reference photoRef = _storage.refFromURL(imageUrl);
          await photoRef.delete();
        } catch (e) {
          print("Error deleting image from storage: $e. Firestore document for banner $bannerId may still be deleted.");
          if (e is FirebaseException && e.code == 'object-not-found') {
            print("Image not found in storage for banner $bannerId.");
          }
        }
      }
      notifyListeners();
    } catch (e) {
      print("Error deleting banner $bannerId from Firestore: $e");
      rethrow;
    }
  }
}
