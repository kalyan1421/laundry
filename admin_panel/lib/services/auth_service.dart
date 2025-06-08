// services/auth_service.dart - Fixed version with better type safety
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Auth state changes stream with user data and type safety
  Stream<Map<String, dynamic>?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((User? user) async {
      if (user != null) {
        try {
          return await _getUserData(user);
        } catch (e) {
          print('Error loading user data in stream: $e');
          return null;
        }
      }
      return null;
    });
  }

  // Get current user safely
  User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Helper method to get user data with type safety
  Future<Map<String, dynamic>?> _getUserData(User user) async {
    try {
      // Check admins collection first
      final adminDoc = await _firestore.collection('admins').doc(user.uid).get();
      if (adminDoc.exists) {
        final data = adminDoc.data();
        if (data != null) {
          return _sanitizeUserData({
            'uid': user.uid,
            'email': user.email ?? '',
            'role': 'admin',
            ...data,
          });
        }
      }
      
      // Check delivery_personnel collection
      final deliveryDoc = await _firestore.collection('delivery').doc(user.uid).get();
      if (deliveryDoc.exists) {
        final data = deliveryDoc.data();
        if (data != null) {
          return _sanitizeUserData({
            'uid': user.uid,
            'email': user.email ?? '',
            'role': 'delivery',
            ...data,
          });
        }
      }
      
      // Check users collection as fallback
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null) {
          return _sanitizeUserData({
            'uid': user.uid,
            'email': user.email ?? '',
            ...data,
          });
        }
      }
      
      return null;
    } catch (e) {
      print('Error in _getUserData: $e');
      return null;
    }
  }

  // Sanitize user data to prevent type casting issues
  Map<String, dynamic> _sanitizeUserData(Map<String, dynamic> rawData) {
    final sanitized = <String, dynamic>{};
    
    for (final entry in rawData.entries) {
      final key = entry.key;
      final value = entry.value;
      
      switch (key) {
        case 'permissions':
          sanitized[key] = _sanitizeStringList(value);
          break;
        case 'assignedOrders':
          sanitized[key] = _sanitizeStringList(value);
          break;
        case 'reviews':
          sanitized[key] = _sanitizeMapList(value);
          break;
        case 'rating':
          sanitized[key] = _sanitizeDouble(value);
          break;
        case 'totalDeliveries':
        case 'completedOrders':
          sanitized[key] = _sanitizeInt(value);
          break;
        case 'isActive':
        case 'isAvailable':
          sanitized[key] = _sanitizeBool(value);
          break;
        case 'createdAt':
        case 'lastLogin':
        case 'joinedAt':
          sanitized[key] = _sanitizeTimestamp(value);
          break;
        default:
          sanitized[key] = value;
      }
    }
    
    return sanitized;
  }

  List<String> _sanitizeStringList(dynamic value) {
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return <String>[];
  }

  List<Map<String, dynamic>> _sanitizeMapList(dynamic value) {
    if (value is List) {
      return value.whereType<Map<String, dynamic>>().toList();
    }
    return <Map<String, dynamic>>[];
  }

  double _sanitizeDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int _sanitizeInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  bool _sanitizeBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return true;
  }

  dynamic _sanitizeTimestamp(dynamic value) {
    if (value is Timestamp) return value;
    if (value is String) {
      try {
        return Timestamp.fromDate(DateTime.parse(value));
      } catch (e) {
        return Timestamp.now();
      }
    }
    return value;
  }

  // Sign in with better error handling
  Future<Map<String, dynamic>?> signIn(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      
      if (result.user != null) {
        return await _getUserData(result.user!);
      }
      
      return null;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Sign in error: $e');
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  // Safe sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  // Method to refresh user data
  Future<Map<String, dynamic>?> refreshUserData() async {
    final user = currentUser;
    if (user != null) {
      return await _getUserData(user);
    }
    return null;
  }
}