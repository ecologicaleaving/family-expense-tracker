import 'package:equatable/equatable.dart';

/// Family group entity representing a family expense sharing group.
class FamilyGroupEntity extends Equatable {
  const FamilyGroupEntity({
    required this.id,
    required this.name,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.memberCount = 0,
  });

  /// Unique group identifier
  final String id;

  /// Group name
  final String name;

  /// User ID of the group creator (admin)
  final String createdBy;

  /// When the group was created
  final DateTime? createdAt;

  /// When the group was last updated
  final DateTime? updatedAt;

  /// Number of members in the group
  final int memberCount;

  /// Check if a user is the admin of this group
  bool isAdmin(String userId) => createdBy == userId;

  /// Create an empty group (for initial state)
  factory FamilyGroupEntity.empty() {
    return const FamilyGroupEntity(
      id: '',
      name: '',
      createdBy: '',
    );
  }

  /// Check if this is an empty group
  bool get isEmpty => id.isEmpty;

  /// Check if this is a valid group
  bool get isNotEmpty => id.isNotEmpty;

  /// Create a copy with updated fields
  FamilyGroupEntity copyWith({
    String? id,
    String? name,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? memberCount,
  }) {
    return FamilyGroupEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      memberCount: memberCount ?? this.memberCount,
    );
  }

  @override
  List<Object?> get props => [id, name, createdBy, createdAt, updatedAt, memberCount];

  @override
  String toString() {
    return 'FamilyGroupEntity(id: $id, name: $name, createdBy: $createdBy, memberCount: $memberCount)';
  }
}
