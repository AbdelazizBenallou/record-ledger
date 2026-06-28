import 'package:flutter/material.dart';

class AppAvatar extends StatelessWidget {
  final String name;
  final double radius;
  final String? phone;

  const AppAvatar({
    super.key,
    required this.name,
    this.radius = 24,
    this.phone,
  });

  static const _avatarColors = [
    Color(0xFF4F46E5),
    Color(0xFF059669),
    Color(0xFFD97706),
    Color(0xFF7C3AED),
    Color(0xFF0891B2),
    Color(0xFFDB2777),
    Color(0xFF2563EB),
    Color(0xFFD4D4D8),
  ];

  Color get _color {
    final hash = (name + (phone ?? '')).hashCode.abs();
    return _avatarColors[hash % _avatarColors.length];
  }

  String get _initial {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.15),
      child: Text(
        _initial,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: radius * 0.75,
        ),
      ),
    );
  }
}
