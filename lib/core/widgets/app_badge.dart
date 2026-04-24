import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AppBadgeTone { neutral, primary, gold, success, danger, warning, info, premium }

class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.icon,
    this.tone = AppBadgeTone.neutral,
  });

  final String label;
  final IconData? icon;
  final AppBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      AppBadgeTone.primary => AppColors.primaryBright,
      AppBadgeTone.gold => AppColors.gold,
      AppBadgeTone.success => AppColors.success,
      AppBadgeTone.danger => AppColors.danger,
      AppBadgeTone.warning => AppColors.warning,
      AppBadgeTone.info => AppColors.info,
      AppBadgeTone.premium => AppColors.expert,
      AppBadgeTone.neutral => AppColors.textSecondary,
    };

    return Container(
      constraints: const BoxConstraints(minHeight: 32),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
