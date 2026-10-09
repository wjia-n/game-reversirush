import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../audio/club_audio.dart';
import '../engine/reversi.dart';

/// Game modes on the club menu.
enum PlayMode { vsAi, twoPlayer, blitz }

extension PlayModeLabel on PlayMode {
  String get label => switch (this) {
        PlayMode.vsAi => 'PLAY VS AI',
        PlayMode.twoPlayer => 'TWO PLAYERS',
        PlayMode.blitz => 'BLITZ MODE',
      };
}

/// Persisted club preferences.
class ClubSettings extends ChangeNotifier {
  bool musicOn = true;
  bool sfxOn = true;
  bool hapticsOn = true;
  bool hintsOn = true;
  double volume = 0.7;
  AiLevel aiLevel = AiLevel.club;
  int blitzMinutes = 5;

  static const _kMusic = 'rr_music';
  static const _kSfx = 'rr_sfx';
  static const _kHaptics = 'rr_haptics';
  static const _kHints = 'rr_hints';
  static const _kVolume = 'rr_volume';
  static const _kAi = 'rr_ai';
  static const _kBlitz = 'rr_blitz';

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    hapticsOn = p.getBool(_kHaptics) ?? true;
    hintsOn = p.getBool(_kHints) ?? true;
    volume = p.getDouble(_kVolume) ?? 0.7;
    aiLevel = AiLevel.values[p.getInt(_kAi) ?? 1];
    blitzMinutes = p.getInt(_kBlitz) ?? 5;
    notifyListeners();
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kMusic, musicOn);
    await p.setBool(_kSfx, sfxOn);
    await p.setBool(_kHaptics, hapticsOn);
    await p.setBool(_kHints, hintsOn);
    await p.setDouble(_kVolume, volume);
    await p.setInt(_kAi, aiLevel.index);
    await p.setInt(_kBlitz, blitzMinutes);
  }

  // UI-facing mutators: update, notify, persist.
  void setMusic(bool v) {
    musicOn = v;
    notifyListeners();
    save();
  }

  void setSfx(bool v) {
    sfxOn = v;
    notifyListeners();
    save();
  }

  void setHaptics(bool v) {
    hapticsOn = v;
    notifyListeners();
    save();
  }

  void setHints(bool v) {
    hintsOn = v;
    notifyListeners();
    save();
  }

  void setVolume(double v) {
    volume = v;
    notifyListeners();
    save();
  }

  void setAiLevel(AiLevel v) {
    aiLevel = v;
    notifyListeners();
    save();
  }

  void setBlitzMinutes(int v) {
    blitzMinutes = v;
    notifyListeners();
    save();
  }

  void buzz() {
    if (hapticsOn) HapticFeedback.lightImpact();
  }
}

/// Persisted club records.
class ClubRecords extends ChangeNotifier {
  int gamesPlayed = 0;
  int wins = 0;
  int losses = 0;
  int draws = 0;
  int bestMargin = 0;
  int mostFlipped = 0;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    gamesPlayed = p.getInt('rr_r_games') ?? 0;
    wins = p.getInt('rr_r_wins') ?? 0;
    losses = p.getInt('rr_r_losses') ?? 0;
    draws = p.getInt('rr_r_draws') ?? 0;
    bestMargin = p.getInt('rr_r_margin') ?? 0;
    mostFlipped = p.getInt('rr_r_flipped') ?? 0;
    notifyListeners();
  }

  /// Records a finished game. [humanColor] is 0 when no human perspective
  /// (two-player duel): only shared stats are updated then.
  Future<void> recordGame(
      {required int winnerColor,
      required int blackCount,
      required int whiteCount,
      required int humanColor,
      required int maxChain}) async {
    gamesPlayed++;
    final margin = (blackCount - whiteCount).abs();
    if (winnerColor == 0) {
      draws++;
    } else if (humanColor != 0) {
      if (winnerColor == humanColor) {
        wins++;
      } else {
        losses++;
      }
    }
    if (margin > bestMargin) bestMargin = margin;
    if (maxChain > mostFlipped) mostFlipped = maxChain;
    final p = await SharedPreferences.getInstance();
    await p.setInt('rr_r_games', gamesPlayed);
    await p.setInt('rr_r_wins', wins);
    await p.setInt('rr_r_losses', losses);
    await p.setInt('rr_r_draws', draws);
    await p.setInt('rr_r_margin', bestMargin);
    await p.setInt('rr_r_flipped', mostFlipped);
    notifyListeners();
  }
}

