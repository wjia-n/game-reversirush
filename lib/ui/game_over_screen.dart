import 'package:flutter/material.dart';

import '../state/club_state.dart';
import '../theme/club_theme.dart';
import 'widgets/brass_widgets.dart';

/// Official classification: brass victory banner, rally registration score
/// plaque, stat rows, REMATCH / NEW GAME / MENU buttons.
class GameOverScreen extends StatelessWidget {
  final ClubController controller;
  final VoidCallback onRematch;
  final VoidCallback onMenu;

  const GameOverScreen({
    super.key,
    required this.controller,
    required this.onRematch,
    required this.onMenu,
  });

  String _fmtClock(double secs) {
    final s = secs.clamp(0, 359999).round();
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final b = c.engine.count(1), w = c.engine.count(2);
    final draw = c.winnerColor == 0;
    final humanWon = c.humanColor != 0 && c.winnerColor == c.humanColor;
    final humanLost = c.humanColor != 0 && c.winnerColor != 0 && !humanWon;

    final banner = draw
        ? 'DEAD HEAT'
        : humanWon
            ? 'VICTORY'
            : humanLost
                ? 'DEFEAT'
                : '${c.playerName(c.winnerColor)} WINS';

    return Scaffold(
      backgroundColor: Club.cream,
      body: Column(
        children: [
          ClubHeader(
            title: 'REVERSI RUSH',
            sub: 'OFFICIAL CLASSIFICATION',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Column(
                children: [
                  // Brass banner.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Club.teak,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Club.brass, width: 3),
                      boxShadow: Club.contactShadow(blur: 12, dy: 6),
                    ),
                    child: Column(
                      children: [
                        Text('★ ★ ★',
                            style: Club.label(12,
                                color: Club.brassHi, spacing: 6)),
                        const SizedBox(height: 4),
                        Text(banner,
                            style: Club.hDisplay(38, color: Club.cream)),
                        const SizedBox(height: 4),
                        Text('SPEED DUEL CONCLUDED',
                            style: Club.label(11,
                                color: Club.brassHi, spacing: 3)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(c.endReason,
                      textAlign: TextAlign.center,
                      style: Club.label(13,
                          color: Club.darkTeak.withValues(alpha: 0.8),
                          spacing: 1.6)),
                  const SizedBox(height: 14),
                  // Score plaque — rally registration card.
                  RallyCard(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _Tally(
                                label: c.mode == PlayMode.twoPlayer
                                    ? 'NOIR'
                                    : 'NOIR (YOU)',
                                value: b,
                                black: true),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('—',
                                  style: Club.hDisplay(28,
                                      color: Club.brassDeep)),
                            ),
                            _Tally(
                                label: c.mode == PlayMode.twoPlayer
                                    ? 'BLANC'
                                    : 'BLANC (AUTO)',
                                value: w,
                                black: false),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(height: 1, color: Club.hairline),
                        const SizedBox(height: 10),
                        _StatRow(
                            label: 'TOTAL MOVES',
                            value: '${c.movesMade}'),
                        _StatRow(
                            label: 'DISCS FLIPPED',
                            value: '${c.totalFlipped}'),
                        _StatRow(
                            label: 'MAX FLANK CHAIN',
                            value: '${c.maxChain} discs'),
                        _StatRow(
                          label: c.isBlitz ? 'CHRONO REMAINING' : 'DUEL TIME',
                          value: c.isBlitz
                              ? '${_fmtClock(c.blackClock)} / ${_fmtClock(c.whiteClock)}'
                              : _fmtClock(c.elapsed),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Resting pile of enamel discs.
                  const _DiscPile(),
                  const SizedBox(height: 16),
                  BrassButton(
                      label: 'REMATCH', primary: true, onTap: onRematch),
                  const SizedBox(height: 10),
                  BrassButton(label: 'BACK TO LOBBY', onTap: onMenu),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tally extends StatelessWidget {
  final String label;
  final int value;
  final bool black;
  const _Tally(
      {required this.label, required this.value, required this.black});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.35, -0.4),
              colors: [
                black ? const Color(0xFF3A3A3A) : Colors.white,
                black ? const Color(0xFF161616) : Club.ivory,
              ],
            ),
            border: Border.all(color: Club.brass, width: 2),
          ),
        ),
        const SizedBox(height: 6),
        Text('$value', style: Club.numeral(40)),
        Text(label,
            style:
                Club.label(10, color: Club.darkTeak.withValues(alpha: 0.65))),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: Club.label(12,
                      color: Club.darkTeak.withValues(alpha: 0.7),
                      spacing: 1.6))),
          Text(value, style: Club.numeral(18)),
        ],
      ),
    );
  }
}

/// A resting pile of enamel discs, club-table dressing.
class _DiscPile extends StatelessWidget {
  const _DiscPile();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (var k = 0; k < 7; k++)
            Positioned(
              left: 60.0 + k * 30,
              child: Transform.rotate(
                angle: (k * 0.35) - 1.0,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.35, -0.4),
                      colors: [
                        k.isEven
                            ? const Color(0xFF3A3A3A)
                            : Colors.white,
                        k.isEven
                            ? const Color(0xFF161616)
                            : Club.ivory,
                      ],
                    ),
                    border: Border.all(color: Club.brass, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x55000000),
                          blurRadius: 4,
                          offset: Offset(0, 3)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
