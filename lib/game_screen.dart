import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

/// Reversi engine: 8x8, 0 empty, 1 black, 2 white.
class ReversiEngine {
  static const n = 8;
  static const dirs = [
    [-1, -1], [-1, 0], [-1, 1],
    [0, -1],           [0, 1],
    [1, -1],  [1, 0],  [1, 1],
  ];
  List<int> b = List.filled(64, 0);
  int turn = 1;

  void reset() {
    b = List.filled(64, 0);
    b[27] = 2; b[28] = 1; b[35] = 1; b[36] = 2;
    turn = 1;
  }

  int _at(int r, int c) => (r < 0 || r > 7 || c < 0 || c > 7) ? -1 : b[r * 8 + c];

  List<int> _flipsFor(int i, int color) {
    if (b[i] != 0) return [];
    final r = i ~/ 8, c = i % 8, foe = 3 - color, out = <int>[];
    for (final d in dirs) {
      final line = <int>[];
      int nr = r + d[0], nc = c + d[1];
      while (_at(nr, nc) == foe) {
        line.add(nr * 8 + nc);
        nr += d[0]; nc += d[1];
      }
      if (line.isNotEmpty && _at(nr, nc) == color) out.addAll(line);
    }
    return out;
  }

  List<int> legalMoves([int? color]) {
    color ??= turn;
    final m = <int>[];
    for (int i = 0; i < 64; i++) {
      if (_flipsFor(i, color).isNotEmpty) m.add(i);
    }
    return m;
  }

  /// Returns number of discs flipped.
  int play(int i) {
    final flips = _flipsFor(i, turn);
    if (flips.isEmpty) return 0;
    b[i] = turn;
    for (final f in flips) {
      b[f] = turn;
    }
    turn = 3 - turn;
    return flips.length;
  }

  int count(int color) => b.where((v) => v == color).length;
  bool get full => !b.contains(0);
}

/// Greedy bot: max flips + positional spice, fast.
int botPick(ReversiEngine e, Random rng) {
  final moves = e.legalMoves();
  const w = [ // positional weights
    30,-8,12,10,10,12,-8,30,
    -8,-12,-4,-4,-4,-4,-12,-8,
    12,-4,6,4,4,6,-4,12,
    10,-4,4,2,2,4,-4,10,
    10,-4,4,2,2,4,-4,10,
    12,-4,6,4,4,6,-4,12,
    -8,-12,-4,-4,-4,-4,-12,-8,
    30,-8,12,10,10,12,-8,30];
  int best = moves.first, bs = -999999;
  for (final m in moves) {
    final s = e._flipsFor(m, e.turn).length * 10 + w[m] + rng.nextInt(12);
    if (s > bs) { bs = s; best = m; }
  }
  return best;
}

class ReversiRushScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;
  const ReversiRushScreen({super.key, required this.players, required this.callbacks});

  @override
  State<ReversiRushScreen> createState() => _ReversiRushScreenState();
}

class _ReversiRushScreenState extends State<ReversiRushScreen> {
  final e = ReversiEngine();
  final rng = Random();
  static const totalSecs = 60;
  double timeLeft = totalSecs.toDouble();
  Timer? clock;
  bool over = false;
  int flipGen = 0; // bumps to animate flips
  Set<int> hints = {};

  List<Player> get ps => widget.players;
  int get turnIdx => e.turn == 1 ? 0 : 1;

