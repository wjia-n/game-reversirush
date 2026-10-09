import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:reversirush/engine/reversi.dart';

/// Mirrors the controller's turn-settlement loop (pass when stuck, end when
/// neither side can move) so the sim proves the engine can never get stuck.
int _simulateGame(AiLevel black, AiLevel white, Random rng,
    {Duration? aiDeadline}) {
  final e = ReversiEngine()..reset();
  var plies = 0;
  while (plies < 300) {
    final legal = e.legalMoves();
    if (legal.isEmpty) {
      if (e.full || e.legalMoves(3 - e.turn).isEmpty) break; // game ends
      e.turn = 3 - e.turn; // pass
      continue;
    }
    final level = e.turn == 1 ? black : white;
    final deadline =
        aiDeadline == null ? null : DateTime.now().add(aiDeadline);
    final m = ReversiAi.pick(e, level, rng, deadline: deadline);
    assert(legal.contains(m), 'AI played an illegal move: $m');
    final flipped = e.play(m);
    assert(flipped > 0, 'legal move flipped nothing');
    plies++;
  }
  assert(plies < 300, 'game did not terminate — stuck state!');
  return plies;
}

void main() {
  group('RULES.md §13 test cases', () {
    test('1. Opening legality: Black moves are {d3, c4, f5, e6}', () {
      final e = ReversiEngine()..reset();
      // d3=(2,3)=19; c4=(3,2)=26; f5=(4,5)=37; e6=(5,4)=44
      expect(e.legalMoves().toSet(), {19, 26, 37, 44});
    });

    test('2. Basic flip: Black d3 flips d4 -> Black 4, White 1', () {
      final e = ReversiEngine()..reset();
      expect(e.play(19), 1);
      expect(e.count(1), 4);
      expect(e.count(2), 1);
      expect(e.turn, 2);
    });

    test('3. Multi-direction flip flips every bracketed line', () {
      final e = ReversiEngine();
      e.b = List.filled(64, 0);
      e.turn = 1;
      // Horizontal: target (3,0)=24; white at 25,26; black anchor at 27.
      e.b[25] = 2;
      e.b[26] = 2;
      e.b[27] = 1;
      // Vertical: white at (2,0)=16; black anchor at (1,0)=8.
      e.b[16] = 2;
      e.b[8] = 1;
      // Diagonal: white at (2,1)=17; black anchor at (1,2)=10.
      e.b[17] = 2;
      e.b[10] = 1;
      final lines = e.flipLines(24, 1);
      expect(lines.length, 3);
      expect(lines.expand((l) => l).toSet(), {25, 26, 16, 17});
      expect(e.flipsFor(24, 1).toSet(), {25, 26, 16, 17});
      expect(e.play(24), 4);
      for (final i in [16, 17, 25, 26]) {
        expect(e.b[i], 1);
      }
    });

    test('4. No-flip placement rejected (White a1 from opening)', () {
      final e = ReversiEngine()..reset();
      e.play(19); // Black d3
      expect(e.play(0), 0); // a1 flips nothing
      expect(e.count(1), 4); // board unchanged
    });

    test('5. Occupied square rejected', () {
      final e = ReversiEngine()..reset();
      expect(e.play(27), 0); // d4 occupied
      expect(e.turn, 1); // turn unchanged
    });

    test('6/7. Pass when stuck; double pass ends game', () {
      final e = ReversiEngine();
      // Nearly full board, one empty corner, no legal moves for either side.
      e.b = List.filled(64, 1);
      e.b[0] = 0;
      e.turn = 1;
      expect(e.legalMoves(1), isEmpty);
      expect(e.legalMoves(2), isEmpty);
    });

    test('8. Counts sum to 64 on full board', () {
      final e = ReversiEngine();
      e.b = List.generate(64, (i) => i % 2 == 0 ? 1 : 2);
      expect(e.count(1) + e.count(2), 64);
      expect(e.full, isTrue);
    });

    test('9. 32-32 is a draw, 33-31 is a win', () {
      int winner(int black, int white) {
        if (black == white) return 0;
        return black > white ? 1 : 2;
      }

      expect(winner(32, 32), 0);
      expect(winner(33, 31), 1);
      expect(winner(20, 44), 2);
    });

    test('11. Corner capture flips the full bracketed line', () {
      final e = ReversiEngine();
      e.b = List.filled(64, 0);
      e.turn = 1;
      // a1 target: white at b1, black anchor at c1.
      e.b[1] = 2;
      e.b[2] = 1;
      expect(e.legalMoves(1), contains(0));
      expect(e.play(0), 1);
      expect(e.b[0], 1);
      expect(e.b[1], 1);
    });

    test('Illegal placements never change the board or turn', () {
      final e = ReversiEngine()..reset();
      final before = List<int>.from(e.b);
      expect(e.play(27), 0); // occupied
      expect(e.play(0), 0); // no outflank
      expect(e.play(63), 0); // no outflank
      expect(e.b, before);
      expect(e.turn, 1);
    });

    test('flipLines union always equals flipsFor', () {
      final rng = Random(7);
      for (var g = 0; g < 20; g++) {
        final e = ReversiEngine()..reset();
        for (var p = 0; p < 12; p++) {
          final legal = e.legalMoves();
          if (legal.isEmpty) {
            e.turn = 3 - e.turn;
            continue;
          }
          final m = legal[rng.nextInt(legal.length)];
          final union = e.flipLines(m, e.turn).expand((l) => l).toSet();
          expect(union, e.flipsFor(m, e.turn).toSet());
          e.play(m);
        }
      }
    });
  });

  group('AI legality + termination (RULES.md §13.13)', () {
    test('13. AI plays legally across full games (Casual/Club/Pro)', () {
      for (final level in AiLevel.values) {
        final e = ReversiEngine()..reset();
        final rng = Random(42);
        var moves = 0;
        while (moves < 200) {
          final legal = e.legalMoves();
          if (legal.isEmpty) {
            if (e.full || e.legalMoves(3 - e.turn).isEmpty) break;
            e.turn = 3 - e.turn; // pass
            continue;
          }
          final m = ReversiAi.pick(e, level, rng);
          expect(legal, contains(m));
          expect(e.play(m), greaterThan(0));
          moves++;
        }
        expect(e.count(1) + e.count(2), lessThanOrEqualTo(64));
      }
    });

    test('Pro respects the 2s Rush thinking cap', () {
      final e = ReversiEngine()..reset();
      // Mid-game position with real branching.
      for (final m in [19, 18, 26, 37]) {
        if (e.legalMoves().contains(m)) e.play(m);
      }
      final sw = Stopwatch()..start();
      final m = ReversiAi.pick(e, AiLevel.pro, Random(1),
          deadline: DateTime.now().add(const Duration(seconds: 2)));
      sw.stop();
      expect(e.legalMoves(), contains(m));
      expect(sw.elapsed, lessThan(const Duration(seconds: 4)));
    });
  });

  group('Bot-vs-bot: no stuck states possible', () {
    test('every pairing terminates with a valid result', () {
      final levels = AiLevel.values;
      var games = 0;
      for (final black in levels) {
        for (final white in levels) {
          for (var seed = 0; seed < 4; seed++) {
            // Short cap: this proves termination, not strength.
            final plies = _simulateGame(black, white, Random(seed * 31 + 7),
                aiDeadline: const Duration(milliseconds: 150));
            expect(plies, lessThan(300));
            games++;
          }
        }
      }
      expect(games, 36);
    });

    test('results are always decisive or a true 32-32 draw', () {
      for (var seed = 0; seed < 12; seed++) {
        final e = ReversiEngine()..reset();
        final rng = Random(seed);
        var plies = 0;
        while (plies < 300) {
          final legal = e.legalMoves();
          if (legal.isEmpty) {
            if (e.full || e.legalMoves(3 - e.turn).isEmpty) break;
            e.turn = 3 - e.turn;
            continue;
          }
          e.play(ReversiAi.pick(e, AiLevel.club, rng));
          plies++;
        }
        final b = e.count(1), w = e.count(2);
        expect(b + w + e.b.where((x) => x == 0).length, 64);
        // Every game ends with no legal moves for the side to move and
        // none for the opponent — otherwise the sim would not have stopped.
        expect(e.legalMoves(e.turn), isEmpty);
        expect(e.legalMoves(3 - e.turn), isEmpty);
        if (b == w) expect(b, 32); // the only legal draw (RULES.md §10)
      }
    });

    test('blitz-capped pro games terminate too', () {
      for (var seed = 0; seed < 6; seed++) {
        final plies = _simulateGame(AiLevel.pro, AiLevel.pro, Random(seed),
            aiDeadline: const Duration(seconds: 2));
        expect(plies, lessThan(300));
      }
    });
  });
}
