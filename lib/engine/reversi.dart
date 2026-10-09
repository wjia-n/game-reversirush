import 'dart:math';

/// Reversi engine: 8x8, 0 empty, 1 black, 2 white.
/// Game rules per RULES.md. Original engine kept verbatim; AI extended
/// to the three difficulty levels the rules document mandates
/// (Casual / Club / Pro).
class ReversiEngine {
  static const n = 8;
  static const dirs = [
    [-1, -1],
    [-1, 0],
    [-1, 1],
    [0, -1],
    [0, 1],
    [1, -1],
    [1, 0],
    [1, 1],
  ];
  List<int> b = List.filled(64, 0);
  int turn = 1;

  void reset() {
    b = List.filled(64, 0);
    b[27] = 2;
    b[28] = 1;
    b[35] = 1;
    b[36] = 2;
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
        nr += d[0];
        nc += d[1];
      }
      if (line.isNotEmpty && _at(nr, nc) == color) out.addAll(line);
    }
    return out;
  }

  /// Public bracket lookup used by the AI search (same rules as [_flipsFor]).
  List<int> flipsFor(int i, int color) => _flipsFor(i, color);

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

  ReversiEngine clone() {
    final e = ReversiEngine();
    e.b = List<int>.from(b);
    e.turn = turn;
    return e;
  }
}

/// AI difficulty levels per RULES.md §11.
enum AiLevel { casual, club, pro }

extension AiLevelLabel on AiLevel {
  String get label => switch (this) {
        AiLevel.casual => 'CASUAL',
        AiLevel.club => 'CLUB',
        AiLevel.pro => 'PRO',
      };
}

/// Automaton opponent. All levels play legal moves only and pass when they
/// have none (RULES.md §11).
class ReversiAi {
  static const _corners = [0, 7, 56, 63];
  static const _cornerAdj = {
    0: [1, 8, 9],
    7: [6, 14, 15],
    56: [48, 49, 57],
    63: [54, 55, 62],
  };

  /// Picks a move for [engine.turn]. [deadline] caps search time (Rush mode).
  static int pick(ReversiEngine engine, AiLevel level, Random rng,
      {DateTime? deadline}) {
    final moves = engine.legalMoves();
    if (moves.isEmpty) {
      throw StateError('AI asked to move with no legal moves');
    }
    return switch (level) {
      AiLevel.casual => _casual(engine, moves, rng),
      AiLevel.club => _bestOf(engine, moves, depth: 3, deadline: deadline),
      AiLevel.pro => _iterative(engine, moves, deadline: deadline),
    };
  }

  /// Casual: 1-ply greedy (max flips), 25% random legal move to stay beatable.
  static int _casual(ReversiEngine e, List<int> moves, Random rng) {
    if (rng.nextDouble() < 0.25) return moves[rng.nextInt(moves.length)];
    int best = moves.first, bs = -1;
    for (final m in moves) {
      final s = e.flipsFor(m, e.turn).length;
      if (s > bs) {
        bs = s;
        best = m;
      }
    }
    return best;
  }

  /// Club: 3-ply minimax with alpha-beta.
  /// Eval = disc-count differential + mobility×10 + corner occupancy×25.
  static int _bestOf(ReversiEngine e, List<int> moves,
      {required int depth, DateTime? deadline}) {
    final color = e.turn;
    int best = moves.first, bs = -1 << 30;
    final ordered = _orderMoves(e, moves, color);
    for (final m in ordered) {
      final sim = e.clone();
      _apply(sim, m, color);
      final v = -_search(sim, 3 - color, color, depth - 1, -1 << 30, 1 << 30,
          _State(deadline));
      if (v > bs) {
        bs = v;
        best = m;
      }
    }
    return best;
  }

