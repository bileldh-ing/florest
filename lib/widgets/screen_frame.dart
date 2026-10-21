import 'package:flutter/widgets.dart';

import '../core/theme.dart';

/// Clips a screen to the 40pt rounded "phone" outline from the reference.
/// Set [clipCorners] to false to render edge to edge.
class ScreenFrame extends StatelessWidget {
  const ScreenFrame({super.key, required this.child, this.clipCorners = true});

  final Widget child;
  final bool clipCorners;

  @override
  Widget build(BuildContext context) {
    if (!clipCorners) return child;
    return ColoredBox(
      color: AppColors.ink,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.phone),
        child: child,
      ),
    );
  }
}
