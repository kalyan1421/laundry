// services/workshop_worker_service.dart - No Firebase Auth operations
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'dart:convert';
import '../models/workshop_worker_model.dart';

class WorkshopWorkerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Toggle workshop worker active status
  Future<bool> toggleWorkshopWorkerStatus(String id, bool isActive) async {
    try {
      await _firestore.collection('workshop_workers').doc(id).update({
        'isActive': isActive,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('Error toggling workshop worker status: $e');
      return false;
    }
  }

  // Update workshop worker status (alias for better naming)
  Future<bool> updateWorkshopWorkerStatus(String id, bool isActive) async {
    return toggleWorkshopWorkerStatus(id, isActive);
  }

  // Delete workshop worker (soft delete)
  Future<bool> deleteWorkshopWorker(String id) async {
    try {
      await _firestore.collection('workshop_workers').doc(id).update({
        'isActive': false,
        'isDeleted': true,
        'deletedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('Error deleting workshop worker: $e');
      return false;
    }
  }

  // Get workshop worker statistics
  Future<Map<String, dynamic>> getWorkshopWorkerStats() async {
    try {
      final snapshot = await _firestore
          .collection('workshop_workers')
          .where('isDeleted', isNotEqualTo: true)
          .get();

      int total = snapshot.docs.length;
      int active = snapshot.docs.where((doc) => doc.data()['isActive'] == true).length;
      int online = snapshot.docs.where((doc) => doc.data()['isOnline'] == true).length;
      int available = snapshot.docs.where((doc) => 
        doc.data()['isActive'] == true && 
        doc.data()['isAvailable'] == true
      ).length;

      return {
        'total': total,
        'active': active,
        'inactive': total - active,
        'online': online,
        'available': available,
      };
    } catch (e) {
      print('Error getting workshop worker stats: $e');
      return {
        'total': 0,
        'active': 0,
        'inactive': 0,
        'online': 0,
        'available': 0,
      };
    }
  }

  // Create workshop worker by admin WITHOUT any Firebase Auth operations
  Future<WorkshopWorkerModel?> createWorkshopWorkerByAdmin({
    required String name,
    String? email,
    required String phoneNumber,
    required String employeeId,
    String? workshopLocation,
    double hourlyRate = 0.0,
    String? shift,
    String? aadharNumber,
    String? aadharCardUrl,
    String? createdByUid,
  }) async {
    try {
      // Format phone number
      String formattedPhone = phoneNumber.startsWith('+') ? phoneNumber : '+91$phoneNumber';
      
      // Generate a unique ID for the workshop worker
      String workerId = _firestore.collection('workshop_workers').doc().id;
      
      // Generate a secure registration token
      final random = Random.secure();
      var values = List<int>.generate(4, (i) => random.nextInt(255));
      String registrationToken = base64UrlEncode(values).substring(0, 6).toUpperCase();
      
      // Create workshop worker data
      final workerData = {
        'id': workerId,
        'uid': workerId, // Will be updated when they first login
        'name': name,
        'phoneNumber': formattedPhone,
        'employeeId': employeeId.toUpperCase(),
        'role': 'workshop_worker',
        'isActive': true,
        'isAvailable': true,
        'isOnline': false,
        'isRegistered': false, // Will be set to true on first login
        'registrationToken': registrationToken,
        'rating': 0.0,
        'totalOrders': 0,
        'completedOrders': 0,
        'cancelledOrders': 0,
        'earnings': 0.0,
        'currentOrders': [],
        'orderHistory': [],
        'workshopLocation': workshopLocation ?? '',
        'hourlyRate': hourlyRate,
        'shift': shift ?? 'morning',
        'documents': {
          'identity': {
            'verified': false,
          }
        },
        'bankDetails': {},
        'address': {},
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'createdBy': createdByUid ?? 'admin',
        'createdByRole': 'admin',
      };

      // Add optional fields only if provided
      if (email != null && email.isNotEmpty) {
        workerData['email'] = email.toLowerCase();
      }
      
      if (aadharNumber != null && aadharNumber.isNotEmpty) {
        workerData['aadharNumber'] = aadharNumber;
      }
      
      if (aadharCardUrl != null) {
        workerData['aadharCardUrl'] = aadharCardUrl;
      }

      // Save to Firestore
      await _firestore.collection('workshop_workers').doc(workerId).set(workerData);
      
      print('✅ Workshop worker created successfully with ID: $workerId');
      
      // Return the created workshop worker
      return WorkshopWorkerModel.fromMap(workerData);
      
    } catch (e) {
      print('❌ Error creating workshop worker: $e');
      throw Exception('Failed to create workshop worker: ${e.toString()}');
    }
  }

  // Check if phone number is available
  Future<bool> isPhoneNumberAvailable(String phoneNumber) async {
    try {
      String formattedPhone = phoneNumber.startsWith('+') ? phoneNumber : '+91$phoneNumber';
      
      // Check in workshop_workers collection
      final workerQuery = await _firestore
          .collection('workshop_workers')
          .where('phoneNumber', isEqualTo: formattedPhone)
          .limit(1)
          .get();
          
      // Also check in delivery collection to avoid conflicts
      final deliveryQuery = await _firestore
          .collection('delivery')
          .where('phoneNumber', isEqualTo: formattedPhone)
          .limit(1)
          .get();
      
      return workerQuery.docs.isEmpty && deliveryQuery.docs.isEmpty;
    } catch (e) {
      print('Error checking phone availability: $e');
      // Return false to prevent duplicate creation on error
      return false;
    }
  }

  // Check if email is available
  Future<bool> isEmailAvailable(String email) async {
    try {
      String lowerEmail = email.toLowerCase();
      
      // Check in workshop_workers collection
      final workerQuery = await _firestore
          .collection('workshop_workers')
          .where('email', isEqualTo: lowerEmail)
          .limit(1)
          .get();
          
      // Also check in delivery collection to avoid conflicts
      final deliveryQuery = await _firestore
          .collection('delivery')
          .where('email', isEqualTo: lowerEmail)
          .limit(1)
          .get();
      
      return workerQuery.docs.isEmpty && deliveryQuery.docs.isEmpty;
    } catch (e) {
      print('Error checking email availability: $e');
      // Return false to prevent duplicate creation on error
      return false;
    }
  }

  // Check if employee ID is available
  Future<bool> isEmployeeIdAvailable(String employeeId) async {
    try {
      String upperEmployeeId = employeeId.toUpperCase();
      
      // Check in workshop_workers collection
      final workerQuery = await _firestore
          .collection('workshop_workers')
          .where('employeeId', isEqualTo: upperEmployeeId)
          .limit(1)
          .get();
      
      return workerQuery.docs.isEmpty;
    } catch (e) {
      print('Error checking employee ID availability: $e');
      // Return false to prevent duplicate creation on error
      return false;
    }
  }

  // Get all workshop workers (alias for better naming)
  Stream<List<WorkshopWorkerModel>> getAllWorkshopWorkersStream() {
    return getWorkshopWorkers();
  }

  // Get all workshop workers
  Stream<List<WorkshopWorkerModel>> getWorkshopWorkers() {
    return _firestore
        .collection('workshop_workers')
        .where('isDeleted', isNotEqualTo: true)
        .orderBy('isDeleted')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => WorkshopWorkerModel.fromMap({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    }).handleError((error) {
      print('Error in workshop workers stream: $error');
      return <WorkshopWorkerModel>[];
    });
  }

  // Get active workshop workers
  Stream<List<WorkshopWorkerModel>> getActiveWorkshopWorkers() {
    return _firestore
        .collection('workshop_workers')
        .where('isActive', isEqualTo: true)
        .where('isDeleted', isNotEqualTo: true)
        .orderBy('isDeleted')
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => WorkshopWorkerModel.fromMap({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    }).handleError((error) {
      print('Error in active workshop workers stream: $error');
      return <WorkshopWorkerModel>[];
    });
  }

  // Get workshop worker by ID
  Future<WorkshopWorkerModel?> getWorkshopWorkerById(String id) async {
    try {
      final doc = await _firestore.collection('workshop_workers').doc(id).get();
      if (doc.exists && doc.data() != null) {
        return WorkshopWorkerModel.fromMap({
          ...doc.data()!,
          'id': doc.id,
        });
      }
      return null;
    } catch (e) {
      print('Error getting workshop worker: $e');
      return null;
    }
  }

  // Update workshop worker
  Future<bool> updateWorkshopWorker(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('workshop_workers').doc(id).update({
        ...data,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('Error updating workshop worker: $e');
      return false;
    }
  }

  // Get workshop workers by skill
  Stream<List<WorkshopWorkerModel>> getWorkshopWorkersBySkill(String skill) {
    return _firestore
        .collection('workshop_workers')
        .where('isActive', isEqualTo: true)
        .where('skills', arrayContains: skill)
        .orderBy('rating', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => WorkshopWorkerModel.fromMap({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    }).handleError((error) {
      print('Error in workshop workers by skill stream: $error');
      return <WorkshopWorkerModel>[];
    });
  }

  // Get workshop workers by shift
  Stream<List<WorkshopWorkerModel>> getWorkshopWorkersByShift(String shift) {
    return _firestore
        .collection('workshop_workers')
        .where('isActive', isEqualTo: true)
        .where('shift', isEqualTo: shift)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => WorkshopWorkerModel.fromMap({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    }).handleError((error) {
      print('Error in workshop workers by shift stream: $error');
      return <WorkshopWorkerModel>[];
    });
  }

  // Get workshop worker by phone number (for login)
  Future<WorkshopWorkerModel?> getWorkshopWorkerByPhone(String phoneNumber) async {
    try {
      String formattedPhone = phoneNumber.startsWith('+') ? phoneNumber : '+91$phoneNumber';
      
      final querySnapshot = await _firestore
          .collection('workshop_workers')
          .where('phoneNumber', isEqualTo: formattedPhone)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return WorkshopWorkerModel.fromMap({
          ...querySnapshot.docs.first.data(),
          'id': querySnapshot.docs.first.id,
        });
      }
      return null;
    } catch (e) {
      print('Error getting workshop worker by phone: $e');
      return null;
    }
  }

  // Update workshop worker earnings
  Future<bool> updateWorkerEarnings(String workerId, double additionalEarnings) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('workshop_workers').doc(workerId).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        double currentEarnings = (data['earnings'] ?? 0.0).toDouble();
        
        await _firestore.collection('workshop_workers').doc(workerId).update({
          'earnings': currentEarnings + additionalEarnings,
          'updatedAt': Timestamp.now(),
        });
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating worker earnings: $e');
      return false;
    }
  }

  // Increment order count for workshop worker
  Future<bool> incrementWorkerOrderCount(String workerId, bool isCompleted) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('workshop_workers').doc(workerId).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        int totalOrders = (data['totalOrders'] ?? 0) + 1;
        int completedOrders = (data['completedOrders'] ?? 0) + (isCompleted ? 1 : 0);
        
        await _firestore.collection('workshop_workers').doc(workerId).update({
          'totalOrders': totalOrders,
          'completedOrders': completedOrders,
          'updatedAt': Timestamp.now(),
        });
        return true;
      }
      return false;
    } catch (e) {
      print('Error incrementing worker order count: $e');
      return false;
    }
  }
} 