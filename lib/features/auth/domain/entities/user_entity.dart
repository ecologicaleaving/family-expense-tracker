import 'package:equatable/equatable.dart';

/// User entity representing an authenticated user.
class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.email,
    this.displayName,
    this.groupId,
    this.createdAt,
    this.updatedAt,
  });

  /// Unique user identifier (from Supabase Auth)
  final String id;

  /// User's email address
  final String email;

  /// User's display name (optional)
  final String? displayName;

  /// The family group this user belongs to (null if not in a group)
  final String? groupId;

  /// When the user was created
  final DateTime? createdAt;

  /// When the user was last updated
  final DateTime? updatedAt;

  /// Whether the user has a display name set
  bool get hasDisplayName => displayName != null && displayName!.isNotEmpty;

  /// Whether the user belongs to a family group
  bool get hasGroup => groupId != null;

  /// Create an empty user (for initial state)
  factory UserEntity.empty() {
    return const UserEntity(
      id: '',
      email: '',
    );
  }

  /// Check if this is an empty user
  bool get isEmpty => id.isEmpty;

  /// Check if this is a valid user
  bool get isNotEmpty => id.isNotEmpty;

  /// Create a copy with updated fields
  UserEntity copyWith({
    String? id,
    String? email,
    String? displayName,
    String? groupId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      groupId: groupId ?? this.groupId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, email, displayName, groupId, createdAt, updatedAt];

  @override
  String toString() {
    return 'UserEntity(id: $id, email: $email, displayName: $displayName, groupId: $groupId)';
  }
}
