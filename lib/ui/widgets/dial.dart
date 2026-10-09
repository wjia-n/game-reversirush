import 'package:flutter/material.dart';

import '../../theme/club_theme.dart';

/// Stopwatch timer chip: cream digits on ebonite black inside a brass bezel.
/// Racing crimson hand/digits under urgency.
class StopwatchChip extends StatelessWidget {
  final String text;
  final bool urgent;
  final String caption;

  const StopwatchChip(
      {super.key, required this.text, this.urgent = false, required this.caption});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Club.ebonite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: urgent ? Club.crimson : Club.brass, width: 2.5),
        boxShadow: const [
          BoxShadow(
              color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer,
                  size: 16,
                  color: urgent ? Club.crimson : Club.brassHi),
              const SizedBox(width: 6),
              Text(text,
                  style: Club.numeral(20,
                      color: urgent ? Club.crimson : Club.cream)),
            ],
          ),
          Text(caption,
              style: Club.label(9,
                  color: (urgent ? Club.crimson : Club.brassHi)
                      .withValues(alpha: 0.9),
                  spacing: 2.0)),
        ],
      ),
    );
  }
}

/// Score tally styled as a rally registration card.
class ScoreCard extends StatelessWidget {
  final String name;
  final int discs;
  final int color; // 1 black, 2 white
  final bool active;
  final String? sub;

  const ScoreCard({
    super.key,
    required this.name,
    required this.discs,
    required this.color,
    this.active = false,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Club.cream : Club.cardstock,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: active ? Club.crimson : Club.brass,
              width: active ? 2.5 : 1.5),
          boxShadow: Club.contactShadow(blur: 6, dy: 3),
        ),
        child: Row(
          children: [
            _MiniDisc(black: color == 1),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name,
                      style: Club.label(11,
                          color: active ? Club.crimson : Club.darkTeak,
                          spacing: 1.6)),
                  if (sub != null)
                    Text(sub!,
                        style: Club.bodyText(10,
                            color: Club.darkTeak.withValues(alpha: 0.6))),
                ],
              ),
            ),
            Text('$discs', style: Club.numeral(24)),
          ],
        ),
      ),
    );
  }
}

/// Tiny enamel disc for score cards.
class _MiniDisc extends StatelessWidget {
  final bool black;
  const _MiniDisc({required this.black});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.4),
          colors: [
            black ? const Color(0xFF3A3A3A) : Colors.white,
            black ? const Color(0xFF161616) : Club.ivory,
          ],
        ),
        border: Border.all(color: Club.brass, width: 1.5),
        boxShadow: const [
          BoxShadow(
              color: Color(0x55000000), blurRadius: 3, offset: Offset(0, 2)),
        ],
      ),
    );
  }
}

/// Bottom action bar: UNDO / HINT / SETTINGS style brass buttons row.
class ClubActionBar extends StatelessWidget {
  final List<Widget> children;
  const ClubActionBar({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            Expanded(child: children[i]),
            if (i < children.length - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

/// Small brass action button for the bottom bar.
class BarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool highlighted;

  const BarButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: () {
        if (enabled) onTap!();
      },
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: highlighted ? Club.teak : Club.cardstock,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Club.brass, width: 2),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x55000000),
                  blurRadius: 5,
                  offset: Offset(0, 3)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 20,
                  color: highlighted ? Club.cream : Club.darkTeak),
              const SizedBox(height: 2),
              Text(label,
                  style: Club.label(10,
                      color: highlighted ? Club.cream : Club.darkTeak,
                      spacing: 1.8)),
            ],
          ),
        ),
      ),
    );
  }
}
