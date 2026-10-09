import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/club_theme.dart';

/// The club board: oiled teak veneer, brass inlay grid, hand-poured enamel
/// discs with 1px brass rims. Light from top-left at 45°.
class ClubBoard extends StatefulWidget {
  final List<int> cells; // 64: 0 empty, 1 black, 2 white
  final Set<int> legal;
  final bool showHints;
  final int? justPlaced;
  final Set<int> justFlipped;
  final int animGen;
  final int hintPulseIndex;
  final int hintPulseGen;
  final int shakeIndex;
  final int shakeGen;
  final bool interactive;
  final void Function(int index)? onTap;

  const ClubBoard({
    super.key,
    required this.cells,
    required this.legal,
    this.showHints = true,
    this.justPlaced,
    this.justFlipped = const {},
    this.animGen = 0,
    this.hintPulseIndex = -1,
    this.hintPulseGen = 0,
    this.shakeIndex = -1,
    this.shakeGen = 0,
    this.interactive = true,
    this.onTap,
  });

  @override
  State<ClubBoard> createState() => _ClubBoardState();
}

class _ClubBoardState extends State<ClubBoard> with TickerProviderStateMixin {
  late final AnimationController _flip;
  late final AnimationController _pulse;
  late final AnimationController _shake;
  int _seenAnim = -1;
  int _seenPulse = -1;
  int _seenShake = -1;

