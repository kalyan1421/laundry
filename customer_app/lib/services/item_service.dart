import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/item_model.dart';

class ItemService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'items';

  Future<List<ItemModel>> getItems({String? category}) async {
    print('[ItemService] getItems called. Category: ${category ?? 'all'}.');
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection(_collectionPath)
          .where('isActive', isEqualTo: true);
      print('[ItemService] Base query created for collection: $_collectionPath, where isActive is true.');

      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
        print('[ItemService] Added category filter: $category');
      }

      // Define orderBy clauses based on whether a category filter is applied
      if (category != null && category.isNotEmpty) {
        query = query.orderBy('sortOrder').orderBy('name');
        print('[ItemService] Ordering by sortOrder, then name (for specific category).');
      } else {
        query = query.orderBy('category').orderBy('sortOrder').orderBy('name');
        print('[ItemService] Ordering by category, sortOrder, then name (for all items).');
      }
      
      print('[ItemService] Executing Firestore query...');
      final QuerySnapshot<Map<String, dynamic>> itemSnapshot = await query.get();
      print('[ItemService] Firestore query executed. Number of documents received: ${itemSnapshot.docs.length}');

      if (itemSnapshot.docs.isEmpty) {
        print('[ItemService] No documents returned from Firestore for the current query.');
        return [];
      }

      List<ItemModel> items = itemSnapshot.docs.map((doc) {
        print('[ItemService] Mapping document ID: ${doc.id}, Data: ${doc.data()}');
        return ItemModel.fromFirestore(doc);
      }).toList();
      print('[ItemService] Successfully mapped ${items.length} documents to ItemModels.');
      return items;

    } catch (e, stackTrace) {
      print('[ItemService] Error fetching items: $e');
      print('[ItemService] Stack trace: $stackTrace');
      // Check for Firestore index errors specifically
      if (e.toString().toLowerCase().contains('index')) {
          print('[ItemService] POTENTIAL FIRESTORE INDEXING ISSUE DETECTED. The query might require a custom index in Firestore. Check the Firebase console for index creation links or error messages related to indexes.');
      }
      return []; // Return empty list on error as per original logic
    }
  }

  Future<Map<String, List<ItemModel>>> getItemsGroupedByCategory() async {
    print('[ItemService] getItemsGroupedByCategory called.');
    try {
      // This now uses the enhanced getItems method which has its own logging
      final List<ItemModel> allItems = await getItems(); 
      print('[ItemService] getItemsGroupedByCategory: Fetched ${allItems.length} total items for grouping.');
      
      if (allItems.isEmpty) {
        print('[ItemService] getItemsGroupedByCategory: No items to group.');
        return {};
      }

      final Map<String, List<ItemModel>> groupedItems = {};
      for (var item in allItems) {
        if (groupedItems.containsKey(item.category)) {
          groupedItems[item.category]!.add(item);
        } else {
          groupedItems[item.category] = [item];
        }
      }
      print('[ItemService] getItemsGroupedByCategory: Grouped items into ${groupedItems.keys.length} categories.');
      return groupedItems;
    } catch (e, stackTrace) {
      print('[ItemService] Error fetching and grouping items: $e');
      print('[ItemService] Stack trace for grouping error: $stackTrace');
      return {};
    }
  }

  // Optional: Stream-based methods if real-time updates are needed.
  // Stream<List<ItemModel>> getItemsStream({String? category}) { ... }
  // Stream<Map<String, List<ItemModel>>> getItemsGroupedByCategoryStream() { ... }
} 