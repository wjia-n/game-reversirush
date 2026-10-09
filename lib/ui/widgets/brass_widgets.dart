import 'package:flutter/material.dart';

import '../../theme/club_theme.dart';

/// Mechanical dash button: 2px solid brass border, bottom bevel,
/// press shifts down 2px with reduced shadow.
class BrassButton extends StatefulWidget {
  final String label;
  final String? sublabel;
  final VoidCallback? onTap;
  final bool primary;
  final bool danger;
  final double height;
  final Widget? leading;

  const BrassButton({
    super.key,
    required this.label,
    this.sublabel,
    this.onTap,
    this.primary = false,
    this.danger = false,
    this.height = 64,
    this.leading,
  });

  @override
  State<BrassButton> createState() => _BrassButtonState();
}

class _BrassButtonState extends State<BrassButton> {
  bool _pressed = false;

  Color get _fill {
    if (widget.danger) return Club.crimson;
    if (widget.primary) return Club.teak;
    return Club.cardstock;
  }

  Color get _text => widget.primary || widget.danger ? Club.cream : Club.darkTeak;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: () => setState(() => _pressed = false),
      onTap: enabled
          ? () {
              setState(() => _pressed = false);
              widget.onTap!();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        height: widget.height,
        transform: Matrix4.translationValues(0, _pressed ? 2 : 0, 0),
        decoration: BoxDecoration(
          color: enabled ? _fill : Club.hairline,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Club.brass, width: 2),
          boxShadow: _pressed
              ? [
                  const BoxShadow(
                      color: Color(0x55000000),
                      blurRadius: 3,
                      offset: Offset(0, 1)),
                ]
              : [
                  const BoxShadow(
                      color: Color(0x77000000),
                      blurRadius: 8,
                      offset: Offset(0, 5)),
                  const BoxShadow(
                      color: Club.brassHi,
                      blurRadius: 0,
                      offset: Offset(0, -1)),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.leading != null) ...[
              widget.leading!,
              const SizedBox(width: 10),
            ],
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.label,
                    style: Club.label(18, color: _text, spacing: 2.6)),
                if (widget.sublabel != null)
                  Text(widget.sublabel!,
                      style: Club.bodyText(11,
                          color: _text.withValues(alpha: 0.75))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Heavy brass lever articulating between ivory and black wells.
class LeverToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final double width;

  const LeverToggle(
      {super.key, required this.value, required this.onChanged, this.width = 64});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: width,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: Club.brass, width: 2),
          gradient: const LinearGradient(
            colors: [Club.ivory, Club.ebonite],
            stops: [0.49, 0.51],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: const [
            BoxShadow(
                color: Color(0x66000000), blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutBack,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 30,
                height: 30,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Club.brass,
                  border: Border.all(color: Club.brassHi, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x88000000),
                        blurRadius: 4,
                        offset: Offset(0, 2)),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.circle, size: 8, color: Club.darkTeak),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Machined brass volume gauge.
class VolumeGauge extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const VolumeGauge({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      return GestureDetector(
        onHorizontalDragUpdate: (d) {
          onChanged(((d.localPosition.dx) / w).clamp(0.0, 1.0));
        },
        onTapDown: (d) {
          onChanged((d.localPosition.dx / w).clamp(0.0, 1.0));
        },
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Club.ebonite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Club.brass, width: 2),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x55000000),
                  blurRadius: 6,
                  offset: Offset(0, 3)),
            ],
          ),
          child: Stack(
            children: [
              // tick marks
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      11,
                      (i) => Container(
                        width: 2,
                        height: i % 5 == 0 ? 12 : 7,
                        color: Club.brass.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ),
              // needle
              Positioned(
                left: 14 + value * (w - 28 - 10),
                top: 5,
                child: Container(
                  width: 10,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Club.crimson,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Club.brassHi, width: 1),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

/// "YOUR TURN" style ribbon banner.
class ClubRibbon extends StatelessWidget {
  final String text;
  final Color color;

  const ClubRibbon({super.key, required this.text, this.color = Club.crimson});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color,
        border: const Border(
          top: BorderSide(color: Club.brass, width: 2),
          bottom: BorderSide(color: Club.brass, width: 2),
        ),
        boxShadow: const [
          BoxShadow(
              color: Color(0x55000000), blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Club.label(15, color: Club.cream, spacing: 3.0),
      ),
    );
  }
}

/// Rally registration card: cream face, double-ruled brass hairline borders.
class RallyCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const RallyCard(
      {super.key, required this.child, this.padding = const EdgeInsets.all(14)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Club.cream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Club.brass, width: 2),
        boxShadow: Club.contactShadow(),
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: Club.hairline, width: 1.5),
        ),
        child: child,
      ),
    );
  }
}

/// Brass header bar used on menu / settings / records.
class ClubHeader extends StatelessWidget {
  final String title;
  final String? sub;
  final Widget? trailing;

  const ClubHeader({super.key, required this.title, this.sub, this.trailing});

  @override
  Widget build(BuildContext context) {
    final Widget? subtitle = sub == null
        ? null
        : Text(sub!,
            style: Club.label(11, color: Club.brassHi, spacing: 2.4));
    final Widget? action = trailing;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      decoration: const BoxDecoration(
        color: Club.teak,
        border: Border(bottom: BorderSide(color: Club.brass, width: 3)),
        boxShadow: [
          BoxShadow(
              color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Club.hDisplay(26, color: Club.cream)),
                  ?subtitle,
                ],
              ),
            ),
            ?action,
          ],
        ),
      ),
    );
  }
}

/// Small square brass icon button (settings gear, pause, etc.).
class BrassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;

  const BrassIconButton(
      {super.key, required this.icon, this.onTap, this.size = 46});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Club.cardstock,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Club.brass, width: 2),
          boxShadow: const [
            BoxShadow(
                color: Color(0x66000000), blurRadius: 5, offset: Offset(0, 3)),
          ],
        ),
        child: Icon(icon,
            color: onTap == null ? Club.hairline : Club.darkTeak, size: 22),
      ),
    );
  }
}
