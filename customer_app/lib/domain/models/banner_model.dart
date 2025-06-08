class BannerModel {
  final String id;
  final String imageUrl;
  final String mainTagline;
  final String subTagline;

  BannerModel({
    required this.id,
    required this.imageUrl,
    required this.mainTagline,
    required this.subTagline,
  });

  factory BannerModel.fromMap(Map<String, dynamic> map) {
    return BannerModel(
      id: map['id'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      mainTagline: map['mainTagline'] ?? '',
      subTagline: map['subTagline'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'mainTagline': mainTagline,
      'subTagline': subTagline,
    };
  }
} 