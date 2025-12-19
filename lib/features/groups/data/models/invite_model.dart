import '../../domain/entities/invite_entity.dart';

/// Invite model for JSON serialization/deserialization.
///
/// Maps to the 'invites' table in Supabase.
class InviteModel extends InviteEntity {
  const InviteModel({
    required super.id,
    required super.groupId,
    required super.code,
    required super.createdBy,
    required super.expiresAt,
    super.usedBy,
    super.usedAt,
    super.createdAt,
  });

  /// Create an InviteModel from a JSON map (invites table row).
  factory InviteModel.fromJson(Map<String, dynamic> json) {
    return InviteModel(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      code: json['code'] as String,
      createdBy: json['created_by'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      usedBy: json['used_by'] as String?,
      usedAt: json['used_at'] != null
          ? DateTime.parse(json['used_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  /// Convert to JSON map for database operations.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'code': code,
      'created_by': createdBy,
      'expires_at': expiresAt.toIso8601String(),
      'used_by': usedBy,
      'used_at': usedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }

  /// Create an InviteModel from an InviteEntity.
  factory InviteModel.fromEntity(InviteEntity entity) {
    return InviteModel(
      id: entity.id,
      groupId: entity.groupId,
      code: entity.code,
      createdBy: entity.createdBy,
      expiresAt: entity.expiresAt,
      usedBy: entity.usedBy,
      usedAt: entity.usedAt,
      createdAt: entity.createdAt,
    );
  }

  /// Convert to InviteEntity.
  InviteEntity toEntity() {
    return InviteEntity(
      id: id,
      groupId: groupId,
      code: code,
      createdBy: createdBy,
      expiresAt: expiresAt,
      usedBy: usedBy,
      usedAt: usedAt,
      createdAt: createdAt,
    );
  }

  /// Create a copy with updated fields.
  @override
  InviteModel copyWith({
    String? id,
    String? groupId,
    String? code,
    String? createdBy,
    DateTime? expiresAt,
    String? usedBy,
    DateTime? usedAt,
    DateTime? createdAt,
  }) {
    return InviteModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      code: code ?? this.code,
      createdBy: createdBy ?? this.createdBy,
      expiresAt: expiresAt ?? this.expiresAt,
      usedBy: usedBy ?? this.usedBy,
      usedAt: usedAt ?? this.usedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
