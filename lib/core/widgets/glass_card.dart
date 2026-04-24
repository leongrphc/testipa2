import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum GlassCardVariant { normal, elevated, highlighted, gold }

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.variant = GlassCardVariant.normal,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final GlassCardVariant variant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = switch (variant) {
      GlassCardVariant.highlighted => AppColors.primaryBright,
      GlassCardVariant.gold => AppColors.gold,
      _ => Colors.white,
    };
    final background = switch (variant) {
      GlassCardVariant.elevated => AppColors.elevated,
      GlassCardVariant.highlighted => AppColors.card,
      GlassCardVariant.gold => const Color(0xFF342B13),
      GlassCardVariant.normal => AppColors.card,
    };

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: background.withValues(alpha: 0.82),
        border: Border.all(
          color: accent.withValues(
            alpha: variant == GlassCardVariant.normal || variant == GlassCardVariant.elevated ? 0.08 : 0.24,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(
              alpha: variant == GlassCardVariant.normal ? 0.04 : 0.12,
            ),
            blurRadius: variant == GlassCardVariant.normal ? 18 : 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: content,
      ),
    );
  }
}
