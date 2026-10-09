import 'dart:math';

import 'package:flutter/material.dart';

import '../audio/club_audio.dart';
import '../engine/reversi.dart';
import '../services/iap_service.dart';
import '../state/club_state.dart';
import '../theme/club_theme.dart';
import 'widgets/board.dart';
import 'widgets/brass_widgets.dart';

/// Main menu: club logo, board vignette, difficulty selector,
/// PLAY VS AI / TWO PLAYERS / BLITZ MODE brass buttons, table & Pro entries.
class MenuScreen extends StatelessWidget {
  final ClubSettings settings;
  final ClubAudio audio;
  final StoreService store;
  final VoidCallback onPlayVsAi;
  final VoidCallback onTwoPlayers;
  final void Function({required bool vsAi}) onBlitz;
  final VoidCallback onSettings;
  final VoidCallback onRecords;
  final VoidCallback onThemes;
  final VoidCallback onPro;

  const MenuScreen({
    super.key,
    required this.settings,
    required this.audio,
    required this.store,
    required this.onPlayVsAi,
    required this.onTwoPlayers,
    required this.onBlitz,
    required this.onSettings,
    required this.onRecords,
    required this.onThemes,
    required this.onPro,
  });

  void _blitzSheet(BuildContext context) {
    audio.play(ClubSound.click);
    var vsAi = settings.blitzVsAi;
    var minutes = settings.blitzMinutes;
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Text('BLITZ DUEL SETUP',
                      style: Club.label(15, spacing: 2.6))),
              const SizedBox(height: 14),
              Text('OPPONENT',
                  style: Club.label(11,
                      color: Club.darkTeak.withValues(alpha: 0.65),
                      spacing: 2.0)),
              const SizedBox(height: 8),
              Segmented(
                options: const ['TWO PILOTS', 'VS AUTOMATON'],
                selected: vsAi ? 1 : 0,
                onSelect: (i) => setSheet(() => vsAi = i == 1),
              ),
              const SizedBox(height: 12),
              Text('CHRONO PER PILOT',
                  style: Club.label(11,
                      color: Club.darkTeak.withValues(alpha: 0.65),
                      spacing: 2.0)),
              const SizedBox(height: 8),
              Segmented(
                options: const ['5 MIN', '10 MIN', '15 MIN'],
                selected: [5, 10, 15].indexOf(minutes).clamp(0, 2),
                onSelect: (i) =>
                    setSheet(() => minutes = [5, 10, 15][i]),
              ),
              if (vsAi) ...[
                const SizedBox(height: 12),
                Text('AUTOMATON CALIBRE',
                    style: Club.label(11,
                        color: Club.darkTeak.withValues(alpha: 0.65),
                        spacing: 2.0)),
                const SizedBox(height: 8),
                Segmented(
                  options: AiLevel.values.map((e) => e.label).toList(),
                  selected: settings.aiLevel.index,
                  onSelect: (i) => settings.setAiLevel(AiLevel.values[i]),
                ),
              ],
              const SizedBox(height: 16),
              BrassButton(
                label: 'START BLITZ DUEL',
                primary: true,
                danger: true,
                onTap: () {
                  settings.setBlitzVsAi(vsAi);
                  settings.setBlitzMinutes(minutes);
                  Navigator.of(ctx).pop();
                  onBlitz(vsAi: vsAi);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final engine = ReversiEngine()..reset();
    final theme = settings.theme;
    final disc = settings.discStyle;
    return ListenableBuilder(
      listenable: settings,
      builder: (_, _) => Scaffold(
        backgroundColor: Club.cream,
        body: Column(
          children: [
            ClubHeader(
              title: 'REVERSI RUSH',
              sub: 'MID-CENTURY SPEED CLUB · EST. 1964',
              trailing: BrassIconButton(
                icon: Icons.settings,
                onTap: onSettings,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  children: [
                    // Club logo.
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Club.brass, width: 2.5),
                        boxShadow: Club.contactShadow(blur: 14, dy: 7),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset('assets/reversirush_logo.png',
                          fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 10),
                    Text('THE GENTLEMAN\'S SPEED DUEL',
                        style: Club.hDisplay(22)),
                    const SizedBox(height: 4),
                    Text(
                      'Outflank. Flip. Beat the clock. Sixty-four squares of teak and brass.',
                      textAlign: TextAlign.center,
                      style: Club.bodyText(12,
                          color: Club.darkTeak.withValues(alpha: 0.7)),
                    ),
                    const SizedBox(height: 14),
                    // Board vignette in the current table theme.
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Club.walnut,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Club.brassDeep, width: 2),
                      ),
                      child: ClubBoard(
                        cells: engine.b,
                        legal: const {},
                        showHints: false,
                        interactive: false,
                        theme: theme,
                        disc: disc,
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Difficulty selector.
                    RallyCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      child: Column(
                        children: [
                          Text('AUTOMATON CALIBRE',
                              style: Club.label(11,
                                  color: Club.darkTeak.withValues(alpha: 0.7))),
                          const SizedBox(height: 8),
                          Segmented(
                            options:
                                AiLevel.values.map((e) => e.label).toList(),
                            selected: settings.aiLevel.index,
                            onSelect: (i) {
                              settings.setAiLevel(AiLevel.values[i]);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    BrassButton(
                      label: 'PLAY VS AI',
                      sublabel:
                          'Solo duel against the ${settings.aiLevel.label} automaton',
                      primary: true,
                      onTap: onPlayVsAi,
                      leading: const Icon(Icons.smart_toy,
                          color: Club.brassHi, size: 24),
                    ),
                    const SizedBox(height: 10),
                    BrassButton(
                      label: 'TWO PLAYERS',
                      sublabel: 'Pass-and-play duel on this device',
                      onTap: onTwoPlayers,
                      leading: const Icon(Icons.people,
                          color: Club.darkTeak, size: 24),
                    ),
                    const SizedBox(height: 10),
                    BrassButton(
                      label: 'BLITZ MODE',
                      sublabel:
                          'Rapid chrono duel · ${settings.blitzMinutes}:00 per pilot',
                      danger: true,
                      onTap: () => _blitzSheet(context),
                      leading: const Icon(Icons.timer,
                          color: Club.cream, size: 24),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: BrassButton(
                            label: 'TABLE & DISCS',
                            onTap: onThemes,
                            leading: const Icon(Icons.palette,
                                color: Club.darkTeak, size: 20),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ValueListenableBuilder<bool>(
                            valueListenable: store.proPurchased,
                            builder: (_, owned, _) => BrassButton(
                              label: owned ? 'PRO MEMBER' : 'GO PRO',
                              onTap: onPro,
                              leading: Icon(Icons.emoji_events,
                                  color: owned
                                      ? Club.brassDeep
                                      : Club.darkTeak,
                                  size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Official rules (1964) apply at every table.',
                        style: Club.bodyText(11,
                            color: Club.darkTeak.withValues(alpha: 0.55))),
                  ],
                ),
              ),
            ),
            _BottomNav(
              current: 0,
              onLobby: () {},
              onRecords: onRecords,
              onSettings: onSettings,
            ),
          ],
        ),
      ),
    );
  }
}

/// Segmented brass selector (difficulty, blitz minutes).
class Segmented extends StatelessWidget {
  final List<String> options;
  final int selected;
  final ValueChanged<int> onSelect;

  const Segmented(
      {super.key,
      required this.options,
      required this.selected,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Club.hairline,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Club.brass, width: 1.5),
      ),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelect(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: i == selected ? Club.teak : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: i == selected
                        ? Border.all(color: Club.brass, width: 1.5)
                        : null,
                  ),
                  child: Text(
                    options[i],
                    textAlign: TextAlign.center,
                    style: Club.label(13,
                        color: i == selected ? Club.cream : Club.darkTeak,
                        spacing: 1.8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class StopwatchMotif extends StatelessWidget {
  final double size;
  const StopwatchMotif({super.key, this.size = 92});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _StopwatchPainter()),
    );
  }
}

class _StopwatchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 8;

    // Crown + stem.
    canvas.drawRect(
        Rect.fromCenter(center: c + Offset(0, -r - 10), width: 10, height: 12),
        Paint()..color = Club.brassDeep);
    canvas.drawCircle(
        c + Offset(0, -r - 18), 7, Paint()..color = Club.brass);
    // Side button.
    canvas.drawRect(
        Rect.fromCenter(center: c + Offset(r + 9, -r * 0.55), width: 12, height: 7),
        Paint()..color = Club.brassDeep);

    // Brass bezel.
    canvas.drawCircle(
        c,
        r + 4,
        Paint()
          ..color = const Color(0x55000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    canvas.drawCircle(c, r + 4, Paint()..color = Club.brass);
    canvas.drawCircle(c, r, Paint()..color = Club.ebonite);
    // Cream dial.
    canvas.drawCircle(c, r - 7, Paint()..color = Club.cream);

    // Tick marks.
    for (var k = 0; k < 60; k++) {
      final a = k / 60 * 2 * 3.14159265;
      final long = k % 5 == 0;
      final p1 = c + Offset(cos(a), sin(a)) * (r - 9);
      final p2 = c + Offset(cos(a), sin(a)) * (r - (long ? 20 : 14));
      canvas.drawLine(
          p1,
          p2,
          Paint()
            ..color = long ? Club.darkTeak : Club.darkTeak.withValues(alpha: 0.45)
            ..strokeWidth = long ? 2.5 : 1.2);
    }
    // Crimson hand.
    final ha = -0.5;
    canvas.drawLine(
        c,
        c + Offset(cos(ha), sin(ha)) * (r - 24),
        Paint()
          ..color = Club.crimson
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round);
    canvas.drawCircle(c, 5, Paint()..color = Club.brassDeep);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Bottom club navigation: LOBBY / RECORDS / SETTINGS.
class _BottomNav extends StatelessWidget {
  final int current;
  final VoidCallback onLobby;
  final VoidCallback onRecords;
  final VoidCallback onSettings;

  const _BottomNav({
    required this.current,
    required this.onLobby,
    required this.onRecords,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Club.cardstock,
        border: Border(top: BorderSide(color: Club.brass, width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _item(Icons.home, 'LOBBY', 0, onLobby),
            _item(Icons.emoji_events, 'RECORDS', 1, onRecords),
            _item(Icons.settings, 'SETTINGS', 2, onSettings),
          ],
        ),
      ),
    );
  }

  Widget _item(IconData icon, String label, int i, VoidCallback onTap) {
    final active = i == current;
    return Expanded(
      child: GestureDetector(
        onTap: active ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                  color: active ? Club.crimson : Colors.transparent, width: 3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 20,
                  color: active ? Club.crimson : Club.darkTeak.withValues(alpha: 0.55)),
              const SizedBox(height: 2),
              Text(label,
                  style: Club.label(9,
                      color: active
                          ? Club.crimson
                          : Club.darkTeak.withValues(alpha: 0.55),
                      spacing: 2.0)),
            ],
          ),
        ),
      ),
    );
  }
}
