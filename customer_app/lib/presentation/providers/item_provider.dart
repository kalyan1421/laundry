import 'package:flutter/foundation.dart';
import '../../data/models/item_model.dart';
import '../../services/item_service.dart';

class ItemProvider with ChangeNotifier {
  final ItemService _itemService = ItemService();

  List<ItemModel> _items = [];
  Map<String, List<ItemModel>> _itemsGroupedByCategory = {};
  bool _isLoading = false;
  String? _error;

  List<ItemModel> get items => _items;
  Map<String, List<ItemModel>> get itemsGroupedByCategory => _itemsGroupedByCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ItemProvider() {
    loadAllItemData();
  }

  Future<void> loadAllItemData() async {
    if (_isLoading) return; // Prevent concurrent loads

    _isLoading = true;
    _error = null;
    notifyListeners(); // Indicate loading has started

    try {
      final allFetchedItems = await _itemService.getItems();
      _items = allFetchedItems; // Store the raw list
      _itemsGroupedByCategory = _groupItems(allFetchedItems); // Group items

      if (_items.isEmpty) {
        print("ItemProvider: No active items fetched from the service, or the item list is empty.");
        // The UI (HomeScreen) will handle displaying "No items" if _itemsGroupedByCategory is empty.
      } else {
        print("ItemProvider: Successfully fetched ${_items.length} items.");
        if (_itemsGroupedByCategory.isEmpty) {
          print("ItemProvider: Items were fetched, but categories are empty after grouping. Check item 'category' fields.");
        } else {
          print("ItemProvider: Items grouped into ${_itemsGroupedByCategory.keys.length} categories.");
        }
      }

    } catch (e) {
      _error = e.toString();
      _items = []; // Clear data on error
      _itemsGroupedByCategory = {}; // Clear data on error
      print('Error in ItemProvider loading all item data: $_error');
    } finally {
      _isLoading = false;
      notifyListeners(); // Indicate loading finished (successfully or with error)
    }
  }

  Map<String, List<ItemModel>> _groupItems(List<ItemModel> itemsToGroup) {
    final Map<String, List<ItemModel>> grouped = {};
    for (var item in itemsToGroup) {
      if (item.category.isEmpty) {
        print("ItemProvider: Item '${item.name}' (ID: ${item.id}) has an empty category string. It will be ignored for grouping by category.");
        continue; // Skip items with empty category strings if you don't want an 'empty' category
      }
      if (grouped.containsKey(item.category)) {
        grouped[item.category]!.add(item);
      } else {
        grouped[item.category] = [item];
      }
    }
    return grouped;
  }

  // Removed old fetchAllItems and fetchItemsGroupedByCategory methods
  // as loadAllItemData now handles the combined loading logic.
  // If specific refresh functionalities are needed later, they can be added.

  // Example of fetching for a specific category if needed later (kept from original for reference if you extend)
  // This would need to be adapted if you want it to update provider state
  Future<List<ItemModel>> getItemsForCategory(String category) async {
    try {
      // This call to _itemService.getItems is filtered by category
      return await _itemService.getItems(category: category);
    } catch (e) {
      print('Error fetching items for category $category: $e');
      return [];
    }
  }
}
