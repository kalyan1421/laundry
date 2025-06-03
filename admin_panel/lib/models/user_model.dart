// models/user_model.dart
class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role; // 'admin' or 'delivery'
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'createdAt': createdAt,
    };
  }

  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'delivery',
      createdAt: (map['createdAt']?.toDate()) ?? DateTime.now(),
    );
  }
}
