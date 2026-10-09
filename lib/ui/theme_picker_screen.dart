import 'package:flutter/material.dart';

import '../audio/club_audio.dart';
import '../state/club_state.dart';
import '../theme/club_theme.dart';
import '../theme/rush_themes.dart';
import 'widgets/brass_widgets.dart';

/// Table themes (12) + disc pours (9) + custom creators. Everything is
/// persisted; the board repaints instantly.
class ThemePickerScreen extends StatefulWidget {
  final ClubSettings settings;
  final ClubAudio audio;
  final VoidCallback onBack;

  const ThemePickerScreen({
    super.key,
    required this.settings,
    required this.audio,
    required this.onBack,
  });

  @override
  State<ThemePickerScreen> createState() => _ThemePickerScreenState();
}

class _ThemePickerScreenState extends State<ThemePickerScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    return ListenableBuilder(
      listenable: settings,
      builder: (_, _) => Scaffold(
        backgroundColor: Club.cream,
        body: Column(
          children: [
            ClubHeader(
              title: 'TABLE & DISCS',
              sub: 'DRESS THE CLUB',
              trailing: BrassIconButton(
                icon: Icons.check,
                onTap: () {
                  widget.audio.play(ClubSound.click);
                  widget.onBack();
                },
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle('TABLE THEME'),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.86,
                      ),
                      itemCount: RushThemes.catalog.length + 1,
                      itemBuilder: (_, i) {
                        if (i == RushThemes.catalog.length) {
                          return _ThemeCard(
                            name: 'Custom',
                            field: settings.customTheme.isEmpty
                                ? Club.teak
                                : Color(settings.customTheme['field'] ??
                                    0xFF543018),
                            grid: settings.customTheme.isEmpty
                                ? Club.brass
                                : Color(settings.customTheme['grid'] ??
                                    0xFFC89B3C),
                            selected: settings.themeId == 'custom',
                            onTap: () {
                              widget.audio.play(ClubSound.click);
                              _customThemeSheet();
                            },
                          );
                        }
                        final t = RushThemes.catalog[i];
                        return _ThemeCard(
                          name: t.name,
                          field: t.field,
                          grid: t.grid,
                          selected: settings.themeId == t.id,
                          onTap: () {
                            widget.audio.play(ClubSound.click);
                            settings.setTheme(t.id);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    _SectionTitle('DISC POUR'),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.86,
                      ),
                      itemCount: DiscStyles.catalog.length + 1,
                      itemBuilder: (_, i) {
                        if (i == DiscStyles.catalog.length) {
                          final custom = settings.customDisc.isEmpty
                              ? null
                              : DiscStyle.customFrom(settings.customDisc);
                          return _DiscCard(
                            name: 'Custom',
                            style: custom ?? DiscStyles.enamel,
                            selected: settings.discStyleId == 'custom',
                            onTap: () {
                              widget.audio.play(ClubSound.click);
                              _customDiscSheet();
                            },
                          );
                        }
                        final d = DiscStyles.catalog[i];
                        return _DiscCard(
                          name: d.name,
                          style: d,
                          selected: settings.discStyleId == d.id,
                          onTap: () {
                            widget.audio.play(ClubSound.click);
                            settings.setDiscStyle(d.id);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _customThemeSheet() {
    final settings = widget.settings;
    final base = settings.customTheme.isEmpty
        ? RushThemes.teakClassic.toJson()
        : Map<String, int>.of(settings.customTheme);
    Color field = Color(base['field']!);
    Color grid = Color(base['grid']!);
    showModalBottomSheet(
      context: context,
      backgroundColor: Club.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('CUSTOM TABLE', style: Club.label(15, spacing: 2.6)),
              const SizedBox(height: 12),
              _ColorRow(
                label: 'TABLE FELT',
                color: field,
                onPick: (c) => setSheet(() => field = c),
              ),
              _ColorRow(
                label: 'INLAY GRID',
                color: grid,
                onPick: (c) => setSheet(() => grid = c),
              ),
              const SizedBox(height: 14),
              BrassButton(
                label: 'POUR THE TABLE',
                primary: true,
                onTap: () {
                  widget.audio.play(ClubSound.click);
                  settings.setCustomTheme({
                    'field': field.toARGB32(),
                    'fieldAlt': field.withValues(alpha: 0.08).toARGB32(),
                    'grid': grid.toARGB32(),
                    'hint': grid.toARGB32(),
                    'frame': const Color(0xFF2A1D12).toARGB32(),
                    'grain': const Color(0x14000000).toARGB32(),
                  });
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _customDiscSheet() {
    final settings = widget.settings;
    Color black = settings.customDisc.isEmpty
        ? DiscStyles.enamel.blackFace
        : Color(settings.customDisc['blackFace']!);
    Color white = settings.customDisc.isEmpty
        ? DiscStyles.enamel.whiteFace
        : Color(settings.customDisc['whiteFace']!);
    showModalBottomSheet(
      context: context,
      backgroundColor: Club.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('CUSTOM DISC POUR', style: Club.label(15, spacing: 2.6)),
              const SizedBox(height: 12),
              _ColorRow(
                label: 'DARK FACE',
                color: black,
                onPick: (c) => setSheet(() => black = c),
              ),
              _ColorRow(
                label: 'LIGHT FACE',
                color: white,
                onPick: (c) => setSheet(() => white = c),
              ),
              const SizedBox(height: 14),
              BrassButton(
                label: 'POUR THE DISCS',
                primary: true,
                onTap: () {
                  widget.audio.play(ClubSound.click);
                  settings.setCustomDisc({
                    'blackFace': black.toARGB32(),
                    'whiteFace': white.toARGB32(),
                  });
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: Club.label(12,
                color: Club.darkTeak.withValues(alpha: 0.65), spacing: 2.4)),
      );
}

class _ThemeCard extends StatelessWidget {
  final String name;
  final Color field;
  final Color grid;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.name,
    required this.field,
    required this.grid,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? Club.crimson : Club.brass,
              width: selected ? 3 : 1.5),
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
                child: Container(
                  color: field,
                  child: CustomPaint(
                    painter: _MiniGrid(grid),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Club.label(9,
                    color: selected ? Club.crimson : Club.darkTeak,
                    spacing: 1.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniGrid extends CustomPainter {
  final Color grid;
  _MiniGrid(this.grid);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = grid.withValues(alpha: 0.7)
      ..strokeWidth = 1;
    for (var k = 1; k < 4; k++) {
      canvas.drawLine(
          Offset(size.width * k / 4, 0), Offset(size.width * k / 4, size.height), p);
      canvas.drawLine(
          Offset(0, size.height * k / 4), Offset(size.width, size.height * k / 4), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _DiscCard extends StatelessWidget {
  final String name;
  final DiscStyle style;
  final bool selected;
  final VoidCallback onTap;

  const _DiscCard({
    required this.name,
    required this.style,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Club.cardstock,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? Club.crimson : Club.brass,
              width: selected ? 3 : 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MiniDisc(color: style.blackFace, rim: style.rim),
                const SizedBox(width: 6),
                _MiniDisc(color: style.whiteFace, rim: style.rim),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Club.label(9,
                    color: selected ? Club.crimson : Club.darkTeak,
                    spacing: 1.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniDisc extends StatelessWidget {
  final Color color;
  final Color rim;
  const _MiniDisc({required this.color, required this.rim});

  @override
  Widget build(BuildContext context) => Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: rim, width: 1.5),
          boxShadow: const [
            BoxShadow(color: Color(0x55000000), blurRadius: 4, offset: Offset(1, 2)),
          ],
        ),
      );
}

class _ColorRow extends StatelessWidget {
  final String label;
  final Color color;
  final ValueChanged<Color> onPick;

  const _ColorRow({
    required this.label,
    required this.color,
    required this.onPick,
  });

  static const _swatches = [
    0xFF543018,
    0xFF3E2415,
    0xFF6B2A1A,
    0xFF4A1F14,
    0xFF8A5A28,
    0xFF4E463C,
    0xFF2E4034,
    0xFF3A3F45,
    0xFF5E2318,
    0xFFEFE9D9,
    0xFFC89B3C,
    0xFFDFB75A,
    0xFF1E1E1E,
    0xFFFAFAF7,
    0xFFB93829,
    0xFF2A1D12,
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Club.brass, width: 2),
                ),
              ),
              const SizedBox(width: 10),
              Text(label, style: Club.label(12, spacing: 2.0)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in _swatches)
                GestureDetector(
                  onTap: () => onPick(Color(s)),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Color(s),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.toARGB32() == s ? Club.crimson : Club.hairline,
                        width: color.toARGB32() == s ? 3 : 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
