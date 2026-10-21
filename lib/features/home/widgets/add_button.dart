import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme.dart';

/// White 62pt rounded square with a "+" that spins into a check mark while
/// [onAdd] runs, then settles back.
class AddButton extends StatefulWidget {
  const AddButton({super.key, required this.onAdd, this.size = 62});

  final Future<void> Function() onAdd;
  final double size;

  @override
  State<AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<AddButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  late final Animation<double> _curve =
      CurvedAnimation(parent: _c, curve: Curves.easeOutBack, reverseCurve: Curves.easeInCubic);
  late final Animation<double> _plusTurns =
      Tween<double>(begin: 0, end: 0.25).animate(_curve);
  late final Animation<double> _checkTurns =
      Tween<double>(begin: -0.25, end: 0).animate(_curve);
  late final Animation<double> _plusFade = ReverseAnimation(
      CurvedAnimation(parent: _c, curve: const Interval(0, 0.6)));
  late final Animation<double> _checkFade =
      CurvedAnimation(parent: _c, curve: const Interval(0.3, 1));
  bool _busy = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_busy) return;
    _busy = true;
    HapticFeedback.lightImpact();
    _c.forward();
    await widget.onAdd();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) await _c.reverse();
    _busy = false;
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final iconSize = size * 0.5;
    return Semantics(
      button: true,
      label: 'Add to bag',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadii.addButton * size / 62),
            boxShadow: const [
              BoxShadow(color: Color(0x22000000), blurRadius: 14, offset: Offset(0, 6)),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              FadeTransition(
                opacity: _plusFade,
                child: RotationTransition(
                  turns: _plusTurns,
                  child: Icon(Icons.add_rounded, size: iconSize, color: AppColors.ink),
                ),
              ),
              FadeTransition(
                opacity: _checkFade,
                child: RotationTransition(
                  turns: _checkTurns,
                  child: Icon(Icons.check_rounded, size: iconSize, color: AppColors.green),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
