// providers/auth_provider.dart - Simple Phone + Code Authentication
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/delivery_partner_model.dart';
import '../services/delivery_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthStatus { loading, authenticated, unauthenticated }
enum LoginStatus { idle, authenticating, success, failed }

class AuthProvider extends ChangeNotifier {
  final DeliveryAuthService _authService = DeliveryAuthService();

  
  DeliveryPartnerModel? _deliveryPartner;
  AuthStatus _authStatus = AuthStatus.loading;
  LoginStatus _loginStatus = LoginStatus.idle;
  bool _isLoading = false;
  String? _error;
  
  // Getters
  DeliveryPartnerModel? get deliveryPartner => _deliveryPartner;
  AuthStatus get authStatus => _authStatus;
  LoginStatus get loginStatus => _loginStatus;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _authStatus == AuthStatus.authenticated;
  
  AuthProvider() {
    _initAuth();
  }
  
  /// Initialize authentication state
  void _initAuth() async {
    try {
      // Check if user was previously logged in
      final prefs = await SharedPreferences.getInstance();
      final partnerId = prefs.getString('delivery_partner_id');
      
      if (partnerId != null) {
        // Try to load saved delivery partner data
        final partnerData = await _authService.getDeliveryPartner(partnerId);
        if (partnerData != null && partnerData['isActive'] == true) {
          print('🚚 ✅ Custom authentication session restored - no Firebase Auth needed');
          
          _deliveryPartner = DeliveryPartnerModel.fromMap(partnerData);
          _authStatus = AuthStatus.authenticated;
          print('🚚 ✅ Restored authentication for: ${_deliveryPartner!.name}');
        } else {
          // Clear invalid session
          await _clearSession();
          _authStatus = AuthStatus.unauthenticated;
          print('🚚 ❌ Invalid session, cleared');
        }
      } else {
        _authStatus = AuthStatus.unauthenticated;
        print('🚚 No previous session found');
      }
      
      notifyListeners();
    } catch (e) {
      print('🚚 Error initializing auth: $e');
      _authStatus = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  /// Login with phone number and code
  Future<bool> login(String phoneNumber, String loginCode) async {
    try {
      print('🚚 Attempting login: $phoneNumber');
      _isLoading = true;
      _loginStatus = LoginStatus.authenticating;
      _error = null;
      notifyListeners();

      // Authenticate with service
      final partnerData = await _authService.authenticateDeliveryPartner(
        phoneNumber: phoneNumber,
        loginCode: loginCode,
      );

      if (partnerData != null) {
        print('🚚 ✅ Custom authentication successful - no Firebase Auth needed');
        
        _deliveryPartner = DeliveryPartnerModel.fromMap(partnerData);
        _authStatus = AuthStatus.authenticated;
        _loginStatus = LoginStatus.success;
        
        // Save session
        await _saveSession(partnerData['id']);
        
        print('🚚 ✅ Login successful: ${_deliveryPartner!.name}');
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception('Authentication failed');
      }

    } catch (e) {
      print('🚚 ❌ Login failed: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      _loginStatus = LoginStatus.failed;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      print('🚚 ✅ Custom authentication sign-out - no Firebase Auth needed');
      
      await _clearSession();
      _deliveryPartner = null;
      _authStatus = AuthStatus.unauthenticated;
      _loginStatus = LoginStatus.idle;
      _error = null;
      notifyListeners();
      print('🚚 Signed out successfully');
    } catch (e) {
      print('🚚 Error signing out: $e');
    }
  }

  /// Save authentication session
  Future<void> _saveSession(String partnerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('delivery_partner_id', partnerId);
      await prefs.setInt('login_timestamp', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('🚚 Error saving session: $e');
    }
  }

  /// Clear authentication session
  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('delivery_partner_id');
      await prefs.remove('login_timestamp');
    } catch (e) {
      print('🚚 Error clearing session: $e');
    }
  }

  /// Refresh delivery partner data
  Future<void> refreshPartnerData() async {
    if (_deliveryPartner == null) return;
    
    try {
      final partnerData = await _authService.getDeliveryPartner(_deliveryPartner!.id);
      if (partnerData != null && partnerData['isActive'] == true) {
        _deliveryPartner = DeliveryPartnerModel.fromMap(partnerData);
        notifyListeners();
        print('🚚 ✅ Partner data refreshed');
      } else {
        // Partner was deactivated, sign out
        await signOut();
        print('🚚 ⚠️ Partner deactivated, signed out');
      }
    } catch (e) {
      print('🚚 Error refreshing partner data: $e');
    }
  }

  /// Update online status
  Future<void> updateOnlineStatus(bool isOnline) async {
    if (_deliveryPartner == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('delivery')
          .doc(_deliveryPartner!.id)
          .update({
        'isOnline': isOnline,
        'updatedAt': Timestamp.now(),
      });

      _deliveryPartner = _deliveryPartner!.copyWith(isOnline: isOnline);
      notifyListeners();
      print('🚚 Online status updated: $isOnline');
    } catch (e) {
      print('🚚 Error updating online status: $e');
    }
  }

  /// Clear errors
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Reset login status
  void resetLoginStatus() {
    _loginStatus = LoginStatus.idle;
    notifyListeners();
  }
}

// Extension to add copyWith method to DeliveryPartnerModel if not present
extension DeliveryPartnerModelExtension on DeliveryPartnerModel {
  DeliveryPartnerModel copyWith({
    String? id,
    String? uid,
    String? name,
    String? email,
    String? phoneNumber,
    String? licenseNumber,
    String? aadharNumber,
    String? role,
    bool? isActive,
    bool? isAvailable,
    bool? isOnline,
    bool? isRegistered,
    double? rating,
    int? totalDeliveries,
    int? completedDeliveries,
    int? cancelledDeliveries,
    double? earnings,
    List<String>? currentOrders,
    List<String>? orderHistory,
    Map<String, dynamic>? vehicleInfo,
    Map<String, dynamic>? documents,
    Map<String, dynamic>? bankDetails,
    Map<String, dynamic>? address,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    String? createdBy,
    String? createdByRole,
    String? registrationToken,
  }) {
    return DeliveryPartnerModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      aadharNumber: aadharNumber ?? this.aadharNumber,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      isAvailable: isAvailable ?? this.isAvailable,
      isOnline: isOnline ?? this.isOnline,
      isRegistered: isRegistered ?? this.isRegistered,
      rating: rating ?? this.rating,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      completedDeliveries: completedDeliveries ?? this.completedDeliveries,
      cancelledDeliveries: cancelledDeliveries ?? this.cancelledDeliveries,
      earnings: earnings ?? this.earnings,
      currentOrders: currentOrders ?? this.currentOrders,
      orderHistory: orderHistory ?? this.orderHistory,
      vehicleInfo: vehicleInfo ?? this.vehicleInfo,
      documents: documents ?? this.documents,
      bankDetails: bankDetails ?? this.bankDetails,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      createdByRole: createdByRole ?? this.createdByRole,
      registrationToken: registrationToken ?? this.registrationToken,
    );
  }
}