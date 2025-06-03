
// models/offer_model.dart
class OfferModel {
  final String id;
  final String title;
  final String description;
  final double discount;
  final DateTime validFrom;
  final DateTime validTo;
  final bool isActive;

  OfferModel({
    required this.id,
    required this.title,
    required this.description,
    required this.discount,
    required this.validFrom,
    required this.validTo,
    required this.isActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'discount': discount,
      'validFrom': validFrom,
      'validTo': validTo,
      'isActive': isActive,
    };
  }

  factory OfferModel.fromMap(String id, Map<String, dynamic> map) {
    return OfferModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      discount: (map['discount'] ?? 0.0).toDouble(),
      validFrom: (map['validFrom']?.toDate()) ?? DateTime.now(),
      validTo: (map['validTo']?.toDate()) ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }
}