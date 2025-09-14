import 'package:cloud_firestore/cloud_firestore.dart';

class ItemModel {
  final String id;
  final String name;
  final String category; // e.g., 'ironing', 'washAndFold', 'dryCleaning'
  final double pricePerPiece;
  final double? offerPrice; // Added offer price field
  final String unit; // e.g., 'piece', 'kg', 'set'
  final String? imageUrl;
  final String? iconUrl;
  final String? description;
  final bool isActive;
  final int order; // For display order within a category or globally
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  ItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.pricePerPiece,
    this.offerPrice, // Optional offer price
    required this.unit,
    this.imageUrl,
    this.iconUrl,
    this.description,
    required this.isActive,
    required this.order,
    this.createdAt,
    this.updatedAt,
  });

  factory ItemModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    Map<String, dynamic> data = doc.data()!;
    return ItemModel(
      id: doc.id,
      name: data['name'] as String? ?? 'Unnamed Item',
      category: data['category'] as String? ?? 'uncategorized',
      pricePerPiece: (data['price'] as num?)?.toDouble() ?? (data['pricePerPiece'] as num?)?.toDouble() ?? 0.0,
      offerPrice: data['offerPrice'] != null ? (data['offerPrice'] as num).toDouble() : null,
      unit: data['unit'] as String? ?? 'piece',
      imageUrl: data['imageUrl'] as String?,
      iconUrl: data['iconUrl'] as String?,
      description: data['description'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      order: data['sortOrder'] as int? ?? data['order'] as int? ?? 0,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category,
      'price': pricePerPiece, // Consistent with screenshot field name 'price'
      'unit': unit,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (iconUrl != null) 'iconUrl': iconUrl,
      if (description != null) 'description': description,
      'isActive': isActive,
      'sortOrder': order,
      if (createdAt != null) 'createdAt': createdAt,
      // 'updatedAt' is usually handled by server-side timestamp or Firestore console.
      // If you need to set it from client, add: 'updatedAt': FieldValue.serverTimestamp() on write
    };
  }
}
