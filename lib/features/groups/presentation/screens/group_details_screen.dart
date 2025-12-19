import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/error_display.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../widgets/invite_code_card.dart';
import '../widgets/member_list_item.dart';

/// Screen showing group details, members, and admin actions.
class GroupDetailsScreen extends ConsumerStatefulWidget {
  const GroupDetailsScreen({super.key});

  @override
  ConsumerState<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends ConsumerState<GroupDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Load group data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(groupProvider.notifier).loadCurrentGroup();
    });
  }

  Future<void> _handleLeaveGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lascia il gruppo'),
        content: const Text(
          'Sei sicuro di voler lasciare il gruppo? Le tue spese rimarranno visibili agli altri membri.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Lascia'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(groupProvider.notifier).leaveGroup();
      if (mounted && success) {
        await ref.read(authProvider.notifier).refreshUser();
        if (mounted) {
          context.go('/no-group');
        }
      }
    }
  }

  Future<void> _handleDeleteGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina il gruppo'),
        content: const Text(
          'Sei sicuro di voler eliminare il gruppo? Questa azione non può essere annullata.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(groupProvider.notifier).deleteGroup();
      if (mounted && success) {
        await ref.read(authProvider.notifier).refreshUser();
        if (mounted) {
          context.go('/no-group');
        }
      }
    }
  }

  Future<void> _handleRemoveMember(String userId, String displayName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rimuovi membro'),
        content: Text(
          'Sei sicuro di voler rimuovere $displayName dal gruppo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Rimuovi'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(groupProvider.notifier).removeMember(userId: userId);
    }
  }

  Future<void> _handleGenerateInvite() async {
    await ref.read(groupProvider.notifier).createInvite();
  }

  @override
  Widget build(BuildContext context) {
    final groupState = ref.watch(groupProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isAdmin = ref.watch(isGroupAdminProvider);
    final theme = Theme.of(context);

    if (groupState.isLoading && groupState.group == null) {
      return const Scaffold(
        body: LoadingIndicator(message: 'Caricamento gruppo...'),
      );
    }

    if (groupState.group == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gruppo')),
        body: ErrorDisplay(
          message: 'Gruppo non trovato',
          onRetry: () => ref.read(groupProvider.notifier).loadCurrentGroup(),
        ),
      );
    }

    final group = groupState.group!;
    final members = groupState.members;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: Text(group.name),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditNameDialog(context, group.name),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(groupProvider.notifier).loadCurrentGroup();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Error message
            if (groupState.hasError && groupState.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InlineError(message: groupState.errorMessage!),
              ),

            // Invite code section (admin only)
            if (isAdmin) ...[
              Text(
                'Codice invito',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (groupState.invite != null)
                InviteCodeCard(
                  invite: groupState.invite!,
                  onRefresh: _handleGenerateInvite,
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Nessun codice invito attivo',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SecondaryButton(
                          onPressed: _handleGenerateInvite,
                          label: 'Genera codice',
                          icon: Icons.add,
                          isLoading: groupState.isLoading,
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
            ],

            // Members section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Membri (${members.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  for (int i = 0; i < members.length; i++) ...[
                    MemberListItem(
                      member: members[i],
                      isCurrentUser: members[i].userId == currentUser?.id,
                      canRemove: isAdmin && members[i].userId != currentUser?.id,
                      onRemove: () => _handleRemoveMember(
                        members[i].userId,
                        members[i].displayName,
                      ),
                    ),
                    if (i < members.length - 1) const Divider(height: 1),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Actions section
            if (isAdmin && members.length == 1) ...[
              DangerButton(
                onPressed: _handleDeleteGroup,
                label: 'Elimina gruppo',
                icon: Icons.delete_forever,
                isLoading: groupState.isLoading,
              ),
            ] else ...[
              SecondaryButton(
                onPressed: _handleLeaveGroup,
                label: 'Lascia il gruppo',
                icon: Icons.exit_to_app,
                isLoading: groupState.isLoading,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showEditNameDialog(BuildContext context, String currentName) async {
    final controller = TextEditingController(text: currentName);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifica nome gruppo'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nome del gruppo',
          ),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Salva'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != currentName) {
      await ref.read(groupProvider.notifier).updateGroupName(name: newName);
    }

    controller.dispose();
  }
}
