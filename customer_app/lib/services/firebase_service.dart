// lib/services/firebase_service.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  // Firebase instances
  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  static FirebaseStorage get storage => FirebaseStorage.instance;

  // Initialize Firebase
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      print('Firebase initialized successfully');
    } catch (e) {
      print('Firebase initialization error: $e');
      rethrow;
    }
  }

  // Get current user
  static User? get currentUser => auth.currentUser;

  // Check if user is signed in
  static bool get isSignedIn => currentUser != null;

  // Get user ID
  static String? get userId => currentUser?.uid;

  // Get user phone number
  static String? get userPhoneNumber => currentUser?.phoneNumber;

  // Auth state changes stream
  static Stream<User?> get authStateChanges => auth.authStateChanges();

  // Sign out
  static Future<void> signOut() async {
    try {
      await auth.signOut();
      print('User signed out successfully');
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }
}
