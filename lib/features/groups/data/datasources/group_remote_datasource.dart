import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/exceptions.dart';
import '../models/family_group_model.dart';
import '../models/member_model.dart';

/// Remote data source for group operations using Supabase.
abstract class GroupRemoteDataSource {
  /// Create a new family group.
  Future<FamilyGroupModel> createGroup({required String name});

  /// Get the current user's group.
  Future<FamilyGroupModel?> getCurrentGroup();

  /// Get a group by ID.
  Future<FamilyGroupModel> getGroup({required String groupId});

  /// Get all members of a group.
  Future<List<MemberModel>> getGroupMembers({required String groupId});

  /// Leave the current group.
  Future<void> leaveGroup();

  /// Remove a member from the group.
  Future<void> removeMember({required String userId});

  /// Update the group name.
  Future<FamilyGroupModel> updateGroupName({required String name});

  /// Delete the group.
  Future<void> deleteGroup();
}

/// Implementation of [GroupRemoteDataSource] using Supabase.
class GroupRemoteDataSourceImpl implements GroupRemoteDataSource {
  GroupRemoteDataSourceImpl({required this.supabaseClient});

  final SupabaseClient supabaseClient;

  String get _currentUserId {
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      throw const AppAuthException('Nessun utente autenticato', 'not_authenticated');
    }
    return userId;
  }

  @override
  Future<FamilyGroupModel> createGroup({required String name}) async {
    try {
      final userId = _currentUserId;

      // Create the group
      final groupResponse = await supabaseClient
          .from('family_groups')
          .insert({
            'name': name,
            'created_by': userId,
          })
          .select()
          .single();

      final group = FamilyGroupModel.fromJson(groupResponse);

      // Update the user's profile with the group ID
      await supabaseClient
          .from('profiles')
          .update({'group_id': group.id})
          .eq('id', userId);

      return group;
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      if (e is AppAuthException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<FamilyGroupModel?> getCurrentGroup() async {
    try {
      final userId = _currentUserId;

      // Get user's profile to find group_id
      final profileResponse = await supabaseClient
          .from('profiles')
          .select('group_id')
          .eq('id', userId)
          .single();

      final groupId = profileResponse['group_id'] as String?;
      if (groupId == null) {
        return null;
      }

      // Get the group
      final groupResponse = await supabaseClient
          .from('family_groups')
          .select()
          .eq('id', groupId)
          .single();

      // Get member count
      final memberCount = await supabaseClient
          .from('profiles')
          .select()
          .eq('group_id', groupId)
          .count(CountOption.exact);

      final group = FamilyGroupModel.fromJson(groupResponse);
      return group.copyWith(memberCount: memberCount.count);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        // No rows returned
        return null;
      }
      throw ServerException(e.message, e.code);
    } catch (e) {
      if (e is AppAuthException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<FamilyGroupModel> getGroup({required String groupId}) async {
    try {
      final groupResponse = await supabaseClient
          .from('family_groups')
          .select()
          .eq('id', groupId)
          .single();

      // Get member count
      final memberCount = await supabaseClient
          .from('profiles')
          .select()
          .eq('group_id', groupId)
          .count(CountOption.exact);

      final group = FamilyGroupModel.fromJson(groupResponse);
      return group.copyWith(memberCount: memberCount.count);
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<MemberModel>> getGroupMembers({required String groupId}) async {
    try {
      // Get the group to know who the admin is
      final groupResponse = await supabaseClient
          .from('family_groups')
          .select('created_by')
          .eq('id', groupId)
          .single();

      final adminId = groupResponse['created_by'] as String;

      // Get all members (profiles with this group_id)
      final membersResponse = await supabaseClient
          .from('profiles')
          .select()
          .eq('group_id', groupId)
          .order('created_at');

      return (membersResponse as List)
          .map((json) => MemberModel.fromJson(json, adminId))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> leaveGroup() async {
    try {
      final userId = _currentUserId;

      // Get user's current group
      final profileResponse = await supabaseClient
          .from('profiles')
          .select('group_id')
          .eq('id', userId)
          .single();

      final groupId = profileResponse['group_id'] as String?;
      if (groupId == null) {
        throw const GroupException('Non fai parte di nessun gruppo', 'not_in_group');
      }

      // Check if user is admin
      final groupResponse = await supabaseClient
          .from('family_groups')
          .select('created_by')
          .eq('id', groupId)
          .single();

      final adminId = groupResponse['created_by'] as String;
      if (adminId == userId) {
        // Check if there are other members
        final memberCount = await supabaseClient
            .from('profiles')
            .select()
            .eq('group_id', groupId)
            .count(CountOption.exact);

        if (memberCount.count > 1) {
          throw const GroupException(
            'L\'amministratore non può lasciare il gruppo se ci sono altri membri',
            'admin_cannot_leave',
          );
        }
      }

      // Leave the group
      await supabaseClient
          .from('profiles')
          .update({'group_id': null})
          .eq('id', userId);
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      if (e is AppAuthException || e is GroupException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> removeMember({required String userId}) async {
    try {
      final currentUserId = _currentUserId;

      // Get current user's group
      final profileResponse = await supabaseClient
          .from('profiles')
          .select('group_id')
          .eq('id', currentUserId)
          .single();

      final groupId = profileResponse['group_id'] as String?;
      if (groupId == null) {
        throw const GroupException('Non fai parte di nessun gruppo', 'not_in_group');
      }

      // Check if current user is admin
      final groupResponse = await supabaseClient
          .from('family_groups')
          .select('created_by')
          .eq('id', groupId)
          .single();

      final adminId = groupResponse['created_by'] as String;
      if (adminId != currentUserId) {
        throw const GroupException(
          'Solo l\'amministratore può rimuovere membri',
          'not_admin',
        );
      }

      // Cannot remove yourself
      if (userId == currentUserId) {
        throw const GroupException('Non puoi rimuovere te stesso', 'cannot_remove_self');
      }

      // Remove the member
      await supabaseClient
          .from('profiles')
          .update({'group_id': null})
          .eq('id', userId)
          .eq('group_id', groupId);
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      if (e is AppAuthException || e is GroupException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<FamilyGroupModel> updateGroupName({required String name}) async {
    try {
      final userId = _currentUserId;

      // Get user's group
      final profileResponse = await supabaseClient
          .from('profiles')
          .select('group_id')
          .eq('id', userId)
          .single();

      final groupId = profileResponse['group_id'] as String?;
      if (groupId == null) {
        throw const GroupException('Non fai parte di nessun gruppo', 'not_in_group');
      }

      // Check if user is admin
      final groupResponse = await supabaseClient
          .from('family_groups')
          .select('created_by')
          .eq('id', groupId)
          .single();

      final adminId = groupResponse['created_by'] as String;
      if (adminId != userId) {
        throw const GroupException(
          'Solo l\'amministratore può modificare il nome del gruppo',
          'not_admin',
        );
      }

      // Update the group name
      final updatedGroup = await supabaseClient
          .from('family_groups')
          .update({'name': name})
          .eq('id', groupId)
          .select()
          .single();

      return FamilyGroupModel.fromJson(updatedGroup);
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      if (e is AppAuthException || e is GroupException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteGroup() async {
    try {
      final userId = _currentUserId;

      // Get user's group
      final profileResponse = await supabaseClient
          .from('profiles')
          .select('group_id')
          .eq('id', userId)
          .single();

      final groupId = profileResponse['group_id'] as String?;
      if (groupId == null) {
        throw const GroupException('Non fai parte di nessun gruppo', 'not_in_group');
      }

      // Check if user is admin
      final groupResponse = await supabaseClient
          .from('family_groups')
          .select('created_by')
          .eq('id', groupId)
          .single();

      final adminId = groupResponse['created_by'] as String;
      if (adminId != userId) {
        throw const GroupException(
          'Solo l\'amministratore può eliminare il gruppo',
          'not_admin',
        );
      }

      // Check if there are other members
      final memberCount = await supabaseClient
          .from('profiles')
          .select()
          .eq('group_id', groupId)
          .count(CountOption.exact);

      if (memberCount.count > 1) {
        throw const GroupException(
          'Il gruppo non può essere eliminato se ci sono altri membri',
          'has_members',
        );
      }

      // Remove user from group
      await supabaseClient
          .from('profiles')
          .update({'group_id': null})
          .eq('id', userId);

      // Delete the group
      await supabaseClient
          .from('family_groups')
          .delete()
          .eq('id', groupId);
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      if (e is AppAuthException || e is GroupException) rethrow;
      throw ServerException(e.toString());
    }
  }
}
