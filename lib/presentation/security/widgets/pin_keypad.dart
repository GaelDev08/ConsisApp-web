import 'package:consis_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Los 4 indicadores circulares del PIN en curso.
class PinDots extends StatelessWidget {
  final int filled;
  final bool hasError;

  const PinDots({super.key, required this.filled, this.hasError = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final isFilled = i < filled;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hasError
                ? AppColors.coral.withValues(alpha: isFilled ? 0.5 : 0.12)
                : isFilled
                    ? AppColors.violet
                    : Colors.transparent,
            border: Border.all(
              color: hasError
                  ? AppColors.coral
                  : isFilled
                      ? AppColors.violet
                      : AppColors.border,
              width: isFilled || hasError ? 2 : 1,
            ),
          ),
        );
      }),
    );
  }
}

/// Teclado numérico 3×4 estilizado Dark Premium.
///
/// Fila inferior dinámica: [onBiometric] != null muestra el botón de
/// huella en el slot izquierdo; si es null queda hueco simétrico.
class NumericKeypad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final VoidCallback? onBiometric;
  final bool enabled;

  const NumericKeypad({
    super.key,
    required this.onDigit,
    required this.onDelete,
    this.onBiometric,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _row(['1', '2', '3']),
        const SizedBox(height: 12),
        _row(['4', '5', '6']),
        const SizedBox(height: 12),
        _row(['7', '8', '9']),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 72,
              height: 60,
              child: onBiometric != null
                  ? _SpecialKey(
                      icon: Icons.fingerprint_rounded,
                      iconColor: AppColors.cyan,
                      onTap: enabled ? onBiometric : null,
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(width: 12),
            _KeyButton(label: '0', onTap: enabled ? () => onDigit('0') : null),
            const SizedBox(width: 12),
            SizedBox(
              width: 72,
              height: 60,
              child: _SpecialKey(
                icon: Icons.backspace_outlined,
                iconColor: AppColors.textSecondary,
                onTap: enabled ? onDelete : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _row(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < digits.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          _KeyButton(
            label: digits[i],
            onTap: enabled ? () => onDigit(digits[i]) : null,
          ),
        ],
      ],
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _KeyButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceHigh,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 72,
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SpecialKey extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  const _SpecialKey({
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 72,
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
          ),
          child: Icon(icon, size: 26, color: iconColor),
        ),
      ),
    );
  }
}
