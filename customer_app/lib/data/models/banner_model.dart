import 'package:cloud_firestore/cloud_firestore.dart';

class BannerModel {
  final String id;
  final String imageUrl;
  final String? title; // Corresponds to mainTagline from admin
  final String? subtitle; // Corresponds to subTagline from admin
  final String? description;
  final String? promoText;
  final String? actionType;
  final String? actionValue;
  final int order;
  final bool isActive;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  BannerModel({
    required this.id,
    required this.imageUrl,
    this.title,
    this.subtitle,
    this.description,
    this.promoText,
    this.actionType,
    this.actionValue,
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
      // Map mainTagline from Firestore to title, and subTagline to subtitle
      title: data['mainTagline'] as String? ?? data['title'] as String?, // Prioritize mainTagline if present
      subtitle: data['subTagline'] as String? ?? data['subtitle'] as String?,
      description: data['description'] as String?,
      promoText: data['promoText'] as String?,
      actionType: data['actionType'] as String?,
      actionValue: data['actionValue'] as String?,
      order: data['order'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'imageUrl': imageUrl,
      // When saving from customer app (if ever), it would use these names.
      // Admin panel saves as mainTagline/subTagline.
      // This mapping is primarily for reading.
      if (title != null) 'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      if (description != null) 'description': description,
      if (promoText != null) 'promoText': promoText,
      if (actionType != null) 'actionType': actionType,
      if (actionValue != null) 'actionValue': actionValue,
      'order': order,
      'isActive': isActive,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt, 
    };
  }
}
