// Widget: Member Contribution Info
// Feature: Italian Categories and Budget Management (004)
// Shows which members contribute percentage budgets for a category

import 'package:flutter/material.dart';

import '../../data/models/member_budget_contribution_model.dart';

/// Widget to display members who contribute to category budget via percentage
class MemberContributionInfoWidget extends StatelessWidget {
  const MemberContributionInfoWidget({
    super.key,
    required this.members,
  });

  final List<MemberBudgetContributionModel> members;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Filter only members with percentage budgets
    final membersWithPercentage = members
        .where((m) => m.hasPercentageBudget)
        .toList();

    if (membersWithPercentage.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people,
                size: 16,
                color: theme.colorScheme.onTertiaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                'Membri che contribuiscono:',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onTertiaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: membersWithPercentage.map((member) {
              return Chip(
                avatar: CircleAvatar(
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    member.userName[0].toUpperCase(),
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                label: Text(
                  '${member.userName} • ${member.percentageValue!.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 13),
                ),
                backgroundColor: theme.colorScheme.secondaryContainer,
                side: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
