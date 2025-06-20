import 'package:cloud_firestore/cloud_firestore.dart';

class AdminTokenService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if there are any admin tokens available for notifications
  Future<List<String>> getAvailableAdminTokens() async {
    try {
      QuerySnapshot adminSnapshot = await _firestore
          .collection('admins')
          .where('isActive', isEqualTo: true)
          .get();

      List<String> tokens = [];
      for (QueryDocumentSnapshot doc in adminSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String? token = data['fcmToken'];
        if (token != null && token.isNotEmpty) {
          tokens.add(token);
        }
      }

      print('Found ${tokens.length} admin tokens available for notifications');
      return tokens;
    } catch (e) {
      print('Error getting admin tokens: $e');
      return [];
    }
  }

  /// Get admin tokens with additional info for debugging
  Future<List<Map<String, dynamic>>> getAdminTokensWithInfo() async {
    try {
      QuerySnapshot adminSnapshot = await _firestore
          .collection('admins')
          .where('isActive', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> adminTokenInfo = [];
      for (QueryDocumentSnapshot doc in adminSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        adminTokenInfo.add({
          'adminId': doc.id,
          'name': data['name'] ?? 'Unknown',
          'phoneNumber': data['phoneNumber'] ?? 'Unknown',
          'hasToken': data['fcmToken'] != null && data['fcmToken'].toString().isNotEmpty,
          'fcmToken': data['fcmToken'] != null ? '${data['fcmToken'].toString().substring(0, 20)}...' : 'None',
          'lastUpdated': data['updatedAt'],
        });
      }

      print('Admin token info: $adminTokenInfo');
      return adminTokenInfo;
    } catch (e) {
      print('Error getting admin token info: $e');
      return [];
    }
  }

  /// Create default admin token if none exist (for testing)
  Future<void> ensureAdminTokensExist() async {
    try {
      List<String> tokens = await getAvailableAdminTokens();
      if (tokens.isEmpty) {
        print('No admin tokens found. Checking for admins without tokens...');
        
        QuerySnapshot adminSnapshot = await _firestore
            .collection('admins')
            .where('isActive', isEqualTo: true)
            .get();

        if (adminSnapshot.docs.isEmpty) {
          print('No active admins found. Cannot create default tokens.');
          return;
        }

        for (QueryDocumentSnapshot doc in adminSnapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String? token = data['fcmToken'];
          
          if (token == null || token.isEmpty) {
            print('Admin ${doc.id} (${data['name']}) has no FCM token. '
                  'They need to log in to the admin app to register their token.');
          }
        }
      }
    } catch (e) {
      print('Error ensuring admin tokens exist: $e');
    }
  }
} 