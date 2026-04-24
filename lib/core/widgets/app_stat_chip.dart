import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppStatChip extends StatelessWidget {
  const AppStatChip({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.primaryBright,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.13),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            '$label: $value',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
