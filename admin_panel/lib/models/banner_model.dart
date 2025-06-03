// models/banner_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class BannerModel {
  final String id;
  final String imageUrl;
  final String mainTagline;
  final String subTagline;
  final Timestamp? createdAt;

  BannerModel({
    required this.id,
    required this.imageUrl,
    required this.mainTagline,
    required this.subTagline,
    this.createdAt,
  });

  factory BannerModel.fromMap(Map<String, dynamic> map, String id) {
    return BannerModel(
      id: id,
      imageUrl: map['imageUrl'] ?? '',
      mainTagline: map['mainTagline'] ?? '',
      subTagline: map['subTagline'] ?? '',
      createdAt: map['createdAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'mainTagline': mainTagline,
      'subTagline': subTagline,
      'createdAt': createdAt ?? Timestamp.now(),
    };
  }
}