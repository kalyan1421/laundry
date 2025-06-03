// providers/auth_provider.dart - Fixed version with better type safety
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _user;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<User?>? _authSubscription;
  
  User? get user => _user;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null && _userData != null;
  String? get userRole => _userData?['role'] as String?;
  
  AuthProvider() {
    _initAuth();
  }
  
  void _initAuth() {
    _authSubscription = _auth.authStateChanges().listen(
      (User? user) async {
        try {
          _user = user;
          if (user != null) {
            await _loadUserData();
          } else {
            _userData = null;
            _error = null;
          }
          notifyListeners();
        } catch (e) {
          print('Auth state change error: $e');
          _error = 'Authentication error occurred';
          notifyListeners();
        }
      },
      onError: (error) {
        print('Auth stream error: $error');
        _error = 'Authentication stream error';
        notifyListeners();
      },
    );
  }
  
  Future<void> _loadUserData() async {
    if (_user == null) return;
    
    try {
      _isLoading = true;
      notifyListeners();
      
      // Check admin collection first
      final adminDoc = await _firestore.collection('admins').doc(_user!.uid).get();
      if (adminDoc.exists) {
        final data = adminDoc.data();
        if (data != null) {
          _userData = _sanitizeUserData({
            'id': _user!.uid,
            'email': _user!.email ?? '',
            'role': 'admin',
            ...data,
          });
          _error = null;
          _isLoading = false;
          notifyListeners();
          return;
        }
      }
      
      // Check delivery collection
      final deliveryDoc = await _firestore.collection('delivery_personnel').doc(_user!.uid).get();
      if (deliveryDoc.exists) {
        final data = deliveryDoc.data();
        if (data != null) {
          _userData = _sanitizeUserData({
            'id': _user!.uid,
            'email': _user!.email ?? '',
            'role': 'delivery',
            ...data,
          });
          _error = null;
          _isLoading = false;
          notifyListeners();
          return;
        }
      }
      
      // Check general users collection as fallback
      final userDoc = await _firestore.collection('users').doc(_user!.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null) {
          _userData = _sanitizeUserData({
            'id': _user!.uid,
            'email': _user!.email ?? '',
            ...data,
          });
          _error = null;
          _isLoading = false;
          notifyListeners();
          return;
        }
      }
      
      // User not found in any collection
      _error = 'User profile not found';
      _isLoading = false;
      await signOut();
    } catch (e) {
      print('Load user data error: $e');
      _error = 'Failed to load user data: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Sanitize user data to prevent type casting issues
  Map<String, dynamic> _sanitizeUserData(Map<String, dynamic> rawData) {
    final sanitized = <String, dynamic>{};
    
    for (final entry in rawData.entries) {
      final key = entry.key;
      final value = entry.value;
      
      // Handle specific known problematic fields
      switch (key) {
        case 'permissions':
          if (value is List) {
            sanitized[key] = value.whereType<String>().toList();
          } else {
            sanitized[key] = <String>[];
          }
          break;
        case 'assignedOrders':
          if (value is List) {
            sanitized[key] = value.whereType<String>().toList();
          } else {
            sanitized[key] = <String>[];
          }
          break;
        case 'reviews':
          if (value is List) {
            sanitized[key] = value.whereType<Map<String, dynamic>>().toList();
          } else {
            sanitized[key] = <Map<String, dynamic>>[];
          }
          break;
        case 'rating':
          if (value is int) {
            sanitized[key] = value.toDouble();
          } else if (value is double) {
            sanitized[key] = value;
          } else if (value is String) {
            sanitized[key] = double.tryParse(value) ?? 0.0;
          } else {
            sanitized[key] = 0.0;
          }
          break;
        case 'totalDeliveries':
        case 'completedOrders':
          if (value is int) {
            sanitized[key] = value;
          } else if (value is double) {
            sanitized[key] = value.toInt();
          } else if (value is String) {
            sanitized[key] = int.tryParse(value) ?? 0;
          } else {
            sanitized[key] = 0;
          }
          break;
        case 'isActive':
        case 'isAvailable':
          if (value is bool) {
            sanitized[key] = value;
          } else if (value is String) {
            sanitized[key] = value.toLowerCase() == 'true';
          } else {
            sanitized[key] = true; // Default to true
          }
          break;
        case 'createdAt':
        case 'lastLogin':
        case 'joinedAt':
          // Handle Timestamp objects
          if (value is Timestamp) {
            sanitized[key] = value;
          } else if (value is String) {
            try {
              sanitized[key] = Timestamp.fromDate(DateTime.parse(value));
            } catch (e) {
              sanitized[key] = Timestamp.now();
            }
          } else {
            sanitized[key] = value; // Keep as is for null or other types
          }
          break;
        default:
          // For all other fields, keep as is but handle null safely
          sanitized[key] = value;
      }
    }
    
    return sanitized;
  }
  
  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      
      if (result.user != null) {
        // _loadUserData will be called automatically by auth state listener
        return true;
      }
      
      _isLoading = false;
      _error = 'Sign in failed';
      notifyListeners();
      return false;
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      print('Sign in error: $e');
      _error = 'An unexpected error occurred: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      _userData = null;
      _error = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Sign out error: $e');
      _error = 'Sign out failed';
      notifyListeners();
    }
  }
  
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Wrong password provided';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This user has been disabled';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later';
      case 'invalid-credential':
        return 'Invalid email or password';
      default:
        return 'Authentication failed: $code';
    }
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}