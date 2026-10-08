import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const ReversiRushApp());

class ReversiRushApp extends StatelessWidget {
  const ReversiRushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      variant: ShellVariant.elegantSerif,
      title: 'Reversi Rush',
      tagline: 'Flip discs at lightning speed in this 60-second blitz! ⚫',
      emoji: '⚫',
      slug: 'reversirush',
      howToPlay:
          '• Black moves first. Tap a glowing dot to place your disc.\n• Outflank rival discs in any direction to flip them to your color!\n• No moves? You pass automatically. The clock never stops!\n• When the 60 seconds die, most discs on the board wins! ⚡',
      playerOptions: const [1, 2],
      supportsBots: true,
      gameBuilder: (ctx, players, cb) => ReversiRushScreen(players: players, callbacks: cb),
    );
  }
}
