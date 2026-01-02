import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/expense_category_entity.dart';
import '../providers/category_actions_provider.dart';

/// Dialog for creating or editing a category
class CategoryFormDialog extends ConsumerStatefulWidget {
  const CategoryFormDialog({
    super.key,
    required this.groupId,
    this.categoryToEdit,
  });

  final String groupId;
  final ExpenseCategoryEntity? categoryToEdit;

  @override
  ConsumerState<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends ConsumerState<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.categoryToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.categoryToEdit!.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final actions = ref.read(categoryActionsProvider);
      final name = _nameController.text.trim();

      // Check if name already exists
      final exists = await actions.categoryNameExists(
        groupId: widget.groupId,
        name: name,
        excludeCategoryId: _isEditing ? widget.categoryToEdit!.id : null,
      );

      if (exists) {
        setState(() {
          _errorMessage = 'A category with this name already exists';
          _isSubmitting = false;
        });
        return;
      }

      final result = _isEditing
          ? await actions.updateCategory(
              groupId: widget.groupId,
              categoryId: widget.categoryToEdit!.id,
              name: name,
            )
          : await actions.createCategory(
              groupId: widget.groupId,
              name: name,
            );

      if (mounted) {
        if (result != null) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditing
                    ? 'Category updated successfully'
                    : 'Category created successfully',
              ),
            ),
          );
        } else {
          setState(() {
            _errorMessage = _isEditing
                ? 'Failed to update category'
                : 'Failed to create category';
            _isSubmitting = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred: $e';
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(_isEditing ? 'Edit Category' : 'New Category'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                hintText: 'e.g. Pet care, Education',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              enabled: !_isSubmitting,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Category name cannot be empty';
                }
                if (value.trim().length < 1) {
                  return 'Category name must be at least 1 character';
                }
                if (value.trim().length > 50) {
                  return 'Category name must be at most 50 characters';
                }
                return null;
              },
              onFieldSubmitted: (_) => _handleSubmit(),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.onErrorContainer,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          child: _isSubmitting
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
