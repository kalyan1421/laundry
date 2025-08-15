import 'package:cloud_firestore/cloud_firestore.dart';

class ItemService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Cache to avoid repeated fetches
  final Map<String, Map<String, dynamic>> _itemCache = {};
  
  /// Fetch item details by item ID
  Future<Map<String, dynamic>?> getItemById(String itemId) async {
    try {
      // Check cache first
      if (_itemCache.containsKey(itemId)) {
        print('🏷️ ItemService: Using cached item data for: $itemId');
        return _itemCache[itemId];
      }
      
      print('🏷️ ItemService: Fetching item data for: $itemId');
      
      final itemDoc = await _firestore
          .collection('items')
          .doc(itemId)
          .get();
      
      if (itemDoc.exists && itemDoc.data() != null) {
        final itemData = itemDoc.data()!;
        print('🏷️ ItemService: Item found - Name: ${itemData['name']}, Price: ${itemData['price']}');
        
        // Add document ID to the data
        itemData['id'] = itemDoc.id;
        
        // Cache the item data
        _itemCache[itemId] = itemData;
        
        return itemData;
      } else {
        print('🏷️ ❌ ItemService: Item not found: $itemId');
        return null;
      }
    } catch (e) {
      print('🏷️ ❌ ItemService: Error fetching item $itemId: $e');
      return null;
    }
  }
  
  /// Fetch multiple items by their IDs
  Future<Map<String, Map<String, dynamic>>> getItemsByIds(List<String> itemIds) async {
    final Map<String, Map<String, dynamic>> items = {};
    
    // Remove duplicates and check cache first
    final uniqueIds = itemIds.toSet().toList();
    final idsToFetch = <String>[];
    
    for (final id in uniqueIds) {
      if (_itemCache.containsKey(id)) {
        items[id] = _itemCache[id]!;
      } else {
        idsToFetch.add(id);
      }
    }
    
    if (idsToFetch.isEmpty) {
      print('🏷️ ItemService: All ${uniqueIds.length} items found in cache');
      return items;
    }
    
    print('🏷️ ItemService: Fetching ${idsToFetch.length} items from Firestore');
    
    try {
      // Firestore 'in' queries are limited to 10 items, so batch them
      const batchSize = 10;
      for (int i = 0; i < idsToFetch.length; i += batchSize) {
        final batch = idsToFetch.skip(i).take(batchSize).toList();
        
        final querySnapshot = await _firestore
            .collection('items')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        
        for (final doc in querySnapshot.docs) {
          if (doc.exists && doc.data().isNotEmpty) {
            final itemData = doc.data();
            itemData['id'] = doc.id; // Add document ID
            
            items[doc.id] = itemData;
            _itemCache[doc.id] = itemData; // Cache it
            
            print('🏷️ ItemService: Fetched item ${doc.id} - ${itemData['name']}');
          }
        }
      }
      
      print('🏷️ ItemService: Successfully fetched ${items.length}/${uniqueIds.length} items');
      return items;
    } catch (e) {
      print('🏷️ ❌ ItemService: Error fetching items: $e');
      return items; // Return whatever we managed to get
    }
  }
  
  /// Search items by name (for autocomplete/search functionality)
  Future<List<Map<String, dynamic>>> searchItemsByName(String searchTerm) async {
    try {
      if (searchTerm.isEmpty) return [];
      
      print('🏷️ ItemService: Searching items with term: $searchTerm');
      
      final querySnapshot = await _firestore
          .collection('items')
          .where('name', isGreaterThanOrEqualTo: searchTerm)
          .where('name', isLessThanOrEqualTo: searchTerm + '\uf8ff')
          .limit(20)
          .get();
      
      final items = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      print('🏷️ ItemService: Found ${items.length} items matching: $searchTerm');
      return items;
    } catch (e) {
      print('🏷️ ❌ ItemService: Error searching items: $e');
      return [];
    }
  }
  
  /// Get all items (for dropdown/selection lists)
  Future<List<Map<String, dynamic>>> getAllItems() async {
    try {
      print('🏷️ ItemService: Fetching all items');
      
      final querySnapshot = await _firestore
          .collection('items')
          .orderBy('name')
          .get();
      
      final items = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        
        // Cache each item
        _itemCache[doc.id] = data;
        
        return data;
      }).toList();
      
      print('🏷️ ItemService: Fetched ${items.length} total items');
      return items;
    } catch (e) {
      print('🏷️ ❌ ItemService: Error fetching all items: $e');
      return [];
    }
  }
  
  /// Clear the item cache
  void clearCache() {
    _itemCache.clear();
    print('🏷️ ItemService: Cache cleared');
  }
  
  /// Get cache size for debugging
  int get cacheSize => _itemCache.length;
}