  @override
  void initState() {
    super.initState();
    e.reset();
    _updateHints();
    clock = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted) return;
      if (ModalRoute.of(context)?.isCurrent != true) return;
      setState(() {
        timeLeft -= 0.1;
        if (timeLeft <= 0) { timeLeft = 0; _end('⏰ Time!'); }
      });
    });
    _maybeBot();
  }

  @override
  void dispose() { clock?.cancel(); super.dispose(); }

  void _updateHints() => hints = e.legalMoves().toSet();

  void _maybeBot() {
    if (over || !mounted) return;
    if (ps[turnIdx].isBot) {
      Future.delayed(Duration(milliseconds: 350 + rng.nextInt(250)), () {
        if (!mounted || over || !ps[turnIdx].isBot) return;
        _doMove(botPick(e, rng));
      });
    }
  }

  void _doMove(int i) {
    if (over) return;
    final flipped = e.play(i);
    if (flipped == 0) return;
    Sfx.move();
    flipGen++;
    _afterMove();
  }

  void _afterMove() {
    // auto-pass when a side has no moves
    if (e.legalMoves().isEmpty) {
      if (e.full || e.legalMoves(3 - e.turn).isEmpty) {
        _end('🏁 Board locked!');
        return;
      }
      e.turn = 3 - e.turn; // pass
    }
    _updateHints();
    widget.callbacks.setActivePlayer(turnIdx);
    setState(() {});
    _maybeBot();
  }

  void _onTapCell(int i) {
    if (over || ps[turnIdx].isBot) return;
    if (!hints.contains(i)) return;
    _doMove(i);
  }

  void _end(String why) {
    if (over) return;
    over = true;
    clock?.cancel();
    final bCount = e.count(1), wCount = e.count(2);
    ps[0].score = bCount; ps[1].score = wCount;
    widget.callbacks.refreshHud();
    Player? winner;
    if (bCount != wCount) winner = bCount > wCount ? ps[0] : ps[1];
    Sfx.win();
    widget.callbacks.finish(
      winner: winner,
      headline: winner == null
          ? '$why Dead even — $bCount to $wCount!'
          : '$why ${winner.name} flips it $bCount–$wCount! ⚫',
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    final bCount = e.count(1), wCount = e.count(2);
    return Column(
      children: [
        TurnBanner(player: ps[turnIdx], action: over ? 'done!' : 'is flipping!'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              _countChip(t, '⚫', bCount),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    children: [
                      Text('⏱️ ${timeLeft.toStringAsFixed(1)}s',
                          style: TextStyle(color: t.text, fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: timeLeft / totalSecs,
                          minHeight: 8,
                          backgroundColor: t.surface,
                          valueColor: AlwaysStoppedAnimation(t.accent),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _countChip(t, '⚪', wCount),
            ],
          ),
        ),
        ScoreChips(players: ps, activeIndex: turnIdx),
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: t.surface, borderRadius: t.radius,
                  border: Border.all(color: t.primary.withValues(alpha: .35), width: 3),
                ),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
                  itemCount: 64,
                  itemBuilder: (_, i) {
                    final v = e.b[i];
                    final isHint = hints.contains(i) && !ps[turnIdx].isBot && !over;
                    return GestureDetector(
                      onTap: () => _onTapCell(i),
                      child: Container(
                        margin: const EdgeInsets.all(1.5),
                        decoration: BoxDecoration(
                          color: t.background.withValues(alpha: .5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: v == 0
                              ? (isHint
                                  ? Container(width: 12, height: 12,
                                      decoration: BoxDecoration(shape: BoxShape.circle,
                                          color: t.accent.withValues(alpha: .55)))
                                  : null)
                              : TweenAnimationBuilder<double>(
                                  key: ValueKey('$i-$flipGen-$v'),
                                  tween: Tween(begin: 0.3, end: 1.0),
                                  duration: const Duration(milliseconds: 260),
                                  curve: Curves.elasticOut,
                                  builder: (_, s, _) => Transform.scale(
                                    scale: s,
                                    child: Container(
                                      width: 34, height: 34,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: v == 1 ? Colors.black87 : Colors.white,
                                        border: Border.all(color: t.muted, width: 1),
                                        boxShadow: const [BoxShadow(blurRadius: 3, offset: Offset(0, 2), color: Colors.black26)],
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text('⚡ Blitz rules: most discs when the clock dies wins!',
              style: TextStyle(color: t.muted, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _countChip(GameTheme t, String emoji, int n) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: t.surface, borderRadius: t.radius),
        child: Text('$emoji $n', style: TextStyle(color: t.text, fontWeight: FontWeight.bold, fontSize: 16)),
      );
}
