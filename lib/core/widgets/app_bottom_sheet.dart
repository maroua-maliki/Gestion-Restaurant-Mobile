import 'package:flutter/material.dart';
import 'package:restaurantapp/core/theme/app_theme.dart';

/// A modern bottom sheet with handle and customizable content
class AppBottomSheet extends StatelessWidget {
  final String? title;
  final Widget child;
  final List<Widget>? actions;
  final double? maxHeight;
  final bool showHandle;

  const AppBottomSheet({
    super.key,
    this.title,
    required this.child,
    this.actions,
    this.maxHeight,
    this.showHandle = true,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    List<Widget>? actions,
    double? maxHeight,
    bool isScrollControlled = true,
    bool showHandle = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      builder: (context) => AppBottomSheet(
        title: title,
        actions: actions,
        maxHeight: maxHeight,
        showHandle: showHandle,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight ?? MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showHandle) ...[
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
          ],
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: child,
            ),
          ),
          if (actions != null && actions!.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                16 + MediaQuery.of(context).viewPadding.bottom,
              ),
              child: Row(
                children: actions!
                    .expand((action) => [action, const SizedBox(width: 12)])
                    .toList()
                  ..removeLast(),
              ),
            ),
          ] else
            SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
        ],
      ),
    );
  }
}

/// Confirmation dialog with modern design
class AppConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final Color? confirmColor;
  final IconData? icon;

  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirmer',
    this.cancelText = 'Annuler',
    this.confirmColor,
    this.icon,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirmer',
    String cancelText = 'Annuler',
    Color? confirmColor,
    IconData? icon,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AppConfirmDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        confirmColor: confirmColor,
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: confirmColor ?? AppColors.primary),
            const SizedBox(width: 12),
          ],
          Expanded(child: Text(title)),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(cancelText)),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: confirmColor ?? AppColors.primary),
          child: Text(confirmText),
        ),
      ],
    );
  }
}

