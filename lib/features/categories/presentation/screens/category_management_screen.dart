import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
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
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Default categories section
                    if (categoryState.defaultCategories.isNotEmpty) ...[
                      Text(
                        'Default Categories',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'These categories are provided by default and cannot be edited or deleted.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...categoryState.defaultCategories.map(
                        (category) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: CategoryListItem(
                            category: category,
                            groupId: groupId,
                          ),
                        ),
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
                          onPressed: () => _showAddCategoryDialog(context, ref, groupId),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      categoryState.customCategories.isEmpty
                          ? 'No custom categories yet. Create your own to better organize your expenses.'
                          : 'These are custom categories created for your group.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (categoryState.customCategories.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(
                                Icons.category_outlined,
                                size: 64,
                                color: theme.colorScheme.primary.withOpacity(0.5),
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
                      ...categoryState.customCategories.map(
                        (category) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: CategoryListItem(
                            category: category,
                            groupId: groupId,
                          ),
                        ),
                      ),
                  ],
                ),
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
