import 'package:equatable/equatable.dart';

/// Invite entity representing a group invitation code.
class InviteEntity extends Equatable {
  const InviteEntity({
    required this.id,
    required this.groupId,
    required this.code,
    required this.createdBy,
    required this.expiresAt,
    this.usedBy,
    this.usedAt,
    this.createdAt,
  });

  /// Unique invite identifier
  final String id;

  /// The group this invite is for
  final String groupId;

  /// The 6-character invite code
  final String code;

  /// User ID of who created the invite
  final String createdBy;

  /// When the invite expires
  final DateTime expiresAt;

  /// User ID of who used the invite (null if not used)
  final String? usedBy;

  /// When the invite was used (null if not used)
  final DateTime? usedAt;

  /// When the invite was created
  final DateTime? createdAt;

  /// Check if the invite is still valid
  bool get isValid => !isUsed && !isExpired;

  /// Check if the invite has been used
  bool get isUsed => usedBy != null;

  /// Check if the invite has expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Get remaining time until expiration
  Duration get remainingTime {
    if (isExpired) return Duration.zero;
    return expiresAt.difference(DateTime.now());
  }

  /// Create a copy with updated fields
  InviteEntity copyWith({
    String? id,
    String? groupId,
    String? code,
    String? createdBy,
    DateTime? expiresAt,
    String? usedBy,
    DateTime? usedAt,
    DateTime? createdAt,
  }) {
    return InviteEntity(
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

  @override
  List<Object?> get props => [id, groupId, code, createdBy, expiresAt, usedBy, usedAt, createdAt];

  @override
  String toString() {
    return 'InviteEntity(id: $id, code: $code, groupId: $groupId, isValid: $isValid)';
  }
}
