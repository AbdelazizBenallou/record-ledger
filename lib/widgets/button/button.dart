import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary, danger }

class AppButton extends StatelessWidget {
  final String label;
  final String? loadingLabel;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expanded;
  final AppButtonVariant variant;

  const AppButton({
    super.key,
    required this.label,
    this.loadingLabel,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expanded = true,
    this.variant = AppButtonVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    switch (variant) {
      case AppButtonVariant.primary:
        return _buildFilled(theme);
      case AppButtonVariant.secondary:
        return _buildOutlined(theme);
      case AppButtonVariant.danger:
        return _buildDanger(theme);
    }
  }

  Widget _buildFilled(ThemeData theme) {
    final widget = FilledButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.5, color: Colors.white,
              ),
            )
          : (icon != null ? Icon(icon, size: 20) : const SizedBox.shrink()),
      label: Text(isLoading ? (loadingLabel ?? label) : label),
      style: FilledButton.styleFrom(
        minimumSize: Size(expanded ? double.infinity : 0, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
    return expanded ? widget : SizedBox(width: 48, child: widget);
  }

  Widget _buildOutlined(ThemeData theme) {
    return OutlinedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : (icon != null ? Icon(icon, size: 20) : const SizedBox.shrink()),
      label: Text(isLoading ? (loadingLabel ?? label) : label),
      style: OutlinedButton.styleFrom(
        minimumSize: Size(expanded ? double.infinity : 0, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        side: BorderSide(color: theme.colorScheme.outline),
      ),
    );
  }

  Widget _buildDanger(ThemeData theme) {
    return FilledButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.5, color: Colors.white,
              ),
            )
          : (icon != null ? Icon(icon, size: 20) : const SizedBox.shrink()),
      label: Text(isLoading ? (loadingLabel ?? label) : label),
      style: FilledButton.styleFrom(
        minimumSize: Size(expanded ? double.infinity : 0, 52),
        backgroundColor: theme.colorScheme.error,
        foregroundColor: theme.colorScheme.onError,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
