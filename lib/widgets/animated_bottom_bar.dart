// Source - https://stackoverflow.com/q/72553177
// Posted by Patrick Obafemi
// Retrieved 2026-06-27, License - CC BY-SA 4.0

import 'package:flutter/material.dart';
import '../models/icon_model.dart';

class AnimatedBottomBar extends StatelessWidget {
  final int currentIcon;
  final List<IconModel> icons;
  final ValueChanged<int>? onTap;

  const AnimatedBottomBar({
    super.key,
    required this.currentIcon,
    required this.onTap,
    required this.icons,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: icons
              .map(
                (icon) => GestureDetector(
                  onTap: () => onTap?.call(icon.id),
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 900),
                    child: Icon(
                      icon.icon,
                      size: currentIcon == icon.id ? 26 : 23,
                      color: currentIcon == icon.id
                          ? colors.primary
                          : colors.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
