import 'package:flutter/material.dart';

import 'glass_card.dart';

enum AppStateVariant { loading, error, empty }

class AppStatePanel extends StatelessWidget {
  const AppStatePanel({
    super.key,
    required this.variant,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.icon,
  });

  const AppStatePanel.loading({
    super.key,
    required this.message,
  })  : variant = AppStateVariant.loading,
        actionLabel = null,
        onAction = null,
        icon = null;

  const AppStatePanel.error({
    super.key,
    required this.message,
    this.actionLabel = 'Tekrar Dene',
    this.onAction,
  })  : variant = AppStateVariant.error,
        icon = Icons.warning_amber_rounded;

  const AppStatePanel.empty({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.inbox_rounded,
  }) : variant = AppStateVariant.empty;

  final AppStateVariant variant;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: GlassCard(
            variant: GlassCardVariant.elevated,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (variant == AppStateVariant.loading)
                  const CircularProgressIndicator()
                else if (icon != null)
                  Icon(
                    icon,
                    size: 48,
                    color: variant == AppStateVariant.error
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                const SizedBox(height: 20),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 24),
                  FilledButton.tonal(
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
