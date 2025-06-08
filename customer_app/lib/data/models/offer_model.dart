import 'package:cloud_firestore/cloud_firestore.dart';

class OfferModel {
  final String id;
  final String title;
  final String description;
  final String? imageUrl; // Optional image for the offer
  final double? discountPercentage; // e.g., 0.10 for 10%
  final double? discountAmount; // e.g., 50 for ₹50 off
  final String? couponCode; // Optional coupon code to apply
  final Timestamp? validFrom;
  final Timestamp? validTo;
  final String? termsAndConditions;
  final bool isActive;
  final int order; // To control display order
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  // Potential future fields: minOrderAmount, applicableToItems (List<String> itemIds/category)

  OfferModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.discountPercentage,
    this.discountAmount,
    this.couponCode,
    this.validFrom,
    this.validTo,
    this.termsAndConditions,
    required this.isActive,
    required this.order,
    this.createdAt,
    this.updatedAt,
  });

  factory OfferModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    Map<String, dynamic> data = doc.data()!;
    return OfferModel(
      id: doc.id,
      title: data['title'] as String? ?? 'Untitled Offer',
      description: data['description'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      discountPercentage: (data['discountPercentage'] as num?)?.toDouble(),
      discountAmount: (data['discountAmount'] as num?)?.toDouble(),
      couponCode: data['couponCode'] as String?,
      validFrom: data['validFrom'] as Timestamp?,
      validTo: data['validTo'] as Timestamp?,
      termsAndConditions: data['termsAndConditions'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      order: data['order'] as int? ?? 0,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (discountPercentage != null) 'discountPercentage': discountPercentage,
      if (discountAmount != null) 'discountAmount': discountAmount,
      if (couponCode != null) 'couponCode': couponCode,
      if (validFrom != null) 'validFrom': validFrom,
      if (validTo != null) 'validTo': validTo,
      if (termsAndConditions != null) 'termsAndConditions': termsAndConditions,
      'isActive': isActive,
      'order': order,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt, 
    };
  }
}
