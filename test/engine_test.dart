import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:reversirush/engine/reversi.dart';

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

    test('Multi-direction flip flips every bracketed line', () {
      final e = ReversiEngine();
      e.b = List.filled(64, 0);
      e.turn = 1;
      // Horizontal only: target (3,0)=24; white at 25,26; black anchor at 27.
      e.b[25] = 2;
      e.b[26] = 2;
      e.b[27] = 1;
      expect(e.flipsFor(24, 1).toSet(), {25, 26});
      // Add a vertical line too: white at (2,0)=16, black anchor at (1,0)=8.
      e.b[16] = 2;
      e.b[8] = 1;
      expect(e.flipsFor(24, 1).toSet(), {16, 25, 26});
      expect(e.play(24), 3);
      expect(e.b[16], 1);
      expect(e.b[25], 1);
    });

    test('AI plays legally across full games (Casual/Club)', () {
      for (final level in [AiLevel.casual, AiLevel.club]) {
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
  });
}
