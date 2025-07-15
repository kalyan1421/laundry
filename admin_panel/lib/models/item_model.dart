// models/item_model.dart
class ItemModel {
  final String id;
  final String name;
  final double price;
  final double? originalPrice; // Added original price field
  final double? offerPrice; // Added offer price field
  final String category;
  final String unit;
  final bool isActive;
  final DateTime updatedAt;
  final String? imageUrl; // Added image URL field
  final int sortOrder;

  ItemModel({
    required this.id,
    required this.name,
    required this.price,
    this.originalPrice, // Optional original price
    this.offerPrice, // Optional offer price
    required this.category,
    required this.unit,
    required this.isActive,
    required this.updatedAt,
    this.imageUrl, // Optional image URL
    this.sortOrder = 0,
  });

  // Create ItemModel from Firestore document
  factory ItemModel.fromMap(String id, Map<String, dynamic> map) {
    return ItemModel(
      id: id,
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      originalPrice: map['originalPrice'] != null ? (map['originalPrice'] as num).toDouble() : null,
      offerPrice: map['offerPrice'] != null ? (map['offerPrice'] as num).toDouble() : null,
      category: map['category'] ?? '',
      unit: map['unit'] ?? 'piece',
      isActive: map['isActive'] ?? true,
      updatedAt: map['updatedAt']?.toDate() ?? DateTime.now(),
      imageUrl: map['imageUrl'], // Get image URL from Firestore
      sortOrder: map['sortOrder'] ?? 0,
    );
  }

  // Convert ItemModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      if (originalPrice != null) 'originalPrice': originalPrice,
      if (offerPrice != null) 'offerPrice': offerPrice,
      'category': category,
      'unit': unit,
      'isActive': isActive,
      'updatedAt': updatedAt,
      'sortOrder': sortOrder,
      if (imageUrl != null) 'imageUrl': imageUrl, // Include image URL if exists
    };
  }

  // Create a copy of ItemModel with updated fields
  ItemModel copyWith({
    String? id,
    String? name,
    double? price,
    double? originalPrice,
    double? offerPrice,
    String? category,
    String? unit,
    bool? isActive,
    DateTime? updatedAt,
    String? imageUrl,
    int? sortOrder,
  }) {
    return ItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      offerPrice: offerPrice ?? this.offerPrice,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
      imageUrl: imageUrl ?? this.imageUrl,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  String toString() {
    return 'ItemModel(id: $id, name: $name, price: $price, originalPrice: $originalPrice, offerPrice: $offerPrice, category: $category, unit: $unit, isActive: $isActive, imageUrl: $imageUrl, sortOrder: $sortOrder)';
  }
}