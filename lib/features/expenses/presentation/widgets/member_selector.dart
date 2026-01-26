import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../groups/presentation/providers/group_provider.dart';

/// Widget for selecting a group member (admin-only feature).
///
/// This widget allows group administrators to select which member
/// an expense should be created for. Only visible to admins.
/// Feature 001-admin-expenses-cash-fix (T012)
class MemberSelector extends ConsumerWidget {
  const MemberSelector({
    super.key,
    this.selectedMemberId,
    required this.onChanged,
    this.enabled = true,
  });

  final String? selectedMemberId;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if current user is admin
    final isAdmin = ref.watch(isGroupAdminProvider);

    // Only show for admins
    if (!isAdmin) {
      return const SizedBox.shrink();
    }

    // Get group members
    final groupMembers = ref.watch(groupMembersProvider);

    if (groupMembers.isEmpty) {
      return const SizedBox.shrink();
    }

    // Build dropdown items from active members
    final items = groupMembers.map((member) {
      return DropdownMenuItem<String>(
        value: member.userId,
        child: Row(
          children: [
            const Icon(Icons.person, size: 20),
            const SizedBox(width: 8),
            Text(member.displayName),
          ],
        ),
      );
    }).toList();

    return DropdownButtonFormField<String>(
      value: selectedMemberId,
      decoration: const InputDecoration(
        labelText: 'Crea spesa per (opzionale)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person),
        helperText: 'Lascia vuoto per creare la spesa per te stesso',
      ),
      items: items,
      onChanged: enabled ? onChanged : null,
      // No validator - field is optional for admins
    );
  }
}
