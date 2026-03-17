import 'package:flutter/material.dart';

// ─── Design tokens ────────────────────────────────────────
class AppColors {
  static const bg         = Color(0xFF0F0F18);
  static const surface    = Color(0xFF1A1A24);
  static const surfaceDeep= Color(0xFF12121A);
  static const border     = Color(0xFF2A2A3A);
  static const blue       = Color(0xFF378ADD);
  static const blueLight  = Color(0xFF60B4F0);
  static const amber      = Color(0xFFEF9F27);
  static const amberLight = Color(0xFFFAC775);
  static const green      = Color(0xFF1D9E75);
  static const red        = Color(0xFFE24B4A);
  static const purple     = Color(0xFF534AB7);
  static const textMuted  = Color(0xFFAAAAAA);
  static const textHint   = Color(0xFF666677);
}

// ─── Stat tile ────────────────────────────────────────────
class SimStatTile extends StatelessWidget {
  const SimStatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.progress,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final double? progress; // 0-1, shows a thin progress bar if non-null

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceDeep,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                backgroundColor: AppColors.border,
                color: progress! < 0.33
                    ? AppColors.green
                    : progress! < 0.66
                        ? AppColors.amber
                        : AppColors.red,
                minHeight: 3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Slider row ───────────────────────────────────────────
class SimSliderRow extends StatelessWidget {
  const SimSliderRow({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.onChanged,
    this.accentColor = AppColors.blue,
    this.decimals = 1,
    this.divisions,
  });

  final String label;
  final double value;
  final String unit;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final Color accentColor;
  final int decimals;
  final int? divisions;

  @override
  Widget build(BuildContext context) {
    final display = decimals == 0
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(decimals);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12)),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$display$unit',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: accentColor,
            inactiveTrackColor: Colors.white.withOpacity(0.08),
            thumbColor: accentColor,
            overlayColor: accentColor.withOpacity(0.12),
            trackHeight: 3,
            thumbShape:
                const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

// ─── Primary button ───────────────────────────────────────
class SimPrimaryButton extends StatelessWidget {
  const SimPrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color = AppColors.blue,
    this.isLoading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed == null
              ? color.withOpacity(0.35)
              : color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }
}

// ─── Secondary button ─────────────────────────────────────
class SimSecondaryButton extends StatelessWidget {
  const SimSecondaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textMuted,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─── Formula bar ──────────────────────────────────────────
class SimFormulaBar extends StatelessWidget {
  const SimFormulaBar(this.formula, {super.key});
  final String formula;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surfaceDeep,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        formula,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.blueLight,
          fontSize: 11,
          fontFamily: 'monospace',
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────
class SimSectionLabel extends StatelessWidget {
  const SimSectionLabel(this.text, {super.key, this.color = AppColors.blue});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textHint,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}

// ─── Icon toggle button ───────────────────────────────────
class SimIconToggle extends StatelessWidget {
  const SimIconToggle({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: value
              ? activeColor.withOpacity(0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: value ? activeColor : AppColors.border,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 15,
                color: value ? activeColor : AppColors.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: value ? activeColor : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Canvas container ─────────────────────────────────────
class SimCanvas extends StatelessWidget {
  const SimCanvas({
    super.key,
    required this.child,
    this.accentColor,
  });

  final Widget child;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor?.withOpacity(0.2) ??
              Colors.white.withOpacity(0.07),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }
}

// ─── Controls panel ───────────────────────────────────────
class SimControlsPanel extends StatelessWidget {
  const SimControlsPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: padding,
        child: child,
      ),
    );
  }
}

// ─── Status pill ──────────────────────────────────────────
class SimStatusPill extends StatelessWidget {
  const SimStatusPill({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}