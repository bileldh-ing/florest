import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'line_icon.dart';

/// 52pt circle with a 24pt outline icon. [filled] adds the translucent fill.
/// The tap target is never smaller than 48x48.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    this.filled = false,
    this.scale = 1,
  });

  final LineGlyph icon;
  final String semanticLabel;
  final VoidCallback onTap;
  final bool filled;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final d = 52 * scale;
    final hit = math.max(48.0, d);
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: hit,
          height: hit,
          child: Center(
            child: Container(
              width: d,
              height: d,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: filled ? AppColors.translucent : null,
                shape: BoxShape.circle,
              ),
              child: LineIcon(icon, size: 24 * scale, color: AppColors.cream),
            ),
          ),
        ),
      ),
    );
  }
}
