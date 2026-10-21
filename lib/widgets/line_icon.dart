import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The thin, round-capped glyphs from the reference design, drawn on a 24×24
/// grid. Material's icon font is heavier and rounder than the mock, so the app
/// paints its own.
enum LineGlyph {
  search,
  bag,
  back,
  chevronDown,
  plus,
  minus,
  check,
  drop,
  thermometer,
  sun,
  close,
}

class LineIcon extends StatelessWidget {
  const LineIcon(
    this.glyph, {
    super.key,
    this.size = 24,
    required this.color,
    this.strokeWidth = 1.6,
  });

  final LineGlyph glyph;
  final double size;
  final Color color;

  /// Stroke in grid units (the icon is drawn on a 24-unit grid, then scaled).
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _LineIconPainter(glyph, color, strokeWidth),
      ),
    );
  }
}

class _LineIconPainter extends CustomPainter {
  _LineIconPainter(this.glyph, this.color, this.strokeWidth);

  final LineGlyph glyph;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.shortestSide / 24;
    canvas.scale(k);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(lineGlyphPath(glyph), paint);
  }

  @override
  bool shouldRepaint(_LineIconPainter old) =>
      old.glyph != glyph ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}

/// Glyph outlines on the 24-unit grid.
Path lineGlyphPath(LineGlyph glyph) {
  switch (glyph) {
    case LineGlyph.search:
      return Path()
        ..addOval(
          Rect.fromCircle(center: const Offset(10.8, 10.8), radius: 6.6),
        )
        ..moveTo(15.6, 15.6)
        ..lineTo(20.2, 20.2);
    case LineGlyph.bag:
      return Path()
        ..addRRect(
          RRect.fromLTRBR(4.6, 8, 19.4, 20.6, const Radius.circular(2.2)),
        )
        ..moveTo(8.6, 10.6)
        ..lineTo(8.6, 7)
        ..arcToPoint(const Offset(15.4, 7), radius: const Radius.circular(3.4))
        ..lineTo(15.4, 10.6);
    case LineGlyph.back:
      return Path()
        ..moveTo(14.5, 5)
        ..lineTo(7.5, 12)
        ..lineTo(14.5, 19);
    case LineGlyph.chevronDown:
      return Path()
        ..moveTo(5, 9)
        ..lineTo(12, 16)
        ..lineTo(19, 9);
    case LineGlyph.plus:
      return Path()
        ..moveTo(12, 4.5)
        ..lineTo(12, 19.5)
        ..moveTo(4.5, 12)
        ..lineTo(19.5, 12);
    case LineGlyph.minus:
      return Path()
        ..moveTo(5, 12)
        ..lineTo(19, 12);
    case LineGlyph.check:
      return Path()
        ..moveTo(5, 12.6)
        ..lineTo(9.8, 17.4)
        ..lineTo(19, 7.4);
    case LineGlyph.close:
      return Path()
        ..moveTo(6, 6)
        ..lineTo(18, 18)
        ..moveTo(18, 6)
        ..lineTo(6, 18);
    case LineGlyph.drop:
      return Path()
        ..moveTo(12, 3.6)
        ..cubicTo(12, 3.6, 5.8, 10.4, 5.8, 14.6)
        ..arcToPoint(
          const Offset(18.2, 14.6),
          radius: const Radius.circular(6.2),
          clockwise: false,
        )
        ..cubicTo(18.2, 10.4, 12, 3.6, 12, 3.6)
        ..close()
        // Small highlight inside the drop, as in the mock.
        ..moveTo(9.2, 14.8)
        ..arcToPoint(
          const Offset(11.6, 17.4),
          radius: const Radius.circular(2.8),
          clockwise: false,
        );
    case LineGlyph.thermometer:
      return Path()
        ..moveTo(10, 13.6)
        ..lineTo(10, 5.6)
        ..arcToPoint(const Offset(14, 5.6), radius: const Radius.circular(2))
        ..lineTo(14, 13.6)
        ..arcToPoint(
          const Offset(10, 13.6),
          radius: const Radius.circular(3.9),
          largeArc: true,
        )
        ..close()
        ..moveTo(12, 9)
        ..lineTo(12, 16.4);
    case LineGlyph.sun:
      final p = Path()
        ..addOval(Rect.fromCircle(center: const Offset(12, 12), radius: 3.6));
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4;
        p
          ..moveTo(12 + 6.4 * math.cos(a), 12 + 6.4 * math.sin(a))
          ..lineTo(12 + 8.6 * math.cos(a), 12 + 8.6 * math.sin(a));
      }
      return p;
  }
}
