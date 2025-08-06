// debug_firebase_permissions.dart
// Run this script to debug Firebase permissions and create phone index

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';

void main() async {
  await Firebase.initializeApp(
    // options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final firestore = FirebaseFirestore.instance;
  print('🔍 Starting Firebase permission debug...');
  
  // Test 1: Check if we can read delivery_phone_index collection
  try {
    print('\n📞 Testing delivery_phone_index read permission...');
    final snapshot = await firestore.collection('delivery_phone_index').limit(1).get();
    print('✅ Successfully read delivery_phone_index collection');
    print('📊 Found ${snapshot.docs.length} documents');
  } catch (e) {
    print('❌ Failed to read delivery_phone_index: $e');
  }
  
  // Test 2: Check if we can read delivery collection
  try {
    print('\n🚚 Testing delivery collection read permission...');
    final snapshot = await firestore.collection('delivery').limit(1).get();
    print('✅ Successfully read delivery collection');
    print('📊 Found ${snapshot.docs.length} documents');
  } catch (e) {
    print('❌ Failed to read delivery collection: $e');
  }
  
  // Test 3: Try to read a specific phone index entry
  try {
    print('\n🔍 Testing specific phone index lookup...');
    final doc = await firestore.collection('delivery_phone_index').doc('919063290001').get();
    if (doc.exists) {
      print('✅ Found phone index entry: ${doc.data()}');
    } else {
      print('⚠️ Phone index entry does not exist for 919063290001');
    }
  } catch (e) {
    print('❌ Failed to read specific phone index: $e');
  }
  
  // Test 4: List all delivery partners to see what phone numbers exist
  try {
    print('\n📋 Listing all delivery partners...');
    final snapshot = await firestore.collection('delivery').get();
    print('📊 Found ${snapshot.docs.length} delivery partners:');
    
    for (var doc in snapshot.docs) {
      final data = doc.data();
      print('  - ID: ${doc.id}');
      print('    Name: ${data['name'] ?? 'N/A'}');
      print('    Phone: ${data['phoneNumber'] ?? 'N/A'}');
      print('    Active: ${data['isActive'] ?? false}');
      print('    UID: ${data['uid'] ?? 'N/A'}');
      print('');
    }
  } catch (e) {
    print('❌ Failed to list delivery partners: $e');
  }
  
  print('\n🔧 Debug complete!');
}
