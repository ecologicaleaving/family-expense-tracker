import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/invite_code_generator.dart';
import '../models/family_group_model.dart';
import '../models/invite_model.dart';

/// Remote data source for invite operations using Supabase.
abstract class InviteRemoteDataSource {
  /// Create a new invite code for the current user's group.
  Future<InviteModel> createInvite();

  /// Get the active invite for the current user's group.
  Future<InviteModel?> getActiveInvite();

  /// Validate an invite code.
  Future<InviteModel> validateInviteCode({required String code});

  /// Join a group using an invite code.
  Future<FamilyGroupModel> joinGroupWithCode({required String code});
}

/// Implementation of [InviteRemoteDataSource] using Supabase.
class InviteRemoteDataSourceImpl implements InviteRemoteDataSource {
  InviteRemoteDataSourceImpl({required this.supabaseClient});

  final SupabaseClient supabaseClient;

  String get _currentUserId {
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      throw const AppAuthException('Nessun utente autenticato', 'not_authenticated');
    }
    return userId;
  }

  @override
  Future<InviteModel> createInvite() async {
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

      // Check for existing valid invite and invalidate it
      final existingInvites = await supabaseClient
          .from('invites')
          .select()
          .eq('group_id', groupId)
          .isFilter('used_by', null)
          .gt('expires_at', DateTime.now().toIso8601String());

      for (final invite in existingInvites) {
        await supabaseClient
            .from('invites')
            .delete()
            .eq('id', invite['id']);
      }

      // Generate a unique invite code
      String code;
      bool isUnique = false;
      int attempts = 0;
      const maxAttempts = 10;

      do {
        code = InviteCodeGenerator.generate();

        // Check if code already exists
        final existing = await supabaseClient
            .from('invites')
            .select('id')
            .eq('code', code)
            .maybeSingle();

        isUnique = existing == null;
        attempts++;
      } while (!isUnique && attempts < maxAttempts);

      if (!isUnique) {
        throw const ServerException('Impossibile generare un codice univoco', 'code_generation_failed');
      }

      // Create the invite (expires in 7 days)
      final expiresAt = DateTime.now().add(const Duration(days: 7));

      final inviteResponse = await supabaseClient
          .from('invites')
          .insert({
            'group_id': groupId,
            'code': code,
            'created_by': userId,
            'expires_at': expiresAt.toIso8601String(),
          })
          .select()
          .single();

      return InviteModel.fromJson(inviteResponse);
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      if (e is AppAuthException || e is GroupException || e is ServerException) {
        rethrow;
      }
      throw ServerException(e.toString());
    }
  }

  @override
  Future<InviteModel?> getActiveInvite() async {
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
        return null;
      }

      // Get active invite (not used, not expired)
      final inviteResponse = await supabaseClient
          .from('invites')
          .select()
          .eq('group_id', groupId)
          .isFilter('used_by', null)
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (inviteResponse == null) {
        return null;
      }

      return InviteModel.fromJson(inviteResponse);
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      if (e is AppAuthException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<InviteModel> validateInviteCode({required String code}) async {
    try {
      // Normalize code to uppercase
      final normalizedCode = code.toUpperCase().trim();

      // Find the invite
      final inviteResponse = await supabaseClient
          .from('invites')
          .select()
          .eq('code', normalizedCode)
          .maybeSingle();

      if (inviteResponse == null) {
        throw const InviteException('Codice invito non valido', 'invalid_code');
      }

      final invite = InviteModel.fromJson(inviteResponse);

      // Check if already used
      if (invite.isUsed) {
        throw const InviteException('Questo codice invito è già stato utilizzato', 'already_used');
      }

      // Check if expired
      if (invite.isExpired) {
        throw const InviteException('Questo codice invito è scaduto', 'expired');
      }

      return invite;
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      if (e is AppAuthException || e is InviteException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<FamilyGroupModel> joinGroupWithCode({required String code}) async {
    try {
      final userId = _currentUserId;

      // Check if user is already in a group
      final profileResponse = await supabaseClient
          .from('profiles')
          .select('group_id')
          .eq('id', userId)
          .single();

      final currentGroupId = profileResponse['group_id'] as String?;
      if (currentGroupId != null) {
        throw const GroupException(
          'Fai già parte di un gruppo. Devi prima uscire dal gruppo attuale.',
          'already_in_group',
        );
      }

      // Validate the invite
      final invite = await validateInviteCode(code: code);

      // Update the invite to mark it as used
      await supabaseClient
          .from('invites')
          .update({
            'used_by': userId,
            'used_at': DateTime.now().toIso8601String(),
          })
          .eq('id', invite.id);

      // Join the group
      await supabaseClient
          .from('profiles')
          .update({'group_id': invite.groupId})
          .eq('id', userId);

      // Get the group details
      final groupResponse = await supabaseClient
          .from('family_groups')
          .select()
          .eq('id', invite.groupId)
          .single();

      return FamilyGroupModel.fromJson(groupResponse);
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      if (e is AppAuthException || e is GroupException || e is InviteException) {
        rethrow;
      }
      throw ServerException(e.toString());
    }
  }
}
