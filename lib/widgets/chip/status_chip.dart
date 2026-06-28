import 'package:flutter/material.dart';

enum ChipType { success, warning, error, neutral }

class StatusChip extends StatelessWidget {
  final String label;
  final ChipType type;
  final double fontSize;

  const StatusChip({
    super.key,
    required this.label,
    required this.type,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          color: colors.foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  _ChipColors get _colors {
    switch (type) {
      case ChipType.success:
        return _ChipColors(
          background: const Color(0xFF10B981).withValues(alpha: 0.12),
          foreground: const Color(0xFF059669),
        );
      case ChipType.warning:
        return _ChipColors(
          background: const Color(0xFFF59E0B).withValues(alpha: 0.12),
          foreground: const Color(0xFFD97706),
        );
      case ChipType.error:
        return _ChipColors(
          background: const Color(0xFFEF4444).withValues(alpha: 0.12),
          foreground: const Color(0xFFDC2626),
        );
      case ChipType.neutral:
        return _ChipColors(
          background: const Color(0xFF6B7280).withValues(alpha: 0.12),
          foreground: const Color(0xFF6B7280),
        );
    }
  }
}

class _ChipColors {
  final Color background;
  final Color foreground;
  const _ChipColors({required this.background, required this.foreground});
}
