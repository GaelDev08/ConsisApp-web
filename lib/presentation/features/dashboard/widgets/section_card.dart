import 'package:consis_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Contenedor estándar de sección del dashboard: superficie elevada,
/// borde sutil y header opcional con título/subtítulo.
class SectionCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const SectionCard({
    super.key,
    this.title,
    this.subtitle,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null)
            Text(title!, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          if (title != null || subtitle != null) const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
