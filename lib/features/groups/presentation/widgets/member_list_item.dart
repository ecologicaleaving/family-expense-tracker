import 'package:flutter/material.dart';

import '../../domain/entities/member_entity.dart';

/// List item displaying a group member with role badge and actions.
class MemberListItem extends StatelessWidget {
  const MemberListItem({
    super.key,
    required this.member,
    this.isCurrentUser = false,
    this.canRemove = false,
    this.onRemove,
  });

  final MemberEntity member;
  final bool isCurrentUser;
  final bool canRemove;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: member.isAdmin
            ? theme.colorScheme.primary
            : theme.colorScheme.secondaryContainer,
        child: Text(
          _getInitials(member.displayName),
          style: TextStyle(
            color: member.isAdmin
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSecondaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              member.displayName,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            Text(
              '(Tu)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
      subtitle: member.isAdmin
          ? Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Amministratore',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            )
          : null,
      trailing: canRemove
          ? IconButton(
              icon: Icon(
                Icons.remove_circle_outline,
                color: theme.colorScheme.error,
              ),
              onPressed: onRemove,
              tooltip: 'Rimuovi dal gruppo',
            )
          : null,
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';

    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
    }

    final first = parts[0].isNotEmpty ? parts[0][0] : '';
    final last = parts[parts.length - 1].isNotEmpty ? parts[parts.length - 1][0] : '';

    return '$first$last'.toUpperCase();
  }
}

/// Compact member chip for inline display.
class MemberChip extends StatelessWidget {
  const MemberChip({
    super.key,
    required this.member,
    this.onTap,
  });

  final MemberEntity member;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Chip(
        avatar: CircleAvatar(
          backgroundColor: member.isAdmin
              ? theme.colorScheme.primary
              : theme.colorScheme.secondaryContainer,
          radius: 12,
          child: Text(
            _getInitial(member.displayName),
            style: TextStyle(
              fontSize: 10,
              color: member.isAdmin
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        label: Text(
          member.displayName,
          style: theme.textTheme.bodySmall,
        ),
        side: member.isAdmin
            ? BorderSide(color: theme.colorScheme.primary.withOpacity(0.5))
            : null,
      ),
    );
  }

  String _getInitial(String name) {
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }
}

/// Avatar showing member initials.
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    super.key,
    required this.displayName,
    this.isAdmin = false,
    this.size = 40,
  });

  final String displayName;
  final bool isAdmin;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: isAdmin
          ? theme.colorScheme.primary
          : theme.colorScheme.secondaryContainer,
      child: Text(
        _getInitials(displayName),
        style: TextStyle(
          fontSize: size * 0.4,
          color: isAdmin
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';

    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
    }

    final first = parts[0].isNotEmpty ? parts[0][0] : '';
    final last = parts[parts.length - 1].isNotEmpty ? parts[parts.length - 1][0] : '';

    return '$first$last'.toUpperCase();
  }
}
