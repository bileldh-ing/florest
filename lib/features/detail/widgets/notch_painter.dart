import 'package:flutter/widgets.dart';

/// Paints the white side rail with a green "notch" around the selected
/// thumbnail. The notch merges into the green canvas: the rail's corners just
/// above and below it are rounded outward (concave from the notch's side),
/// and the notch's own left corners are rounded. The notch's Y follows a
/// spring-animated index and the rail's scroll offset.
class NotchPainter extends CustomPainter {
  NotchPainter({
    required this.notch,
    required this.scroll,
    required this.itemExtent,
    required this.padTop,
    required this.inset,
    required this.radius,
    required this.color,
  }) : super(repaint: Listenable.merge([notch, scroll]));

  final Animation<double> notch;
  final ScrollController scroll;
  final double itemExtent;
  final double padTop;
  final double inset;
  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final offset = scroll.hasClients ? scroll.offset : 0.0;
    final ny = padTop + notch.value * itemExtent - offset;
    final path = buildRailPath(size, ny, itemExtent, inset, radius);
    canvas
      ..save()
      ..clipRect(Offset.zero & size)
      ..drawPath(path, Paint()..color = color..isAntiAlias = true)
      ..restore();
  }

  @override
  bool shouldRepaint(NotchPainter oldDelegate) =>
      oldDelegate.notch != notch ||
      oldDelegate.scroll != scroll ||
      oldDelegate.itemExtent != itemExtent ||
      oldDelegate.padTop != padTop ||
      oldDelegate.inset != inset ||
      oldDelegate.radius != radius ||
      oldDelegate.color != color;
}

/// Rail outline (clockwise from top-left). [ny]/[nh] is the notch band.
Path buildRailPath(Size size, double ny, double nh, double inset, double r) {
  final w = size.width;
  const top = 0.0;
  final bottom = size.height;
  final path = Path()..moveTo(0, top);

  // Upper white segment: rounded top-right, then a convex corner that turns
  // into the notch.
  final a = ny - top;
  final r1 = (a / 2).clamp(0.0, r);
  if (a > 0.5) {
    path
      ..lineTo(w - r1, top)
      ..arcToPoint(Offset(w, top + r1), radius: Radius.circular(r1))
      ..lineTo(w, ny - r1)
      ..arcToPoint(Offset(w - r1, ny), radius: Radius.circular(r1));
  }

  // The notch itself: rounded top-left and bottom-left (counter-clockwise).
  final rn = (nh / 2).clamp(0.0, r);
  path
    ..lineTo(inset + rn, ny)
    ..arcToPoint(Offset(inset, ny + rn), radius: Radius.circular(rn), clockwise: false)
    ..lineTo(inset, ny + nh - rn)
    ..arcToPoint(Offset(inset + rn, ny + nh),
        radius: Radius.circular(rn), clockwise: false);

  // Lower white segment.
  final b = bottom - (ny + nh);
  final r2 = (b / 2).clamp(0.0, r);
  if (b > 0.5) {
    path
      ..lineTo(w - r2, ny + nh)
      ..arcToPoint(Offset(w, ny + nh + r2), radius: Radius.circular(r2))
      ..lineTo(w, bottom - r2)
      ..arcToPoint(Offset(w - r2, bottom), radius: Radius.circular(r2));
  }
  path
    ..lineTo(0, bottom)
    ..close();
  return path;
}
