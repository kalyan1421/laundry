import 'package:cloud_firestore/cloud_firestore.dart';

class WorkshopMember {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String? profileImageUrl;
  final String workshopId;
  final String role; // 'worker', 'supervisor', 'manager'
  final bool isActive;
  final DateTime joinedDate;
  final DateTime? lastLoginAt;
  final Map<String, dynamic> performance;
  final Map<String, dynamic> earnings;
  final List<String> specialties; // 'washing', 'ironing', 'dry_cleaning', etc.
  final DateTime createdAt;
  final DateTime updatedAt;

  WorkshopMember({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    this.profileImageUrl,
    required this.workshopId,
    required this.role,
    required this.isActive,
    required this.joinedDate,
    this.lastLoginAt,
    required this.performance,
    required this.earnings,
    required this.specialties,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor from Firestore document
  factory WorkshopMember.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkshopMember(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      workshopId: data['workshopId'] ?? '',
      role: data['role'] ?? 'worker',
      isActive: data['isActive'] ?? true,
      joinedDate: (data['joinedDate'] as Timestamp).toDate(),
      lastLoginAt: data['lastLoginAt'] != null ? (data['lastLoginAt'] as Timestamp).toDate() : null,
      performance: Map<String, dynamic>.from(data['performance'] ?? {}),
      earnings: Map<String, dynamic>.from(data['earnings'] ?? {}),
      specialties: List<String>.from(data['specialties'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'workshopId': workshopId,
      'role': role,
      'isActive': isActive,
      'joinedDate': Timestamp.fromDate(joinedDate),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'performance': performance,
      'earnings': earnings,
      'specialties': specialties,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Copy with method for updating
  WorkshopMember copyWith({
    String? name,
    String? email,
    String? phoneNumber,
    String? profileImageUrl,
    String? workshopId,
    String? role,
    bool? isActive,
    DateTime? joinedDate,
    DateTime? lastLoginAt,
    Map<String, dynamic>? performance,
    Map<String, dynamic>? earnings,
    List<String>? specialties,
    DateTime? updatedAt,
  }) {
    return WorkshopMember(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      workshopId: workshopId ?? this.workshopId,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      joinedDate: joinedDate ?? this.joinedDate,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      performance: performance ?? this.performance,
      earnings: earnings ?? this.earnings,
      specialties: specialties ?? this.specialties,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Get display name
  String get displayName {
    return name.isNotEmpty ? name : email.split('@').first;
  }

  // Get initials for avatar
  String get initials {
    final nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (nameParts.isNotEmpty) {
      return nameParts[0][0].toUpperCase();
    }
    return 'U';
  }

  // Get today's earnings
  double get todaysEarnings {
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return (earnings[todayKey] ?? 0.0).toDouble();
  }

  // Get total earnings
  double get totalEarnings {
    return earnings.values.fold(0.0, (sum, value) => sum + (value.toDouble()));
  }

  // Get today's completed orders
  int get todaysCompletedOrders {
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return (performance['completedOrders']?[todayKey] ?? 0);
  }

  // Get total completed orders
  int get totalCompletedOrders {
    final completedOrders = performance['completedOrders'] as Map<String, dynamic>?;
    return completedOrders?.values.fold<int>(0, (sum, value) => sum + (value as int)) ?? 0;
  }

  // Get today's processed items
  int get todaysProcessedItems {
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return (performance['processedItems']?[todayKey] ?? 0);
  }

  // Get total processed items
  int get totalProcessedItems {
    final processedItems = performance['processedItems'] as Map<String, dynamic>?;
    return processedItems?.values.fold<int>(0, (sum, value) => sum + (value as int)) ?? 0;
  }

  // Check if member can process specific item type
  bool canProcessItemType(String itemType) {
    return specialties.contains(itemType) || specialties.contains('all');
  }

  // Get performance rating (0-5 stars)
  double get performanceRating {
    final rating = performance['rating'] ?? 4.0;
    return rating.toDouble().clamp(0.0, 5.0);
  }

  // Get status color based on activity
  String get statusColor {
    if (!isActive) return 'red';
    if (lastLoginAt == null) return 'orange';
    final daysSinceLogin = DateTime.now().difference(lastLoginAt!).inDays;
    if (daysSinceLogin <= 1) return 'green';
    if (daysSinceLogin <= 7) return 'yellow';
    return 'orange';
  }

  @override
  String toString() {
    return 'WorkshopMember(id: $id, name: $name, email: $email, role: $role, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkshopMember && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 