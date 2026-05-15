import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:splitease/theme/app_theme.dart';

// Full frosted-glass card — uses BackdropFilter to blur content behind it.
// Use for hero/featured cards (balance card, auth form, nav bar).
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double blur;
  final Color? color;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding,
    this.blur = 12,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color ?? GlassColors.surfaceHeavy,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: GlassColors.border),
          ),
          child: child,
        ),
      ),
    );
  }
}

// Lightweight glass tile — no BackdropFilter, safe to use in long lists.
// Looks very similar to GlassCard but avoids the compositing cost.
class GlassTile extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const GlassTile({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Material(
        color: GlassColors.surface,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.white.withValues(alpha: 0.08),
          highlightColor: Colors.white.withValues(alpha: 0.04),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: GlassColors.border),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
