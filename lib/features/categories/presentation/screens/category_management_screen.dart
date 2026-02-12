import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        categoryState.errorMessage!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          ref.read(categoryProvider(groupId).notifier).loadCategories();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _CategoryListBody(groupId: groupId, categoryState: categoryState),
      floatingActionButton: categoryState.isLoading
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showAddCategoryDialog(context, ref, groupId),
              icon: const Icon(Icons.add),
              label: const Text('New Category'),
            ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref, String groupId) {
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
    final defaultCategories = categoryState.defaultCategories;
    final customCategories = categoryState.customCategories;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Default categories section with drag & drop
        if (defaultCategories.isNotEmpty) ...[
          Text(
            'Default Categories',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tieni premuto e trascina per riordinare.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _ReorderableCategoryList(
            categories: defaultCategories,
            groupId: groupId,
            isDefault: true,
          ),
          const SizedBox(height: 24),
        ],

        // Custom categories section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Custom Categories',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            FilledButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => CategoryFormDialog(groupId: groupId),
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          customCategories.isEmpty
              ? 'No custom categories yet. Create your own to better organize your expenses.'
              : 'Tieni premuto e trascina per riordinare.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),

        if (customCategories.isEmpty)
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
                  Text(
                    'Create your first category',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add custom categories like "Pet care", "Education", or "Subscriptions"',
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
          _ReorderableCategoryList(
            categories: customCategories,
            groupId: groupId,
            isDefault: false,
          ),

        // Bottom padding for FAB
        const SizedBox(height: 88),
      ],
    );
  }
}

class _ReorderableCategoryList extends ConsumerWidget {
  const _ReorderableCategoryList({
    required this.categories,
    required this.groupId,
    required this.isDefault,
  });

  final List categories;
  final String groupId;
  final bool isDefault;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: categories.length,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex--;
        ref.read(categoryProvider(groupId).notifier).reorderCategory(
              oldIndex,
              newIndex,
              isDefault: isDefault,
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
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