  /// Pro: 5-ply minimax + iterative deepening under a 2s cap.
  /// Eval = Club eval + corner-adjacency penalty×15 + endgame parity bonus.
  static int _iterative(ReversiEngine e, List<int> moves,
      {DateTime? deadline}) {
    final color = e.turn;
    final cap = deadline ?? DateTime.now().add(const Duration(seconds: 2));
    int best = moves.first;
    for (var depth = 1; depth <= 5; depth++) {
      final st = _State(cap);
      int cur = moves.first, curBest = -1 << 30;
      final ordered = _orderMoves(e, moves, color);
      for (final m in ordered) {
        if (st.expired) break;
        final sim = e.clone();
        _apply(sim, m, color);
        final v = -_search(sim, 3 - color, color, depth - 1, -1 << 30, 1 << 30,
            st, pro: true);
        if (v > curBest) {
          curBest = v;
          cur = m;
        }
      }
      if (!st.expired) best = cur; // keep best fully-searched depth
      if (st.expired) break;
    }
    return best;
  }

  static int _search(ReversiEngine e, int toMove, int root, int depth, int alpha,
      int beta, _State st,
      {bool pro = false}) {
    if (st.expired) return 0;
    st.nodes++;
    if (st.nodes % 2048 == 0 && DateTime.now().isAfter(st.deadline)) {
      st.expired = true;
      return 0;
    }
    var moves = e.legalMoves(toMove);
    if (moves.isEmpty) {
      final foeMoves = e.legalMoves(3 - toMove);
      if (foeMoves.isEmpty) {
        // Terminal: disc differential decides, scaled to dominate heuristics.
        final d = e.count(root) - e.count(3 - root);
        return d * 10000 + (d > 0 ? depth : 0);
      }
      // Pass: same depth, opponent moves.
      return -_search(e, 3 - toMove, root, depth, -beta, -alpha, st, pro: pro);
    }
    if (depth <= 0) return _evaluate(e, root, pro: pro);

    int best = -1 << 30;
    for (final m in _orderMoves(e, moves, toMove)) {
      final sim = e.clone();
      _apply(sim, m, toMove);
      final v =
          -_search(sim, 3 - toMove, root, depth - 1, -beta, -alpha, st, pro: pro);
      if (st.expired) return 0;
      if (v > best) best = v;
      if (best > alpha) alpha = best;
      if (alpha >= beta) break;
    }
    return best;
  }

  static void _apply(ReversiEngine e, int move, int color) {
    final flips = e.flipsFor(move, color);
    e.b[move] = color;
    for (final f in flips) {
      e.b[f] = color;
    }
  }

  static List<int> _orderMoves(ReversiEngine e, List<int> moves, int color) {
    final scored = moves
        .map((m) => MapEntry(m, e.flipsFor(m, color).length))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return scored.map((p) => p.key).toList();
  }

  static int _evaluate(ReversiEngine e, int color, {bool pro = false}) {
    final foe = 3 - color;
    final discDiff = e.count(color) - e.count(foe);
    final mobility = e.legalMoves(color).length - e.legalMoves(foe).length;
    var corner = 0;
    for (final c in _corners) {
      if (e.b[c] == color) {
        corner++;
      } else if (e.b[c] == foe) {
        corner--;
      }
    }
    var v = discDiff + mobility * 10 + corner * 25;
    if (pro) {
      var adjPenalty = 0;
      for (final entry in _cornerAdj.entries) {
        if (e.b[entry.key] == 0) {
          for (final s in entry.value) {
            if (e.b[s] == color) adjPenalty++;
          }
        }
      }
      v -= adjPenalty * 15;
      // Endgame parity: bonus when likely to move last.
      final empties = e.b.where((x) => x == 0).length;
      if (empties < 20 && empties.isEven == (color == 1)) v += 12;
    }
    return v;
  }
}

class _State {
  final DateTime deadline;
  bool expired = false;
  int nodes = 0;
  _State(DateTime? d)
      : deadline = d ?? DateTime.now().add(const Duration(seconds: 2));
}
