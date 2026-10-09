import 'package:flutter/material.dart';

import '../audio/club_audio.dart';
import '../engine/reversi.dart';
import '../state/club_state.dart';
import '../theme/club_theme.dart';
import 'widgets/board.dart';
import 'widgets/brass_widgets.dart';
import 'widgets/dial.dart';

/// Gameplay: teak board, score tally cards, stopwatch chip, YOUR TURN ribbon,
/// UNDO / HINT / pause bottom bar, pause & ready overlays.
class GameScreen extends StatelessWidget {
  final ClubController controller;
  final VoidCallback onQuitToMenu;
  final VoidCallback onOpenSettings;

  const GameScreen({
    super.key,
    required this.controller,
    required this.onQuitToMenu,
    required this.onOpenSettings,
  });

  String _fmtClock(double secs) {
    final s = secs.clamp(0, 359999).ceil();
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }

  String _fmtElapsed(double secs) {
    final s = secs.floor();
    final m = s ~/ 60;
    final r = s % 60;
    final d = ((secs - s) * 10).floor();
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}.$d';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (_, _) {
        final c = controller;
        final bCount = c.engine.count(1);
        final wCount = c.engine.count(2);
        final turnBlack = c.engine.turn == 1;
        final aiThinking = c.aiThinking;
        final humanTurn =
            c.mode == PlayMode.twoPlayer || c.engine.turn == c.humanColor;

        final String chipText;
        final bool urgent;
        final String caption;
        if (c.isBlitz) {
          final active = turnBlack ? c.blackClock : c.whiteClock;
          chipText = _fmtClock(active);
          urgent = active <= 10.5;
          caption = turnBlack ? "BLACK'S CHRONO" : "WHITE'S CHRONO";
        } else {
          chipText = _fmtElapsed(c.elapsed);
          urgent = false;
          caption = 'ELAPSED';
        }

        final ribbonText = c.over
            ? 'DUEL COMPLETE'
            : aiThinking
                ? 'AUTOMATON THINKING…'
                : turnBlack
                    ? '${c.playerName(1)} — PLACE BLACK DISC'
                    : '${c.playerName(2)} — PLACE WHITE DISC';