  @override
  void initState() {
    super.initState();
    _flip = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
    _shake = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));
    _seenAnim = widget.animGen;
    _seenPulse = widget.hintPulseGen;
    _seenShake = widget.shakeGen;
  }

  @override
  void didUpdateWidget(ClubBoard old) {
    super.didUpdateWidget(old);
    if (widget.animGen != _seenAnim) {
      _seenAnim = widget.animGen;
      _flip.forward(from: 0);
    }
    if (widget.hintPulseGen != _seenPulse && widget.hintPulseGen >= 0) {
      _seenPulse = widget.hintPulseGen;
      _pulse.forward(from: 0);
    }
    if (widget.shakeGen != _seenShake && widget.shakeGen >= 0) {
      _seenShake = widget.shakeGen;
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _flip.dispose();
    _pulse.dispose();
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Club.brass, width: 3),
          boxShadow: const [
            BoxShadow(
                color: Color(0x77000000), blurRadius: 18, offset: Offset(0, 8)),
            BoxShadow(
                color: Club.brassHi, blurRadius: 0, offset: Offset(0, -2)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: GestureDetector(
            onTapUp: widget.interactive && widget.onTap != null
                ? (d) {
                    final box = context.findRenderObject() as RenderBox;
                    final local = box.globalToLocal(d.globalPosition);
                    final cell = local.dx / box.size.width * 8;
                    final row = local.dy / box.size.height * 8;
                    final ci = cell.floor(), ri = row.floor();
                    if (ci >= 0 && ci < 8 && ri >= 0 && ri < 8) {
                      widget.onTap!(ri * 8 + ci);
                    }
                  }
                : null,
            child: AnimatedBuilder(
              animation: Listenable.merge([_flip, _pulse, _shake]),
              builder: (_, _) => CustomPaint(
                painter: _BoardPainter(
                  cells: widget.cells,
                  legal: widget.legal,
                  showHints: widget.showHints,
                  justPlaced: widget.justPlaced,
                  justFlipped: widget.justFlipped,
                  flipT: _flip.value,
                  hintPulseIndex: widget.hintPulseIndex,
                  hintT: _pulse.value,
                  shakeIndex: widget.shakeIndex,
                  shakeT: _shake.value,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  final List<int> cells;
  final Set<int> legal;
  final bool showHints;
  final int? justPlaced;
  final Set<int> justFlipped;
  final double flipT;
  final int hintPulseIndex;
  final double hintT;
  final int shakeIndex;
  final double shakeT;

  _BoardPainter({
    required this.cells,
    required this.legal,
    required this.showHints,
    required this.justPlaced,
    required this.justFlipped,
    required this.flipT,
    required this.hintPulseIndex,
    required this.hintT,
    required this.shakeIndex,
    required this.shakeT,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cell = w / 8;

    // Teak veneer field.
    final bg = Paint()..color = Club.teak;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bg);

    // Subtle wood grain streaks.
    final grain = Paint()
      ..color = const Color(0x14000000)
      ..strokeWidth = 1.5;
    final grng = Random(7);
    for (var k = 0; k < 26; k++) {
      final y = grng.nextDouble() * h;
      canvas.drawLine(Offset(0, y), Offset(w, y + grng.nextDouble() * 8 - 4), grain);
    }

    // Inset deboss: dark inner top-left, light bottom-right.
    canvas.drawRect(
        Rect.fromLTWH(0, 0, w, 10),
        Paint()
          ..color = const Color(0x55000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawRect(
        Rect.fromLTWH(0, h - 10, w, 10),
        Paint()
          ..color = const Color(0x22FFFFFF)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));

    // Alternating teak cells + brass inlay grid.
    for (var r = 0; r < 8; r++) {
      for (var c = 0; c < 8; c++) {
        if ((r + c).isEven) {
          canvas.drawRect(
              Rect.fromLTWH(c * cell, r * cell, cell, cell),
              Paint()..color = const Color(0x0DFFFFFF));
        }
      }
    }
    final grid = Paint()
      ..color = Club.brass.withValues(alpha: 0.55)
      ..strokeWidth = 1.5;
    for (var k = 1; k < 8; k++) {
      canvas.drawLine(Offset(k * cell, 0), Offset(k * cell, h), grid);
      canvas.drawLine(Offset(0, k * cell), Offset(w, k * cell), grid);
    }

    // Coordinate labels (a–h, 1–8).
    final labelStyle = TextStyle(
      fontFamily: Club.condensed,
      fontWeight: FontWeight.w600,
      fontSize: cell * 0.22,
      color: Club.brassHi.withValues(alpha: 0.8),
      letterSpacing: 1,
    );
    for (var c = 0; c < 8; c++) {
      _drawLabel(canvas, String.fromCharCode(97 + c),
          Offset(c * cell + cell / 2, cell * 0.09), labelStyle);
    }
    for (var r = 0; r < 8; r++) {
      _drawLabel(canvas, '${r + 1}', Offset(cell * 0.09, r * cell + cell / 2),
          labelStyle);
    }

    // Hint dots: faint translucent brass watermark rings — never digital glow.
    if (showHints) {
      final hint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Club.brass.withValues(alpha: 0.45);
      final dot = Paint()..color = Club.brass.withValues(alpha: 0.30);
      for (final i in legal) {
        final cx = (i % 8) * cell + cell / 2;
        final cy = (i ~/ 8) * cell + cell / 2;
        canvas.drawCircle(Offset(cx, cy), cell * 0.16, hint);
        canvas.drawCircle(Offset(cx, cy), cell * 0.05, dot);
      }
    }

    // Hint pulse ring.
    if (hintPulseIndex >= 0) {
      final cx = (hintPulseIndex % 8) * cell + cell / 2;
      final cy = (hintPulseIndex ~/ 8) * cell + cell / 2;
      final pr = cell * (0.2 + 0.28 * hintT);
      canvas.drawCircle(
          Offset(cx, cy),
          pr,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = Club.brassHi.withValues(alpha: 0.9 * (1 - hintT)));
    }

    // Discs.
    for (var i = 0; i < 64; i++) {
      final v = cells[i];
      if (v == 0) continue;
      final cx = (i % 8) * cell + cell / 2;
      var cy = (i ~/ 8) * cell + cell / 2;
      final R = cell * 0.40;

      double scaleX = 1, scaleY = 1;
      int shown = v;
      double lift = 0;
      if (i == justPlaced) {
        // Weighted drop: overshoot settle.
        final t = flipT.clamp(0.0, 1.0);
        final s = t < 0.7
            ? Curves.easeOut.transform(t / 0.7)
            : 1 + 0.12 * sin((t - 0.7) / 0.3 * pi);
        scaleX = scaleY = s;
        lift = (1 - t) * R * 1.6;
        cy -= lift;
      } else if (justFlipped.contains(i)) {
        // Flip: lift, widen blur, +4% scale, swap face at midpoint.
        final t = flipT.clamp(0.0, 1.0);
        scaleX = cos(t * pi).abs().clamp(0.08, 1.0);
        scaleY = 1 + 0.04 * sin(t * pi);
        shown = t < 0.5 ? 3 - v : v;
        lift = sin(t * pi) * R * 1.2;
        cy -= lift;
      }
      var dx = 0.0;
      if (i == shakeIndex && shakeT < 1) {
        dx = sin(shakeT * pi * 5) * (1 - shakeT) * cell * 0.08;
      }
      _drawDisc(canvas, Offset(cx + dx, cy), R, shown, scaleX, scaleY, lift);
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset center, TextStyle style) {
    final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawDisc(
      Canvas canvas, Offset c, double r, int color, double sx, double sy, double lift) {
    // Weighted contact shadow (widens while flipping).
    canvas.drawOval(
        Rect.fromCenter(
            center: c + Offset(r * 0.18, r * 0.42 + lift * 0.25),
            width: r * 2 * sx * (1 + lift / r * 0.35),
            height: r * 0.62 * (1 + lift / r * 0.3)),
        Paint()
          ..color = const Color(0x66000000)
          ..maskFilter =
              MaskFilter.blur(BlurStyle.normal, 4 + lift / r * 6));

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(sx, sy);

    final dark = color == 1;
    final base = dark ? const Color(0xFF1E1E1E) : Club.ivory;
    final edge = dark ? const Color(0xFF0C0C0C) : const Color(0xFFE4DCC8);

    // Enamel body with top-left light response.
    final body = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.4),
        radius: 1.1,
        colors: [
          dark ? const Color(0xFF3A3A3A) : const Color(0xFFFFFFFF),
          base,
          edge,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
    canvas.drawCircle(Offset.zero, r, body);

    // 1px brass edge rim.
    canvas.drawCircle(
        Offset.zero,
        r - 0.75,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Club.brass);

    // Enamel specular: soft top-left crescent.
    final spec = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = r * 0.16
      ..color = (dark ? Colors.white : const Color(0xFFFFF6E0))
          .withValues(alpha: dark ? 0.28 : 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawArc(
        Rect.fromCircle(center: const Offset(-0.08, -0.1), radius: r * 0.62),
        pi * 1.05,
        pi * 0.55,
        false,
        spec);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BoardPainter old) => true;
}
