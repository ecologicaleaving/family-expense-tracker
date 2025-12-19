import 'package:flutter/material.dart';

import '../../../groups/domain/entities/member_entity.dart';

/// Dropdown widget for filtering by group member.
class MemberFilter extends StatelessWidget {
  const MemberFilter({
    super.key,
    required this.members,
    required this.selectedMemberId,
    required this.onMemberChanged,
    this.showAllOption = true,
  });

  final List<MemberEntity> members;
  final String? selectedMemberId;
  final ValueChanged<String?> onMemberChanged;
  final bool showAllOption;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      value: selectedMemberId,
      decoration: const InputDecoration(
        labelText: 'Filtra per membro',
        prefixIcon: Icon(Icons.person_outline),
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        if (showAllOption)
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('Tutti i membri'),
          ),
        ...members.map((member) => DropdownMenuItem<String?>(
              value: member.userId,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: _getAvatarColor(member.displayName),
                    child: Text(
                      member.displayName.isNotEmpty
                          ? member.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      member.displayName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (member.isAdmin)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Admin',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            )),
      ],
      onChanged: onMemberChanged,
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    final index = name.isNotEmpty ? name.codeUnitAt(0) % colors.length : 0;
    return colors[index];
  }
}

/// Compact chip-based member filter.
class MemberFilterChips extends StatelessWidget {
  const MemberFilterChips({
    super.key,
    required this.members,
    required this.selectedMemberId,
    required this.onMemberChanged,
  });

  final List<MemberEntity> members;
  final String? selectedMemberId;
  final ValueChanged<String?> onMemberChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text('Tutti'),
            selected: selectedMemberId == null,
            onSelected: (_) => onMemberChanged(null),
          ),
          const SizedBox(width: 8),
          ...members.map((member) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  avatar: CircleAvatar(
                    backgroundColor: _getAvatarColor(member.displayName),
                    child: Text(
                      member.displayName.isNotEmpty
                          ? member.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  label: Text(member.displayName),
                  selected: selectedMemberId == member.userId,
                  onSelected: (_) => onMemberChanged(
                    selectedMemberId == member.userId ? null : member.userId,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    final index = name.isNotEmpty ? name.codeUnitAt(0) % colors.length : 0;
    return colors[index];
  }
}
