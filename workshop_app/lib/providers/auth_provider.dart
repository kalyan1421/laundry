import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workshop_member.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  
  User? _currentUser;
  WorkshopMember? _currentMember;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get currentUser => _currentUser;
  WorkshopMember? get currentMember => _currentMember;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null && _currentMember != null;

  AuthProvider() {
    _initializeAuth();
  }

  // Initialize authentication state
  Future<void> _initializeAuth() async {
    setLoading(true);
    
    try {
      // Check if user is already logged in
      _currentUser = FirebaseAuth.instance.currentUser;
      
      if (_currentUser != null) {
        // Load workshop member data
        await _loadMemberData();
        
        // Update last login time
        await _updateLastLogin();
      }
    } catch (e) {
      _setError('Failed to initialize authentication: $e');
    } finally {
      setLoading(false);
    }
  }

  // Sign in with email and password (alias for login)
  Future<bool> signIn(String email, String password) async {
    return await login(email, password);
  }

  // Login with email and password
  Future<bool> login(String email, String password) async {
    setLoading(true);
    _clearError();
    
    try {
      final userCredential = await _authService.signInWithEmailAndPassword(email, password);
      
      if (userCredential.user != null) {
        _currentUser = userCredential.user;
        
        // Load workshop member data
        await _loadMemberData();
        
        if (_currentMember != null) {
          // Update last login time
          await _updateLastLogin();
          
          // Save login state
          await _saveLoginState();
          
          notifyListeners();
          return true;
        } else {
          _setError('Workshop member profile not found');
          await logout();
          return false;
        }
      }
    } catch (e) {
      _setError('Login failed: ${e.toString()}');
    } finally {
      setLoading(false);
    }
    
    return false;
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    setLoading(true);
    _clearError();
    
    try {
      await _authService.sendPasswordResetEmail(email);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to send password reset email: ${e.toString()}');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Register new workshop member
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    required String workshopId,
    String role = 'worker',
    List<String> specialties = const [],
  }) async {
    setLoading(true);
    _clearError();
    
    try {
      // Create user account
      final userCredential = await _authService.createUserWithEmailAndPassword(email, password);
      
      if (userCredential.user != null) {
        _currentUser = userCredential.user;
        
        // Create workshop member profile
        final member = WorkshopMember(
          id: _currentUser!.uid,
          name: name,
          email: email,
          phoneNumber: phoneNumber,
          workshopId: workshopId,
          role: role,
          isActive: true,
          joinedDate: DateTime.now(),
          lastLoginAt: DateTime.now(),
          performance: {
            'completedOrders': <String, dynamic>{},
            'processedItems': <String, dynamic>{},
            'rating': 4.0,
          },
          earnings: <String, dynamic>{},
          specialties: specialties,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        // Save member to database
        await _databaseService.saveWorkshopMember(member);
        _currentMember = member;
        
        // Save login state
        await _saveLoginState();
        
        notifyListeners();
        return true;
      }
    } catch (e) {
      _setError('Registration failed: ${e.toString()}');
    } finally {
      setLoading(false);
    }
    
    return false;
  }

  // Sign out (alias for logout)
  Future<void> signOut() async {
    await logout();
  }

  // Logout
  Future<void> logout() async {
    setLoading(true);
    
    try {
      await _authService.signOut();
      await _clearLoginState();
      
      _currentUser = null;
      _currentMember = null;
      _clearError();
      
      notifyListeners();
    } catch (e) {
      _setError('Logout failed: ${e.toString()}');
    } finally {
      setLoading(false);
    }
  }

  // Load workshop member data
  Future<void> _loadMemberData() async {
    if (_currentUser == null) return;
    
    try {
      _currentMember = await _databaseService.getWorkshopMember(_currentUser!.uid);
      
      if (_currentMember == null) {
        _setError('Workshop member profile not found');
        return;
      }
      
      // Check if member is active
      if (!_currentMember!.isActive) {
        _setError('Your account has been deactivated. Please contact your supervisor.');
        await logout();
        return;
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load member data: $e');
    }
  }

  // Update last login time
  Future<void> _updateLastLogin() async {
    if (_currentMember == null) return;
    
    try {
      final updatedMember = _currentMember!.copyWith(
        lastLoginAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _databaseService.updateWorkshopMember(updatedMember);
      _currentMember = updatedMember;
    } catch (e) {
      // Non-critical error, just log it
      debugPrint('Failed to update last login: $e');
    }
  }

  // Update member profile
  Future<bool> updateProfile({
    String? name,
    String? phoneNumber,
    String? profileImageUrl,
    List<String>? specialties,
  }) async {
    if (_currentMember == null) return false;
    
    setLoading(true);
    _clearError();
    
    try {
      final updatedMember = _currentMember!.copyWith(
        name: name,
        phoneNumber: phoneNumber,
        profileImageUrl: profileImageUrl,
        specialties: specialties,
        updatedAt: DateTime.now(),
      );
      
      await _databaseService.updateWorkshopMember(updatedMember);
      _currentMember = updatedMember;
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update profile: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Save login state to shared preferences
  Future<void> _saveLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userId', _currentUser!.uid);
      await prefs.setString('userEmail', _currentUser!.email ?? '');
    } catch (e) {
      debugPrint('Failed to save login state: $e');
    }
  }

  // Clear login state from shared preferences
  Future<void> _clearLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
      await prefs.remove('userId');
      await prefs.remove('userEmail');
    } catch (e) {
      debugPrint('Failed to clear login state: $e');
    }
  }

  // Refresh member data
  Future<void> refreshMemberData() async {
    if (_currentUser == null) return;
    
    await _loadMemberData();
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    setLoading(true);
    _clearError();
    
    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _setError('Failed to send password reset email: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Change password
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    if (_currentUser == null) return false;
    
    setLoading(true);
    _clearError();
    
    try {
      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: _currentUser!.email!,
        password: currentPassword,
      );
      
      await _currentUser!.reauthenticateWithCredential(credential);
      
      // Update password
      await _currentUser!.updatePassword(newPassword);
      
      return true;
    } catch (e) {
      _setError('Failed to change password: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Set loading state
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  // Set error message
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  // Clear error message
  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  // Clear error (public method)
  void clearError() {
    _clearError();
  }

  // Phone Authentication Methods

  String? _verificationId;
  String? _phoneNumber;
  bool _isCodeSent = false;
  bool _isVerifying = false;

  // Getters for phone auth state
  String? get verificationId => _verificationId;
  String? get phoneNumber => _phoneNumber;
  bool get isCodeSent => _isCodeSent;
  bool get isVerifying => _isVerifying;

  // Send OTP to phone number
  Future<bool> sendOTP(String phoneNumber) async {
    setLoading(true);
    _clearError();
    
    try {
      final formattedPhone = _authService.formatPhoneNumber(phoneNumber);
      
      if (!_authService.isValidPhoneNumber(formattedPhone)) {
        _setError('Please enter a valid phone number');
        return false;
      }

      // Check if workshop worker exists with this phone number
      final workerExists = await _databaseService.checkWorkshopWorkerByPhone(formattedPhone);
      if (!workerExists) {
        _setError('No workshop worker found with this phone number. Please contact your supervisor.');
        return false;
      }

      _phoneNumber = formattedPhone;
      _isCodeSent = false;
      _isVerifying = true;
      
      await _authService.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (Android only)
          await _signInWithPhoneCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          _setError('Verification failed: ${e.message}');
          _isVerifying = false;
          notifyListeners();
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _isCodeSent = true;
          _isVerifying = false;
          notifyListeners();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          _isVerifying = false;
          notifyListeners();
        },
        timeout: 60,
      );
      
      return true;
    } catch (e) {
      _setError('Failed to send OTP: ${e.toString()}');
      _isVerifying = false;
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Verify OTP and sign in
  Future<bool> verifyOTP(String otpCode) async {
    if (_verificationId == null || _phoneNumber == null) {
      _setError('Please request OTP first');
      return false;
    }

    setLoading(true);
    _clearError();
    
    try {
      final credential = _authService.createPhoneAuthCredential(
        verificationId: _verificationId!,
        smsCode: otpCode,
      );
      
      return await _signInWithPhoneCredential(credential);
    } catch (e) {
      _setError('Invalid OTP: ${e.toString()}');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Sign in with phone credential
  Future<bool> _signInWithPhoneCredential(PhoneAuthCredential credential) async {
    try {
      final userCredential = await _authService.signInWithPhoneCredential(credential);
      
      if (userCredential.user != null) {
        _currentUser = userCredential.user;
        
        // Load workshop member data by phone number
        await _loadMemberDataByPhone(_phoneNumber!);
        
        if (_currentMember != null) {
          // Update the workshop worker's Firebase Auth UID
          await _linkPhoneToWorkshopWorker();
          
          // Update last login time
          await _updateLastLogin();
          
          // Save login state
          await _saveLoginState();
          
          // Reset phone auth state
          _resetPhoneAuthState();
          
          notifyListeners();
          return true;
        } else {
          _setError('Workshop worker profile not found');
          await logout();
          return false;
        }
      }
      
      return false;
    } catch (e) {
      _setError('Phone sign in failed: ${e.toString()}');
      return false;
    }
  }

  // Load workshop member data by phone number
  Future<void> _loadMemberDataByPhone(String phoneNumber) async {
    try {
      _currentMember = await _databaseService.getWorkshopWorkerByPhone(phoneNumber);
      
      if (_currentMember == null) {
        _setError('Workshop worker profile not found');
        return;
      }
      
      // Check if member is active
      if (!_currentMember!.isActive) {
        _setError('Your account has been deactivated. Please contact your supervisor.');
        await logout();
        return;
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load worker data: $e');
    }
  }

  // Link phone authentication to workshop worker
  Future<void> _linkPhoneToWorkshopWorker() async {
    if (_currentUser == null || _currentMember == null) return;
    
    try {
      // Update workshop worker with Firebase Auth UID
      await _databaseService.updateWorkshopWorkerUID(_currentMember!.id, _currentUser!.uid);
      
      // Update member with new UID
      _currentMember = _currentMember!.copyWith(
        // If WorkshopMember has uid field, update it here
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      // Non-critical error
      debugPrint('Failed to link phone to workshop worker: $e');
    }
  }

  // Reset phone auth state
  void _resetPhoneAuthState() {
    _verificationId = null;
    _phoneNumber = null;
    _isCodeSent = false;
    _isVerifying = false;
  }

  // Resend OTP
  Future<bool> resendOTP() async {
    if (_phoneNumber == null) {
      _setError('Please enter phone number first');
      return false;
    }
    
    return await sendOTP(_phoneNumber!);
  }

  // Phone number login (public method)
  Future<bool> loginWithPhone(String phoneNumber) async {
    return await sendOTP(phoneNumber);
  }
} 