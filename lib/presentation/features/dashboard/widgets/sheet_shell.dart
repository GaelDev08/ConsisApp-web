import 'package:consis_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Chrome compartido de los modales de registro rápido (Fase 3):
/// padding consistente, título/subtítulo y botón de cierre.
class SheetShell extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const SheetShell({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: text.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!,
                          style: text.bodySmall
                              ?.copyWith(color: AppColors.textSecondary)),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, size: 20),
                color: AppColors.textMuted,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// Campo interactivo de fecha para registro retroactivo.
///
/// Muestra "Hoy" / "Ayer" / "lunes, 24 de agosto" según corresponda
/// y abre un [showDatePicker] al tocarlo (lo conecta cada formulario).
class SheetDateField extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const SheetDateField({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Material(
      color: AppColors.surfaceHigh,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 18, color: AppColors.cyan),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    style: text.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ),
              const Icon(Icons.expand_more_rounded,
                  size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
