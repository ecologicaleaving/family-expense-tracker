import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/expense_category_entity.dart';
import '../../../groups/presentation/providers/group_provider.dart';
import '../providers/category_provider.dart';
import '../widgets/category_form_dialog.dart';
import '../widgets/category_list_item.dart';

/// Category management screen for administrators
class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final groupId = ref.watch(currentGroupIdProvider);
    final categoryState = ref.watch(categoryProvider(groupId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
      ),
      body: categoryState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : categoryState.errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        categoryState.errorMessage!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          ref
                              .read(categoryProvider(groupId).notifier)
                              .loadCategories();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _CategoryListBody(
                  groupId: groupId, categoryState: categoryState),
      floatingActionButton: categoryState.isLoading
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showAddCategoryDialog(context, ref, groupId),
              icon: const Icon(Icons.add),
              label: const Text('New Category'),
            ),
    );
  }

  void _showAddCategoryDialog(
      BuildContext context, WidgetRef ref, String groupId) {
    showDialog(
      context: context,
      builder: (context) => CategoryFormDialog(groupId: groupId),
    );
  }
}

class _CategoryListBody extends ConsumerWidget {
  const _CategoryListBody({
    required this.groupId,
    required this.categoryState,
  });

  final String groupId;
  final CategoryState categoryState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final allCategories = categoryState.allCategories;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Text(
          'Categorie',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          allCategories.isEmpty
              ? 'Nessuna categoria disponibile.'
              : 'Tieni premuto e trascina per riordinare. Usa l\'interruttore per attivare/disattivare.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),

        // Empty state
        if (allCategories.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 64,
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text('Nessuna categoria', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Crea la tua prima categoria per organizzare le spese.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          // Unified list
          _UnifiedReorderableCategoryList(
            categories: allCategories,
            groupId: groupId,
          ),

        const SizedBox(height: 88),
      ],
    );
  }
}

class _UnifiedReorderableCategoryList extends ConsumerWidget {
  const _UnifiedReorderableCategoryList({
    required this.categories,
    required this.groupId,
  });

  final List<ExpenseCategoryEntity> categories;
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: categories.length,
      onReorder: (oldIndex, newIndex) {
        ref.read(categoryProvider(groupId).notifier).reorderCategory(
              oldIndex,
              newIndex,
            );
      },
      proxyDecorator: (child, index, animation) {
        return Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final category = categories[index];
        return Padding(
          key: ValueKey(category.id),
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Icon(
                    Icons.drag_handle,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: CategoryListItem(
                  category: category,
                  groupId: groupId,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
