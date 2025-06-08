import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:path/path.dart' as p;

class StorageService {
  final firebase_storage.FirebaseStorage _storage = firebase_storage.FirebaseStorage.instance;

  Future<String?> uploadOfferImage(File imageFile, String offerId) async {
    try {
      String fileName = p.basename(imageFile.path);
      String filePath = 'offer_images/$offerId/$fileName';

      firebase_storage.Reference ref = _storage.ref().child(filePath);
      firebase_storage.UploadTask uploadTask = ref.putFile(imageFile);

      await uploadTask;
      String downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading offer image: $e');
      return null;
    }
  }

  Future<void> deleteOfferImage(String imageUrl) async {
    if (imageUrl.isEmpty) return;
    try {
      firebase_storage.Reference photoRef = _storage.refFromURL(imageUrl);
      await photoRef.delete();
    } catch (e) {
      print('Error deleting offer image: $e');
      // It might fail if the file doesn't exist, or permissions are wrong.
      // Decide if you need to propagate this error or log it.
    }
  }
} 