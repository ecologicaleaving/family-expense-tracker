import 'package:equatable/equatable.dart';

/// Group member role
enum MemberRole {
  admin,
  member,
}

/// Group member entity representing a user's membership in a family group.
class MemberEntity extends Equatable {
  const MemberEntity({
    required this.userId,
    required this.groupId,
    required this.displayName,
    required this.email,
    required this.role,
    this.joinedAt,
  });

  /// The user's ID
  final String userId;

  /// The group's ID
  final String groupId;

  /// The user's display name
  final String displayName;

  /// The user's email
  final String email;

  /// The user's role in the group
  final MemberRole role;

  /// When the user joined the group
  final DateTime? joinedAt;

  /// Check if this member is an admin
  bool get isAdmin => role == MemberRole.admin;

  /// Check if this member is a regular member
  bool get isMember => role == MemberRole.member;

  /// Create a copy with updated fields
  MemberEntity copyWith({
    String? userId,
    String? groupId,
    String? displayName,
    String? email,
    MemberRole? role,
    DateTime? joinedAt,
  }) {
    return MemberEntity(
      userId: userId ?? this.userId,
      groupId: groupId ?? this.groupId,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  @override
  List<Object?> get props => [userId, groupId, displayName, email, role, joinedAt];

  @override
  String toString() {
    return 'MemberEntity(userId: $userId, displayName: $displayName, role: $role)';
  }
}