        return Scaffold(
          backgroundColor: Club.cream,
          body: Stack(
            children: [
              Column(
                children: [
                  // Timing-pit top bar.
                  Container(
                    decoration: const BoxDecoration(
                      color: Club.teak,
                      border:
                          Border(bottom: BorderSide(color: Club.brass, width: 3)),
                      boxShadow: [
                        BoxShadow(
                            color: Color(0x66000000),
                            blurRadius: 8,
                            offset: Offset(0, 4)),
                      ],
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('SPEED DUEL',
                                      style: Club.label(16,
                                          color: Club.cream, spacing: 2.6)),
                                  Text(
                                      c.mode == PlayMode.blitz
                                          ? 'BLITZ · ${c.settings.blitzMinutes}:00 PER PILOT'
                                          : c.mode == PlayMode.vsAi
                                              ? 'SOLO · ${c.aiLevel.label} AUTOMATON'
                                              : 'PASS-AND-PLAY DUEL',
                                      style: Club.label(10,
                                          color: Club.brassHi, spacing: 1.8)),
                                ],
                              ),
                            ),
                            BrassIconButton(
                                icon: Icons.pause,
                                size: 40,
                                onTap: c.over ? null : c.pause),
                            const SizedBox(width: 8),
                            BrassIconButton(
                                icon: Icons.settings,
                                size: 40,
                                onTap: onOpenSettings),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Score tally + stopwatch.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        ScoreCard(
                          name: c.playerName(1),
                          discs: bCount,
                          color: 1,
                          active: turnBlack && !c.over,
                          sub: c.isBlitz ? _fmtClock(c.blackClock) : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: StopwatchChip(
                              text: chipText,
                              urgent: urgent,
                              caption: caption),
                        ),
                        ScoreCard(
                          name: c.playerName(2),
                          discs: wCount,
                          color: 2,
                          active: !turnBlack && !c.over,
                          sub: c.isBlitz ? _fmtClock(c.whiteClock) : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClubRibbon(
                    text: ribbonText,
                    color: aiThinking
                        ? Club.brassDeep
                        : (turnBlack ? Club.teak : Club.darkTeak),
                  ),
                  const SizedBox(height: 8),
                  // Board.
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Club.walnut,
                            borderRadius: BorderRadius.circular(18),
                            border:
                                Border.all(color: Club.brassDeep, width: 2),
                          ),
                          child: ClubBoard(
                            cells: c.engine.b,
                            legal: c.legal,
                            showHints: c.settings.hintsOn,
                            justPlaced: c.justPlaced,
                            justFlipped: c.justFlipped,
                            animGen: c.animGen,
                            hintPulseIndex: c.hintPulseIndex,
                            hintPulseGen: c.hintPulseGen,
                            shakeIndex: c.shakeIndex,
                            shakeGen: c.shakeGen,
                            interactive: !c.over && humanTurn && !aiThinking,
                            onTap: c.tapCell,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (!c.isBlitz)
                    Text('Turn ${c.movesMade + 1} · ${c.totalFlipped} discs flipped',
                        style: Club.bodyText(11,
                            color: Club.darkTeak.withValues(alpha: 0.6))),
                  ClubActionBar(
                    children: [
                      BarButton(
                          icon: Icons.undo,
                          label: 'UNDO',
                          onTap: c.undoAvailable ? c.undo : null),
                      BarButton(
                          icon: Icons.lightbulb_outline,
                          label: 'HINT',
                          onTap: (!c.over &&
                                  !c.paused &&
                                  !c.aiThinking &&
                                  humanTurn &&
                                  c.legal.isNotEmpty)
                              ? c.hint
                              : null),
                      BarButton(
                          icon: Icons.pause,
                          label: 'PAUSE',
                          onTap: c.over ? null : c.pause),
                    ],
                  ),
                ],
              ),
              // Pass banner.
              if (c.passBanner != null)
                Positioned(
                  top: 200,
                  left: 0,
                  right: 0,
                  child: ClubRibbon(
                      text: c.passBanner!, color: Club.brassDeep),
                ),
              // Pause overlay (not during the blitz readiness gate).
              if (c.paused && !c.over && !(c.isBlitz && c.movesMade == 0))
                _PauseOverlay(controller: c, onQuit: onQuitToMenu),
              // Blitz readiness overlay.
              if (c.isBlitz && c.paused && !c.over && c.movesMade == 0)
                _ReadyOverlay(controller: c),
            ],
          ),
        );
      },
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  final ClubController controller;
  final VoidCallback onQuit;
  const _PauseOverlay({required this.controller, required this.onQuit});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Container(
      color: const Color(0xAA2A1D12),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: RallyCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('PIT STOP', style: Club.hDisplay(28)),
                Text('THE CLOCKS ARE HELD',
                    style: Club.label(11,
                        color: Club.darkTeak.withValues(alpha: 0.65))),
                const SizedBox(height: 18),
                BrassButton(
                    label: 'RESUME', primary: true, onTap: c.resume),
                const SizedBox(height: 10),
                BrassButton(label: 'RESTART DUEL', onTap: c.restart),
                const SizedBox(height: 10),
                BrassButton(
                    label: 'CONCEDE',
                    danger: true,
                    onTap: () {
                      c.audio.play(ClubSound.lose);
                      c.resign();
                    }),
                const SizedBox(height: 10),
                BrassButton(label: 'QUIT TO LOBBY', onTap: onQuit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadyOverlay extends StatelessWidget {
  final ClubController controller;
  const _ReadyOverlay({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xAA2A1D12),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: RallyCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('BLITZ DUEL', style: Club.hDisplay(28)),
                const SizedBox(height: 6),
                Text(
                  'Both pilots get ${controller.settings.blitzMinutes}:00 on their chrono. '
                  'Your clock runs only on your turn — run dry and you lose on time. '
                  'Black moves first.',
                  textAlign: TextAlign.center,
                  style: Club.bodyText(13),
                ),
                const SizedBox(height: 18),
                BrassButton(
                  label: 'START ENGINES',
                  primary: true,
                  onTap: controller.ready,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
