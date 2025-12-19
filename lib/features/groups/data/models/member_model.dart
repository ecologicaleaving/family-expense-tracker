import '../../domain/entities/member_entity.dart';

/// Member model for JSON serialization/deserialization.
///
/// Maps from the 'profiles' table in Supabase with role computed from group admin.
class MemberModel extends MemberEntity {
  const MemberModel({
    required super.userId,
    required super.groupId,
    required super.displayName,
    required super.email,
    required super.role,
    super.joinedAt,
  });

  /// Create a MemberModel from a JSON map (profiles table row).
  /// The adminId is used to determine if this member is an admin.
  factory MemberModel.fromJson(Map<String, dynamic> json, String adminId) {
    final userId = json['id'] as String;
    return MemberModel(
      userId: userId,
      groupId: json['group_id'] as String,
      displayName: json['display_name'] as String? ?? 'Utente',
      email: json['email'] as String? ?? '',
      role: userId == adminId ? MemberRole.admin : MemberRole.member,
      joinedAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  /// Convert to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': userId,
      'group_id': groupId,
      'display_name': displayName,
      'email': email,
      'role': role.name,
      'joined_at': joinedAt?.toIso8601String(),
    };
  }

  /// Create a MemberModel from a MemberEntity.
  factory MemberModel.fromEntity(MemberEntity entity) {
    return MemberModel(
      userId: entity.userId,
      groupId: entity.groupId,
      displayName: entity.displayName,
      email: entity.email,
      role: entity.role,
      joinedAt: entity.joinedAt,
    );
  }

  /// Convert to MemberEntity.
  MemberEntity toEntity() {
    return MemberEntity(
      userId: userId,
      groupId: groupId,
      displayName: displayName,
      email: email,
      role: role,
      joinedAt: joinedAt,
    );
  }

  /// Create a copy with updated fields.
  @override
  MemberModel copyWith({
    String? userId,
    String? groupId,
    String? displayName,
    String? email,
    MemberRole? role,
    DateTime? joinedAt,
  }) {
    return MemberModel(
      userId: userId ?? this.userId,
      groupId: groupId ?? this.groupId,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}
