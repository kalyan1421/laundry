// models/banner_model.dart
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
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory BannerModel.fromMap(Map<String, dynamic> map, String id) {
    return BannerModel(
      id: id,
      imageUrl: map['imageUrl'] ?? '',
      order: map['order'] as int? ?? 0,
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] as Timestamp?,
      updatedAt: map['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'order': order,
      'isActive': isActive,
      'createdAt': createdAt ?? Timestamp.now(),
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }
}