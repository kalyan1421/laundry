// models/offer_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class OfferModel {
  final String? id;
  final String title;
  final String description;
  String imageUrl; // Modifiable if a new image is uploaded
  final String? promoCode;
  final String discountType; // e.g., "percentage", "fixed"
  final num discountValue;
  final num? minOrderValue;
  final Timestamp validFrom;
  final Timestamp validTo;
  bool isActive; // Modifiable
  final String? termsAndConditions;
  final Timestamp createdAt;
  Timestamp updatedAt; // Modifiable

  OfferModel({
    this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.promoCode,
    required this.discountType,
    required this.discountValue,
    this.minOrderValue,
    required this.validFrom,
    required this.validTo,
    required this.isActive,
    this.termsAndConditions,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OfferModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return OfferModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      promoCode: data['promoCode'],
      discountType: data['discountType'] ?? 'percentage',
      discountValue: data['discountValue'] ?? 0,
      minOrderValue: data['minOrderValue'],
      validFrom: data['validFrom'] ?? Timestamp.now(),
      validTo: data['validTo'] ?? Timestamp.now(),
      isActive: data['isActive'] ?? false,
      termsAndConditions: data['termsAndConditions'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'promoCode': promoCode,
      'discountType': discountType,
      'discountValue': discountValue,
      'minOrderValue': minOrderValue,
      'validFrom': validFrom,
      'validTo': validTo,
      'isActive': isActive,
      'termsAndConditions': termsAndConditions,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}