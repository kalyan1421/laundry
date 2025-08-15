import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class CustomerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Cache to avoid repeated fetches
  final Map<String, UserModel> _customerCache = {};
  
  /// Fetch customer details by customer ID
  Future<UserModel?> getCustomerById(String customerId) async {
    try {
      // Check cache first
      if (_customerCache.containsKey(customerId)) {
        print('🧑‍💼 CustomerService: Using cached customer data for: $customerId');
        return _customerCache[customerId];
      }
      
      print('🧑‍💼 CustomerService: Fetching customer data for: $customerId');
      
      final customerDoc = await _firestore
          .collection('customer')
          .doc(customerId)
          .get();
      
      if (customerDoc.exists && customerDoc.data() != null) {
        final customerData = customerDoc.data()!;
        print('🧑‍💼 CustomerService: Customer found - Name: ${customerData['name']}, Phone: ${customerData['phoneNumber']}');
        print('🧑‍💼 CustomerService: Customer email: ${customerData['email']}');
        print('🧑‍💼 CustomerService: Profile complete: ${customerData['isProfileComplete']}');
        
        final customer = UserModel.fromMap(customerData, documentId: customerId);
        
        // Cache the customer data
        _customerCache[customerId] = customer;
        
        return customer;
      } else {
        print('🧑‍💼 ❌ CustomerService: Customer not found: $customerId');
        return null;
      }
    } catch (e) {
      print('🧑‍💼 ❌ CustomerService: Error fetching customer $customerId: $e');
      return null;
    }
  }
  
  /// Fetch multiple customers by their IDs
  Future<Map<String, UserModel>> getCustomersByIds(List<String> customerIds) async {
    final Map<String, UserModel> customers = {};
    
    // Remove duplicates and check cache first
    final uniqueIds = customerIds.toSet().toList();
    final idsToFetch = <String>[];
    
    for (final id in uniqueIds) {
      if (_customerCache.containsKey(id)) {
        customers[id] = _customerCache[id]!;
      } else {
        idsToFetch.add(id);
      }
    }
    
    if (idsToFetch.isEmpty) {
      print('🧑‍💼 CustomerService: All ${uniqueIds.length} customers found in cache');
      return customers;
    }
    
    print('🧑‍💼 CustomerService: Fetching ${idsToFetch.length} customers from Firestore');
    
    try {
      // Firestore 'in' queries are limited to 10 items, so batch them
      const batchSize = 10;
      for (int i = 0; i < idsToFetch.length; i += batchSize) {
        final batch = idsToFetch.skip(i).take(batchSize).toList();
        
        final querySnapshot = await _firestore
            .collection('customer')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        
        for (final doc in querySnapshot.docs) {
          if (doc.exists && doc.data().isNotEmpty) {
            final customer = UserModel.fromMap(doc.data(), documentId: doc.id);
            customers[doc.id] = customer;
            _customerCache[doc.id] = customer; // Cache it
            
            print('🧑‍💼 CustomerService: Fetched customer ${doc.id} - ${customer.name}');
          }
        }
      }
      
      print('🧑‍💼 CustomerService: Successfully fetched ${customers.length}/${uniqueIds.length} customers');
      return customers;
    } catch (e) {
      print('🧑‍💼 ❌ CustomerService: Error fetching customers: $e');
      return customers; // Return whatever we managed to get
    }
  }
  
  /// Clear the customer cache
  void clearCache() {
    _customerCache.clear();
    print('🧑‍💼 CustomerService: Cache cleared');
  }
  
  /// Fetch customer addresses by customer ID
  Future<List<Map<String, dynamic>>> getCustomerAddresses(String customerId) async {
    try {
      print('🧑‍💼 CustomerService: Fetching addresses for customer: $customerId');
      
      final addressesSnapshot = await _firestore
          .collection('customer')
          .doc(customerId)
          .collection('addresses')
          .get();
      
      final addresses = addressesSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Add document ID
        return data;
      }).toList();
      
      print('🧑‍💼 CustomerService: Found ${addresses.length} addresses for customer: $customerId');
      return addresses;
    } catch (e) {
      print('🧑‍💼 ❌ CustomerService: Error fetching addresses for $customerId: $e');
      return [];
    }
  }

  /// Get complete customer information including addresses
  Future<Map<String, dynamic>?> getCompleteCustomerInfo(String customerId) async {
    try {
      print('🧑‍💼 CustomerService: Fetching complete info for customer: $customerId');
      
      // Get customer basic information
      final customer = await getCustomerById(customerId);
      if (customer == null) {
        print('🧑‍💼 ❌ CustomerService: Customer not found: $customerId');
        return null;
      }
      
      // Get customer addresses
      final addresses = await getCustomerAddresses(customerId);
      
      // Combine all information
      final completeInfo = {
        'customer': customer.toMap(),
        'addresses': addresses,
        'totalAddresses': addresses.length,
        'fetchedAt': DateTime.now().toIso8601String(),
      };
      
      print('🧑‍💼 ✅ CustomerService: Complete info fetched for ${customer.name} with ${addresses.length} addresses');
      return completeInfo;
    } catch (e) {
      print('🧑‍💼 ❌ CustomerService: Error fetching complete info for $customerId: $e');
      return null;
    }
  }
  
  /// Get cache size for debugging
  int get cacheSize => _customerCache.length;
}
