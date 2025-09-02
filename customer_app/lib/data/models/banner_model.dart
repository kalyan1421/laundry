import 'package:cloud_firestore/cloud_firestore.dart';

class BannerModel {
  final String id;
  final String imageUrl;
  final int order;
  final bool isActive;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  BannerModel({
    required this.id,
    required this.imageUrl,
    required this.order,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory BannerModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    Map<String, dynamic> data = doc.data()!;
    return BannerModel(
      id: doc.id,
      imageUrl: data['imageUrl'] as String? ?? '',
      order: data['order'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'imageUrl': imageUrl,
      'order': order,
      'isActive': isActive,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt, 
    };
  }
}