class _Snapshot {
  final List<int> board;
  final int turn;
  final double blackClock;
  final double whiteClock;
  final double elapsed;
  final int movesMade;
  final int totalFlipped;
  _Snapshot(
      {required this.board,
      required this.turn,
      required this.blackClock,
      required this.whiteClock,
      required this.elapsed,
      required this.movesMade,
      required this.totalFlipped});
}

int _aiIsolatePick((List<int>, int, int, int) args) {
  final e = ReversiEngine()
    ..b = List<int>.from(args.$1)
    ..turn = args.$2;
  return ReversiAi.pick(e, AiLevel.values[args.$3], Random(args.$4));
}

/// Owns a single match: engine, clocks, AI scheduling, animations, sounds.
class ClubController extends ChangeNotifier {
  final ClubAudio audio;
  final ClubSettings settings;
  final ClubRecords records;
  final Random rng = Random();

  ClubController(
      {required this.audio, required this.settings, required this.records});

  final ReversiEngine engine = ReversiEngine();
  PlayMode mode = PlayMode.vsAi;
  AiLevel aiLevel = AiLevel.club;

  Set<int> legal = {};
  bool over = false;
  bool paused = false;
  int winnerColor = 0; // 0 = draw/undecided, 1 = black, 2 = white
  String endReason = '';
  bool wonOnTime = false;

  // Blitz clocks (seconds remaining per pilot).
  double blackClock = 300;
  double whiteClock = 300;
  double clockTotal = 300;
  double elapsed = 0; // untimed games

  // Animation / feedback state.
  int animGen = 0;
  int? justPlaced;
  Set<int> justFlipped = {};
  int shakeIndex = -1;
  int shakeGen = 0;
  int hintPulseIndex = -1;
  int hintPulseGen = 0;
  String? passBanner;

  // Match stats.
  int movesMade = 0;
  int totalFlipped = 0;
  int maxChain = 0;

  bool aiThinking = false;
  Timer? _ticker;
  Timer? _aiTimer;
  Timer? _hintTimer;
  Timer? _passTimer;
  int _lastTickSecond = -1;
  final List<_Snapshot> _undo = [];

  /// Fired once when the game ends so the app can show the results screen.
  VoidCallback? onGameOver;

  /// Human's color in solo modes (always black); 0 in two-player duels.
  int get humanColor => mode == PlayMode.twoPlayer ? 0 : 1;

  bool get isBlitz => mode == PlayMode.blitz;
  bool get undoAvailable =>
      !isBlitz && !aiThinking && !over && !paused && _undo.isNotEmpty;
  bool get _aiTurn =>
      mode != PlayMode.twoPlayer && engine.turn == 2 && !over && !paused;

  String playerName(int color) {
    if (mode == PlayMode.twoPlayer) {
      return color == 1 ? 'BLACK' : 'WHITE';
    }
    return color == 1 ? 'YOU' : 'AUTOMATON';
  }

