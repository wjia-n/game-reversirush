import 'package:flutter/material.dart';

import '../audio/club_audio.dart';
import '../engine/reversi.dart';
import '../state/club_state.dart';
import '../theme/club_theme.dart';
import '../theme/rush_themes.dart';
import 'widgets/board.dart';
import 'widgets/brass_widgets.dart';
import 'widgets/dial.dart';

/// Gameplay: pilot trays per side (name, discs, chrono, thinking state),
/// narration ribbon, themed board with staged flip cascades,
/// UNDO / HINT / pause bottom bar, pause & readiness overlays.
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

  Future<void> _renamePilot(BuildContext context, int color) async {
    final c = controller;
    final slot = c.nameSlots[color - 1];
    final current = c.playerName(color);
    final text = TextEditingController(text: current);
    final next = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Club.cream,
        title: Text('RENAME PILOT',
            style: Club.label(14, color: Club.darkTeak, spacing: 2.4)),
        content: TextField(
          controller: text,
          autofocus: true,
          maxLength: 16,
          style: Club.bodyText(16),
          decoration: const InputDecoration(
            hintText: 'Pilot name',
            counterText: '',
          ),
          onSubmitted: (_) => Navigator.of(ctx).pop(text.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('CANCEL',
                style: Club.label(12, color: Club.darkTeak)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(text.text),
            child:
                Text('SAVE', style: Club.label(12, color: Club.brassDeep)),
          ),
        ],
      ),
    );
    if (next != null) {
      c.settings.setPilotName(slot, next);
      c.audio.play(ClubSound.click);
    }
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
        final theme = c.settings.theme;
        final disc = c.settings.discStyle;

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
                                          ? 'BLITZ · ${c.clockTotal ~/ 60}:00 PER PILOT'
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
                  // Per-side pilot trays.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: _PilotTray(
                            color: 1,
                            name: c.playerName(1),
                            discs: bCount,
                            clock: c.isBlitz ? _fmtClock(c.blackClock) : null,
                            clockUrgent: c.isBlitz &&
                                turnBlack &&
                                c.blackClock <= 10.5,
                            active: turnBlack && !c.over,
                            thinking: aiThinking && !turnBlack,
                            disc: disc,
                            onRename: () => _renamePilot(context, 1),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: StopwatchChip(
                              text: chipText,
                              urgent: urgent,
                              caption: caption),
                        ),
                        Expanded(
                          child: _PilotTray(
                            color: 2,
                            name: c.playerName(2),
                            discs: wCount,
                            clock: c.isBlitz ? _fmtClock(c.whiteClock) : null,
                            clockUrgent: c.isBlitz &&
                                !turnBlack &&
                                c.whiteClock <= 10.5,
                            active: !turnBlack && !c.over,
                            thinking: aiThinking && !turnBlack,
                            disc: disc,
                            onRename: () => _renamePilot(context, 2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Narration ribbon: every turn is announced.
                  ClubRibbon(
                    text: c.over
                        ? 'DUEL COMPLETE'
                        : c.narration.isEmpty
                            ? (turnBlack
                                ? '${c.playerName(1)} — PLACE BLACK DISC'
                                : '${c.playerName(2)} — PLACE WHITE DISC')
                            : c.narration,
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
                            visibleFlipped: c.visibleFlipped,
                            animGen: c.animGen,
                            hintPulseIndex: c.hintPulseIndex,
                            hintPulseGen: c.hintPulseGen,
                            shakeIndex: c.shakeIndex,
                            shakeGen: c.shakeGen,
                            interactive: !c.over && humanTurn && !aiThinking,
                            onTap: c.tapCell,
                            theme: theme,
                            disc: disc,
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
                                  c.legal.isNotEmpty &&
                                  c.phase == TurnPhase.awaitingMove)
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
              // Blitz readiness overlay: each pilot confirms.
              if (c.isBlitz && c.paused && !c.over && c.movesMade == 0)
                _ReadyOverlay(controller: c),
            ],
          ),
        );
      },
    );
  }
}

/// One pilot's tray: renameable name, disc count, chrono, active highlight,
/// and a visible thinking spinner on the automaton's side.
class _PilotTray extends StatelessWidget {
  final int color; // 1 black, 2 white
  final String name;
  final int discs;
  final String? clock;
  final bool clockUrgent;
  final bool active;
  final bool thinking;
  final DiscStyle disc;
  final VoidCallback onRename;

  const _PilotTray({
    required this.color,
    required this.name,
    required this.discs,
    required this.clock,
    required this.clockUrgent,
    required this.active,
    required this.thinking,
    required this.disc,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final face = color == 1 ? disc.blackFace : disc.whiteFace;
    return GestureDetector(
      onTap: onRename,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Club.cream : Club.cardstock,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: active ? Club.crimson : Club.brass,
              width: active ? 2.5 : 1.5),
          boxShadow: active ? Club.contactShadow(blur: 8, dy: 4) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: face,
                    border: Border.all(color: disc.rim, width: 1.5),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Club.label(12,
                        color: active ? Club.crimson : Club.darkTeak,
                        spacing: 1.6),
                  ),
                ),
                if (thinking)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Club.brassDeep),
                  )
                else
                  const Icon(Icons.edit, size: 13, color: Club.brassDeep),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('$discs',
                    style: Club.numeral(22,
                        color: active ? Club.crimson : Club.darkTeak)),
                const SizedBox(width: 4),
                Text('DISCS',
                    style: Club.label(9,
                        color: Club.darkTeak.withValues(alpha: 0.6),
                        spacing: 1.4)),
                if (clock != null) ...[
                  const Spacer(),
                  Text(clock!,
                      style: Club.numeral(15,
                          color: clockUrgent
                              ? Club.crimson
                              : Club.darkTeak)),
                ],
              ],
            ),
            if (thinking)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('THINKING…',
                    style: Club.label(9,
                        color: Club.brassDeep, spacing: 2.0)),
              ),
          ],
        ),
      ),
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
                Text('BLITZ DUEL', style: Club.hDisplay(28)),
                const SizedBox(height: 6),
                Text(
                  'Both pilots get ${c.clockTotal ~/ 60}:00 on their chrono. '
                  'Your clock runs only on your turn — run dry and you lose on time. '
                  'Black moves first. Each pilot taps ready below.',
                  textAlign: TextAlign.center,
                  style: Club.bodyText(13),
                ),
                const SizedBox(height: 16),
                BrassButton(
                  label: c.readyBlack
                      ? '✓ ${c.playerName(1)} READY'
                      : '${c.playerName(1)} — TAP WHEN READY',
                  primary: !c.readyBlack,
                  onTap: c.readyBlack ? null : () => c.ready(1),
                ),
                const SizedBox(height: 10),
                BrassButton(
                  label: c.readyWhite
                      ? '✓ ${c.playerName(2)} READY'
                      : '${c.playerName(2)} — TAP WHEN READY',
                  primary: !c.readyWhite,
                  onTap: c.readyWhite ? null : () => c.ready(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
