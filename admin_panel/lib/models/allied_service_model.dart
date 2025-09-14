// models/allied_service_model.dart
class AlliedServiceModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? offerPrice; // Optional offer price
  final String category; // Main category: "Allied Services"
  final String subCategory; // Subcategory: "Allied Services", "Laundry", "Special Services"
  final String unit;
  final bool isActive;
  final bool hasPrice; // Some services might not have fixed price
  final DateTime updatedAt;
  final String? imageUrl; // Optional image URL
  final int sortOrder;
  final String? iconName; // Store icon name as string

  AlliedServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.offerPrice,
    required this.category,
    required this.subCategory,
    required this.unit,
    required this.isActive,
    required this.hasPrice,
    required this.updatedAt,
    this.imageUrl,
    this.sortOrder = 0,
    this.iconName,
  });

  // Create AlliedServiceModel from Firestore document
  factory AlliedServiceModel.fromMap(String id, Map<String, dynamic> map) {
    return AlliedServiceModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      offerPrice: map['offerPrice'] != null ? (map['offerPrice'] as num).toDouble() : null,
      category: map['category'] ?? 'Allied Services',
      subCategory: map['subCategory'] ?? 'Allied Services',
      unit: map['unit'] ?? 'piece',
      isActive: map['isActive'] ?? true,
      hasPrice: map['hasPrice'] ?? true,
      updatedAt: map['updatedAt']?.toDate() ?? DateTime.now(),
      imageUrl: map['imageUrl'],
      sortOrder: map['sortOrder'] ?? 0,
      iconName: map['iconName'],
    );
  }

  // Convert AlliedServiceModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      if (offerPrice != null) 'offerPrice': offerPrice,
      'category': category,
      'subCategory': subCategory,
      'unit': unit,
      'isActive': isActive,
      'hasPrice': hasPrice,
      'updatedAt': updatedAt,
      'sortOrder': sortOrder,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (iconName != null) 'iconName': iconName,
    };
  }

  // Create a copy of AlliedServiceModel with updated fields
  AlliedServiceModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? offerPrice,
    String? category,
    String? subCategory,
    String? unit,
    bool? isActive,
    bool? hasPrice,
    DateTime? updatedAt,
    String? imageUrl,
    int? sortOrder,
    String? iconName,
  }) {
    return AlliedServiceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      offerPrice: offerPrice ?? this.offerPrice,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      unit: unit ?? this.unit,
      isActive: isActive ?? this.isActive,
      hasPrice: hasPrice ?? this.hasPrice,
      updatedAt: updatedAt ?? this.updatedAt,
      imageUrl: imageUrl ?? this.imageUrl,
      sortOrder: sortOrder ?? this.sortOrder,
      iconName: iconName ?? this.iconName,
    );
  }

  @override
  String toString() {
    return 'AlliedServiceModel{id: $id, name: $name, description: $description, price: $price, category: $category, unit: $unit, isActive: $isActive, hasPrice: $hasPrice}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AlliedServiceModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}