  void startGame(
      {required PlayMode mode, required AiLevel aiLevel, int? blitzMinutes}) {
    this.mode = mode;
    this.aiLevel = aiLevel;
    engine.reset();
    over = false;
    paused = false;
    winnerColor = 0;
    endReason = '';
    wonOnTime = false;
    movesMade = 0;
    totalFlipped = 0;
    maxChain = 0;
    justPlaced = null;
    justFlipped = {};
    passBanner = null;
    hintPulseIndex = -1;
    aiThinking = false;
    _undo.clear();
    _lastTickSecond = -1;
    elapsed = 0;
    clockTotal = ((blitzMinutes ?? settings.blitzMinutes) * 60).toDouble();
    blackClock = clockTotal;
    whiteClock = clockTotal;
    _refreshLegal();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), _tick);
    // Blitz waits for the starter's flag: both pilots confirm readiness.
    if (isBlitz) {
      paused = true;
    } else {
      audio.play(ClubSound.gameStart);
    }
    _scheduleAi();
    notifyListeners();
  }

  void _refreshLegal() {
    legal = engine.legalMoves().toSet();
  }

  void _tick(Timer t) {
    if (paused || over) return;
    if (isBlitz) {
      if (engine.turn == 1) {
        blackClock -= 0.1;
      } else {
        whiteClock -= 0.1;
      }
      final active = engine.turn == 1 ? blackClock : whiteClock;
      // Stopwatch countdown ticks in the final stretch.
      final sec = active.ceil();
      if (active <= 10.5 && sec != _lastTickSecond && active > 0) {
        _lastTickSecond = sec;
        audio.play(ClubSound.tick);
      }
      if (active <= 0) {
        if (engine.turn == 1) {
          blackClock = 0;
        } else {
          whiteClock = 0;
        }
        _endGame(winnerColor: 3 - engine.turn, wonOnTime: true);
        return;
      }
    } else {
      elapsed += 0.1;
    }
    notifyListeners();
  }

  // ---------- player input ----------

  void tapCell(int i) {
    if (over || paused || aiThinking) return;
    if (mode != PlayMode.twoPlayer && engine.turn != humanColor) return;
    if (!legal.contains(i)) {
      // Illegal tap: ignored with a subtle shake (RULES.md §13.7).
      shakeIndex = i;
      shakeGen++;
      audio.play(ClubSound.invalid);
      settings.buzz();
      notifyListeners();
      return;
    }
    _pushUndo();
    final flips = engine.play(i);
    _afterHumanOrAiMove(i, flips);
  }

  void _afterHumanOrAiMove(int i, int flips) {
    justPlaced = i;
    // The placed color is the previous turn (engine.turn already switched).
    justFlipped = _bracketed(i, 3 - engine.turn);
    animGen++;
    movesMade++;
    totalFlipped += flips;
    maxChain = max(maxChain, flips);
    audio.play(ClubSound.place);
    Future.delayed(const Duration(milliseconds: 120), () {
      if (!over) audio.play(ClubSound.flip);
    });
    settings.buzz();
    _afterMove();
  }

  /// All discs that were flipped by placing [i] for [color].
  Set<int> _bracketed(int i, int color) {
    final foe = 3 - color;
    final r = i ~/ 8, c = i % 8;
    final out = <int>{};
    for (final d in ReversiEngine.dirs) {
      final line = <int>[];
      var nr = r + d[0], nc = c + d[1];
      while (nr >= 0 && nr < 8 && nc >= 0 && nc < 8) {
        final v = engine.b[nr * 8 + nc];
        if (v == foe) {
          line.add(nr * 8 + nc);
        } else {
          if (v == color && line.isNotEmpty) out.addAll(line);
          break;
        }
        nr += d[0];
        nc += d[1];
      }
    }
    return out;
  }

  void _afterMove() {
    // Auto-pass when the side to move has no legal move (RULES.md §7).
    if (engine.legalMoves().isEmpty) {
      if (engine.full || engine.legalMoves(3 - engine.turn).isEmpty) {
        _endGame(winnerColor: _countWinner(), wonOnTime: false);
        return;
      }
      passBanner = '${playerName(engine.turn)} PASSES';
      audio.play(ClubSound.pass);
      engine.turn = 3 - engine.turn; // pass
      _passTimer?.cancel();
      _passTimer = Timer(const Duration(milliseconds: 1400), () {
        passBanner = null;
        notifyListeners();
      });
    }
    _refreshLegal();
    notifyListeners();
    _scheduleAi();
  }

  int _countWinner() {
    final b = engine.count(1), w = engine.count(2);
    if (b == w) return 0;
    return b > w ? 1 : 2;
  }

  // ---------- AI ----------

  void _scheduleAi() {
    _aiTimer?.cancel();
    if (!_aiTurn) return;
    aiThinking = true;
    notifyListeners();
    final board = List<int>.from(engine.b);
    final turn = engine.turn;
    final level = aiLevel;
    final seed = rng.nextInt(1 << 30);
    _aiTimer = Timer(Duration(milliseconds: 450 + rng.nextInt(350)), () async {
      if (over || paused || engine.turn != 2) {
        aiThinking = false;
        notifyListeners();
        return;
      }
      try {
        final move = await Isolate.run(() => _aiIsolatePick((board, turn, level.index, seed)));
        if (over || paused || engine.turn != 2) {
          aiThinking = false;
          notifyListeners();
          return;
        }
        aiThinking = false;
        _pushUndo();
        final flips = engine.play(move);
        _afterHumanOrAiMove(move, flips);
      } catch (_) {
        aiThinking = false;
        notifyListeners();
      }
    });
  }

  void _pushUndo() {
    _undo.add(_Snapshot(
      board: List<int>.from(engine.b),
      turn: engine.turn,
      blackClock: blackClock,
      whiteClock: whiteClock,
      elapsed: elapsed,
      movesMade: movesMade,
      totalFlipped: totalFlipped,
    ));
    if (_undo.length > 60) _undo.removeAt(0);
  }

  /// Undo restores the board to before the last move (a pass is also
  /// reverted, restoring the turn — RULES.md §7). Disabled in blitz.
  void undo() {
    if (!undoAvailable) return;
    audio.play(ClubSound.click);
    if (mode == PlayMode.twoPlayer) {
      _restore(_undo.removeLast());
    } else {
      // Revert the automaton's reply too, back to the human's last turn.
      _Snapshot s = _undo.removeLast();
      while (s.turn != humanColor && _undo.isNotEmpty) {
        s = _undo.removeLast();
      }
      _restore(s);
    }
    justPlaced = null;
    justFlipped = {};
    animGen++;
    notifyListeners();
  }

  void _restore(_Snapshot s) {
    engine.b = List<int>.from(s.board);
    engine.turn = s.turn;
    blackClock = s.blackClock;
    whiteClock = s.whiteClock;
    elapsed = s.elapsed;
    movesMade = s.movesMade;
    totalFlipped = s.totalFlipped;
    _refreshLegal();
  }

  /// Highlights one legal square for a moment. Never affects scoring.
  void hint() {
    if (over || paused || aiThinking || legal.isEmpty) return;
    if (mode != PlayMode.twoPlayer && engine.turn != humanColor) return;
    final move = ReversiAi.pick(engine, AiLevel.casual, rng);
    hintPulseIndex = move;
    hintPulseGen++;
    audio.play(ClubSound.hint);
    notifyListeners();
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(milliseconds: 2200), () {
      hintPulseIndex = -1;
      notifyListeners();
    });
  }

  // ---------- pause / resume / lifecycle ----------

  void pause() {
    if (over || paused) return;
    paused = true;
    _aiTimer?.cancel();
    aiThinking = false;
    audio.play(ClubSound.click);
    notifyListeners();
  }

  void resume() {
    if (over || !paused) return;
    paused = false;
    audio.play(ClubSound.gameStart);
    _scheduleAi();
    notifyListeners();
  }

  /// Blitz readiness gate: both pilots confirm, then the chrono starts.
  void ready() {
    if (over || !paused) return;
    paused = false;
    audio.play(ClubSound.gameStart);
    notifyListeners();
  }

  void onBackground() {
    if (!over && !paused) pause();
  }

  /// A pilot may concede at any time; the opponent wins immediately.
  void resign() {
    if (over) return;
    _endGame(winnerColor: 3 - engine.turn, wonOnTime: false, resigned: true);
  }

  void restart() {
    audio.play(ClubSound.click);
    startGame(mode: mode, aiLevel: aiLevel);
  }

  // ---------- game end ----------

  void _endGame(
      {required int winnerColor, required bool wonOnTime, bool resigned = false}) {
    if (over) return;
    over = true;
    _ticker?.cancel();
    _aiTimer?.cancel();
    aiThinking = false;
    this.winnerColor = winnerColor;
    this.wonOnTime = wonOnTime;
    final b = engine.count(1), w = engine.count(2);
    if (wonOnTime) {
      final loser = 3 - winnerColor;
      endReason =
          '${playerName(loser)} OUT OF TIME — ${playerName(winnerColor)} WINS ON TIME';
    } else if (resigned) {
      endReason = '${playerName(3 - winnerColor)} CONCEDES';
    } else if (winnerColor == 0) {
      endReason = 'DEAD EVEN — $b TO $w';
    } else {
      endReason = '${playerName(winnerColor)} TAKES IT $b–$w';
    }
    final humanWon = humanColor != 0 && winnerColor == humanColor;
    final humanLost = humanColor != 0 && winnerColor != 0 && winnerColor != humanColor;
    if (humanWon || (humanColor == 0 && winnerColor != 0)) {
      audio.play(ClubSound.win);
    } else if (humanLost) {
      audio.play(ClubSound.lose);
    } else {
      audio.play(ClubSound.win);
    }
    records.recordGame(
      winnerColor: winnerColor,
      blackCount: b,
      whiteCount: w,
      humanColor: humanColor,
      maxChain: maxChain,
    );
    notifyListeners();
    onGameOver?.call();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _aiTimer?.cancel();
    _hintTimer?.cancel();
    _passTimer?.cancel();
    super.dispose();
  }
}
