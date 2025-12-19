import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/family_group_entity.dart';
import '../entities/invite_entity.dart';
import '../entities/member_entity.dart';

/// Abstract group repository interface.
///
/// Defines the contract for family group operations.
/// Implementations should handle the actual communication with
/// the backend (Supabase).
abstract class GroupRepository {
  /// Create a new family group.
  ///
  /// Returns [Right] with [FamilyGroupEntity] on success,
  /// or [Left] with [Failure] on failure.
  Future<Either<Failure, FamilyGroupEntity>> createGroup({
    required String name,
  });

  /// Get the current user's group.
  ///
  /// Returns [Right] with [FamilyGroupEntity] if user has a group,
  /// or [Left] with [Failure] if no group or error.
  Future<Either<Failure, FamilyGroupEntity>> getCurrentGroup();

  /// Get a group by ID.
  ///
  /// Returns [Right] with [FamilyGroupEntity] on success,
  /// or [Left] with [Failure] on failure.
  Future<Either<Failure, FamilyGroupEntity>> getGroup({
    required String groupId,
  });

  /// Get all members of a group.
  ///
  /// Returns [Right] with list of [MemberEntity] on success,
  /// or [Left] with [Failure] on failure.
  Future<Either<Failure, List<MemberEntity>>> getGroupMembers({
    required String groupId,
  });

  /// Leave the current group.
  ///
  /// Returns [Right] with [unit] on success,
  /// or [Left] with [Failure] on failure.
  /// Note: Admins cannot leave if they are the only member.
  Future<Either<Failure, Unit>> leaveGroup();

  /// Remove a member from the group (admin only).
  ///
  /// Returns [Right] with [unit] on success,
  /// or [Left] with [Failure] on failure.
  Future<Either<Failure, Unit>> removeMember({
    required String userId,
  });

  /// Update the group name (admin only).
  ///
  /// Returns [Right] with updated [FamilyGroupEntity] on success,
  /// or [Left] with [Failure] on failure.
  Future<Either<Failure, FamilyGroupEntity>> updateGroupName({
    required String name,
  });

  /// Create a new invite code for the group.
  ///
  /// Returns [Right] with [InviteEntity] on success,
  /// or [Left] with [Failure] on failure.
  Future<Either<Failure, InviteEntity>> createInvite();

  /// Get the active invite for the current group.
  ///
  /// Returns [Right] with [InviteEntity] if exists,
  /// or [Left] with [Failure] if no active invite or error.
  Future<Either<Failure, InviteEntity>> getActiveInvite();

  /// Validate an invite code.
  ///
  /// Returns [Right] with [InviteEntity] if valid,
  /// or [Left] with [InviteFailure] if invalid, expired, or already used.
  Future<Either<Failure, InviteEntity>> validateInviteCode({
    required String code,
  });

  /// Join a group using an invite code.
  ///
  /// Returns [Right] with [FamilyGroupEntity] on success,
  /// or [Left] with [Failure] on failure.
  Future<Either<Failure, FamilyGroupEntity>> joinGroupWithCode({
    required String code,
  });

  /// Delete the group (admin only, requires all members to leave first).
  ///
  /// Returns [Right] with [unit] on success,
  /// or [Left] with [Failure] on failure.
  Future<Either<Failure, Unit>> deleteGroup();
}
