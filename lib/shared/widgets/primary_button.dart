import 'package:flutter/material.dart';

import 'loading_indicator.dart';

/// Primary action button with loading state support.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.isLoading = false,
    this.isEnabled = true,
    this.loadingLabel,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool isLoading;
  final bool isEnabled;
  final String? loadingLabel;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading || !isEnabled ? null : onPressed;

    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: effectiveOnPressed,
        icon: isLoading
            ? const InlineLoadingIndicator(size: 20, color: Colors.white)
            : Icon(icon),
        label: Text(isLoading ? (loadingLabel ?? label) : label),
      );
    }

    return ElevatedButton(
      onPressed: effectiveOnPressed,
      child: isLoading
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const InlineLoadingIndicator(size: 20, color: Colors.white),
                const SizedBox(width: 12),
                Text(loadingLabel ?? label),
              ],
            )
          : Text(label),
    );
  }
}

/// Secondary/outlined button variant
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.isLoading = false,
    this.isEnabled = true,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool isLoading;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading || !isEnabled ? null : onPressed;

    if (icon != null) {
      return OutlinedButton.icon(
        onPressed: effectiveOnPressed,
        icon: isLoading
            ? InlineLoadingIndicator(
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              )
            : Icon(icon),
        label: Text(label),
      );
    }

    return OutlinedButton(
      onPressed: effectiveOnPressed,
      child: isLoading
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InlineLoadingIndicator(
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(label),
              ],
            )
          : Text(label),
    );
  }
}

/// Text button variant
class TertiaryButton extends StatelessWidget {
  const TertiaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.isLoading = false,
    this.isEnabled = true,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool isLoading;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading || !isEnabled ? null : onPressed;

    if (icon != null) {
      return TextButton.icon(
        onPressed: effectiveOnPressed,
        icon: isLoading
            ? InlineLoadingIndicator(
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              )
            : Icon(icon),
        label: Text(label),
      );
    }

    return TextButton(
      onPressed: effectiveOnPressed,
      child: isLoading
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InlineLoadingIndicator(
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(label),
              ],
            )
          : Text(label),
    );
  }
}

/// Danger/destructive button (red)
class DangerButton extends StatelessWidget {
  const DangerButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.isLoading = false,
    this.isEnabled = true,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool isLoading;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveOnPressed = isLoading || !isEnabled ? null : onPressed;

    final style = ElevatedButton.styleFrom(
      backgroundColor: theme.colorScheme.error,
      foregroundColor: theme.colorScheme.onError,
    );

    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: effectiveOnPressed,
        style: style,
        icon: isLoading
            ? const InlineLoadingIndicator(size: 20, color: Colors.white)
            : Icon(icon),
        label: Text(label),
      );
    }

    return ElevatedButton(
      onPressed: effectiveOnPressed,
      style: style,
      child: isLoading
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const InlineLoadingIndicator(size: 20, color: Colors.white),
                const SizedBox(width: 12),
                Text(label),
              ],
            )
          : Text(label),
    );
  }
}
