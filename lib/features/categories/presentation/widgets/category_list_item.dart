import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/expense_category_entity.dart';
import '../providers/category_actions_provider.dart';
import '../providers/category_provider.dart';
import 'category_form_dialog.dart';

/// List item widget for displaying a category with edit/delete actions
class CategoryListItem extends ConsumerWidget {
  const CategoryListItem({
    super.key,
    required this.category,
    required this.groupId,
  });

  final ExpenseCategoryEntity category;
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isInactive = !category.isActive;

    return Card(
      margin: EdgeInsets.zero,
      color: isInactive
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
          : null,
      child: Opacity(
        opacity: isInactive ? 0.5 : 1.0,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(
              category.getIcon(),
              color: theme.colorScheme.onPrimaryContainer,
              size: 20,
            ),
          ),
          title: Text(
            category.name,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              decoration: isInactive ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: category.expenseCount != null || category.isDefault
              ? Text(
                  [
                    if (category.expenseCount != null)
                      '${category.expenseCount} expense${category.expenseCount == 1 ? '' : 's'}',
                    if (category.isDefault) 'Default',
                  ].join(' • '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              : null,
          trailing: SizedBox(
            width: 110,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Eye icon for visibility toggle
                InkWell(
                  onTap: () {
                    ref
                        .read(categoryProvider(groupId).notifier)
                        .toggleCategoryActive(category.id, !category.isActive);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      category.isActive
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                      color: category.isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.5),
                    ),
                  ),
                ),
                // Edit icon
                InkWell(
                  onTap: () => _showEditDialog(context, ref),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                // Delete icon (only for custom categories)
                if (!category.isDefault)
                  InkWell(
                    onTap: () => _handleDelete(context, ref),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => CategoryFormDialog(
        groupId: groupId,
        categoryToEdit: category,
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina Categoria'),
        content: Text(
          'Vuoi eliminare "${category.name}"?\n\nNota: Se la categoria ha spese associate, la cancellazione fallirà.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Delete the category - let database constraints handle validation
    final actions = ref.read(categoryActionsProvider);
    final result = await actions.deleteCategory(
      groupId: groupId,
      categoryId: category.id,
    );

    if (!context.mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Categoria eliminata con successo'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Show detailed error message
      final errorMsg = result.errorMessage ?? 'Impossibile eliminare la categoria';
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 8),
              const Text('Errore'),
            ],
          ),
          content: Text(errorMsg),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
