import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../audio/club_audio.dart';
import '../engine/reversi.dart';
import '../theme/rush_themes.dart';

/// Game modes on the club menu.
enum PlayMode { vsAi, twoPlayer, blitz }

extension PlayModeLabel on PlayMode {
  String get label => switch (this) {
        PlayMode.vsAi => 'PLAY VS AI',
        PlayMode.twoPlayer => 'TWO PLAYERS',
        PlayMode.blitz => 'BLITZ MODE',
      };
}

/// Engine-owned turn phases. The engine (controller) — never UI timers —
/// owns every phase transition; a watchdog recovers any phase found without
/// a live driver. Stuck states are impossible by construction.
enum TurnPhase {
  idle, // no match running
  awaitingMove, // a side's move is expected; clocks tick
  aiThinking, // automaton computing on its own isolate
  animating, // placed disc + flip cascade playing visibly
  passNotice, // pass banner showing, then control hands over
  over, // match decided
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
  bool blitzVsAi = false;

  // Renameable pilot names, one slot per side per mode.
  String soloHuman = 'YOU';
  String soloAi = 'AUTOMATON';
  String duoBlack = 'BLACK';
  String duoWhite = 'WHITE';
  String blitzBlack = 'BLACK PILOT';
  String blitzWhite = 'WHITE PILOT';

  // Visual catalog choices.
  String themeId = 'teak';
  String discStyleId = 'enamel';
  Map<String, int> customTheme = {};
  Map<String, int> customDisc = {};

  static const _kMusic = 'rr_music';
  static const _kSfx = 'rr_sfx';
  static const _kHaptics = 'rr_haptics';
  static const _kHints = 'rr_hints';
  static const _kVolume = 'rr_volume';
  static const _kAi = 'rr_ai';
  static const _kBlitz = 'rr_blitz';
  static const _kBlitzVsAi = 'rr_blitz_vsai';
  static const _kTheme = 'rr_theme';
  static const _kDisc = 'rr_disc';
  static const _kCustomTheme = 'rr_custom_theme';
  static const _kCustomDisc = 'rr_custom_disc';

  static const _nameKeys = {
    'soloHuman': 'rr_name_solo1',
    'soloAi': 'rr_name_solo2',
    'duoBlack': 'rr_name_duo1',
    'duoWhite': 'rr_name_duo2',
    'blitzBlack': 'rr_name_blitz1',
    'blitzWhite': 'rr_name_blitz2',
  };

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    hapticsOn = p.getBool(_kHaptics) ?? true;
    hintsOn = p.getBool(_kHints) ?? true;
    volume = p.getDouble(_kVolume) ?? 0.7;
    aiLevel = AiLevel.values[p.getInt(_kAi) ?? 1];
    blitzMinutes = p.getInt(_kBlitz) ?? 5;
    blitzVsAi = p.getBool(_kBlitzVsAi) ?? false;
    themeId = p.getString(_kTheme) ?? 'teak';
    discStyleId = p.getString(_kDisc) ?? 'enamel';
    soloHuman = p.getString(_nameKeys['soloHuman']!) ?? 'YOU';
    soloAi = p.getString(_nameKeys['soloAi']!) ?? 'AUTOMATON';
    duoBlack = p.getString(_nameKeys['duoBlack']!) ?? 'BLACK';
    duoWhite = p.getString(_nameKeys['duoWhite']!) ?? 'WHITE';
    blitzBlack = p.getString(_nameKeys['blitzBlack']!) ?? 'BLACK PILOT';
    blitzWhite = p.getString(_nameKeys['blitzWhite']!) ?? 'WHITE PILOT';
    final ct = p.getString(_kCustomTheme);
    if (ct != null && ct.isNotEmpty) {
      customTheme = {
        for (final e in ct.split(';'))
          if (e.contains('=')) e.split('=')[0]: int.parse(e.split('=')[1])
      };
    }
    final cd = p.getString(_kCustomDisc);
    if (cd != null && cd.isNotEmpty) {
      customDisc = {
        for (final e in cd.split(';'))
          if (e.contains('=')) e.split('=')[0]: int.parse(e.split('=')[1])
      };
    }
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
    await p.setBool(_kBlitzVsAi, blitzVsAi);
    await p.setString(_kTheme, themeId);
    await p.setString(_kDisc, discStyleId);
    await p.setString(_nameKeys['soloHuman']!, soloHuman);
    await p.setString(_nameKeys['soloAi']!, soloAi);
    await p.setString(_nameKeys['duoBlack']!, duoBlack);
    await p.setString(_nameKeys['duoWhite']!, duoWhite);
    await p.setString(_nameKeys['blitzBlack']!, blitzBlack);
    await p.setString(_nameKeys['blitzWhite']!, blitzWhite);
    await p.setString(
        _kCustomTheme, customTheme.entries.map((e) => '${e.key}=${e.value}').join(';'));
    await p.setString(
        _kCustomDisc, customDisc.entries.map((e) => '${e.key}=${e.value}').join(';'));
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

  void setBlitzVsAi(bool v) {
    blitzVsAi = v;
    notifyListeners();
    save();
  }

  void setTheme(String id) {
    themeId = id;
    notifyListeners();
    save();
  }

  void setDiscStyle(String id) {
    discStyleId = id;
    notifyListeners();
    save();
  }

  void setCustomTheme(Map<String, int> j) {
    customTheme = Map.of(j);
    themeId = 'custom';
    notifyListeners();
    save();
  }

  void setCustomDisc(Map<String, int> j) {
    customDisc = Map.of(j);
    discStyleId = 'custom';
    notifyListeners();
    save();
  }

  void setPilotName(String slot, String name) {
    final clean = name.trim().isEmpty ? _defaultName(slot) : name.trim();
    switch (slot) {
      case 'soloHuman':
        soloHuman = clean;
      case 'soloAi':
        soloAi = clean;
      case 'duoBlack':
        duoBlack = clean;
      case 'duoWhite':
        duoWhite = clean;
      case 'blitzBlack':
        blitzBlack = clean;
      case 'blitzWhite':
        blitzWhite = clean;
    }
    notifyListeners();
    save();
  }

  String pilotName(String slot) => switch (slot) {
        'soloHuman' => soloHuman,
        'soloAi' => soloAi,
        'duoBlack' => duoBlack,
        'duoWhite' => duoWhite,
        'blitzBlack' => blitzBlack,
        'blitzWhite' => blitzWhite,
        _ => _defaultName(slot),
      };

  static String _defaultName(String slot) => switch (slot) {
        'soloHuman' => 'YOU',
        'soloAi' => 'AUTOMATON',
        'duoBlack' => 'BLACK',
        'duoWhite' => 'WHITE',
        'blitzBlack' => 'BLACK PILOT',
        'blitzWhite' => 'WHITE PILOT',
        _ => 'PILOT',
      };

  RushTheme get theme => RushThemes.byId(themeId,
      custom: customTheme.isEmpty
          ? null
          : RushTheme.fromJson('custom', 'Custom Table', customTheme));

  DiscStyle get discStyle => DiscStyles.byId(discStyleId,
      customJson: customDisc.isEmpty ? null : customDisc);

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
  final int maxChain;
  final String narration;
  _Snapshot(
      {required this.board,
      required this.turn,
      required this.blackClock,
      required this.whiteClock,
      required this.elapsed,
      required this.movesMade,
      required this.totalFlipped,
      required this.maxChain,
      required this.narration});
}

/// Owns a single match: engine, clocks, AI scheduling, staged animations,
/// narration, watchdog. The engine owns ALL turn state; UI only paints.
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
  bool blitzVsAi = false;

  TurnPhase phase = TurnPhase.idle;
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
  Set<int> justFlipped = {}; // full flipped set for this move
  Set<int> visibleFlipped = {}; // progressively revealed cascade waves
  int shakeIndex = -1;
  int shakeGen = 0;
  int hintPulseIndex = -1;
  int hintPulseGen = 0;
  String? passBanner;
  String narration = '';

  // Match stats.
  int movesMade = 0;
  int totalFlipped = 0;
  int maxChain = 0;

  bool aiThinking = false;
  DateTime? _aiThinkStarted;
  Timer? _ticker;
  Timer? _aiTimer;
  Timer? _hintTimer;
  Timer? _passTimer;
  Timer? _waveTimer;
  Timer? _watchdog;
  int _lastTickSecond = -1;
  int _animToken = 0;
  final List<_Snapshot> _undo = [];

  // Blitz readiness gate: each pilot confirms on the shared device.
  bool readyBlack = false;
  bool readyWhite = false;

  /// Fired once when the game ends so the app can show the results screen.
  VoidCallback? onGameOver;

  /// Human's color in solo modes (always black); 0 in two-player duels.
  int get humanColor => mode == PlayMode.twoPlayer ? 0 : 1;

  bool get isBlitz => mode == PlayMode.blitz;
  bool get undoAvailable =>
      !isBlitz &&
      !aiThinking &&
      !over &&
      !paused &&
      phase == TurnPhase.awaitingMove &&
      _undo.isNotEmpty;
  bool get _aiTurn {
    if (over || paused) return false;
    if (mode == PlayMode.vsAi) return engine.turn == 2;
    if (mode == PlayMode.blitz && blitzVsAi) return engine.turn == 2;
    return false;
  }

  bool get _awaitingInput =>
      !over &&
      !paused &&
      phase == TurnPhase.awaitingMove &&
      !_aiTurn &&
      !aiThinking;

  /// Pilot slot keys for the current mode, for rename UI.
  List<String> get nameSlots => switch (mode) {
        PlayMode.vsAi => ['soloHuman', 'soloAi'],
        PlayMode.twoPlayer => ['duoBlack', 'duoWhite'],
        PlayMode.blitz => ['blitzBlack', 'blitzWhite'],
      };

  String playerName(int color) {
    switch (mode) {
      case PlayMode.vsAi:
        return color == 1 ? settings.soloHuman : settings.soloAi;
      case PlayMode.twoPlayer:
        return color == 1 ? settings.duoBlack : settings.duoWhite;
      case PlayMode.blitz:
        return color == 1 ? settings.blitzBlack : settings.blitzWhite;
    }
  }

  void startGame(
      {required PlayMode mode,
      required AiLevel aiLevel,
      bool? blitzVsAi,
      int? blitzMinutes}) {
    _disposeTimers(keepWatchdog: true);
    this.mode = mode;
    this.aiLevel = aiLevel;
    this.blitzVsAi = blitzVsAi ?? settings.blitzVsAi;
    engine.reset();
    phase = TurnPhase.idle;
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
    visibleFlipped = {};
    passBanner = null;
    hintPulseIndex = -1;
    aiThinking = false;
    _aiThinkStarted = null;
    _undo.clear();
    _lastTickSecond = -1;
    elapsed = 0;
    readyBlack = false;
    readyWhite = false;
    clockTotal = ((blitzMinutes ?? settings.blitzMinutes) * 60).toDouble();
    blackClock = clockTotal;
    whiteClock = clockTotal;
    _refreshLegal();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), _tick);
    _watchdog ??= Timer.periodic(const Duration(milliseconds: 750), (_) {
      _watchdogTick();
    });
    narration = _turnPrompt();
    // Blitz waits for the starter's flag: both pilots confirm readiness.
    if (isBlitz) {
      paused = true;
      phase = TurnPhase.idle;
    } else {
      phase = TurnPhase.awaitingMove;
      audio.play(ClubSound.gameStart);
    }
    _scheduleAi();
    notifyListeners();
  }

  void _disposeTimers({bool keepWatchdog = false}) {
    _ticker?.cancel();
    _ticker = null;
    _aiTimer?.cancel();
    _aiTimer = null;
    _hintTimer?.cancel();
    _hintTimer = null;
    _passTimer?.cancel();
    _passTimer = null;
    _waveTimer?.cancel();
    _waveTimer = null;
    if (!keepWatchdog) {
      _watchdog?.cancel();
      _watchdog = null;
    }
  }

  void _refreshLegal() {
    legal = engine.legalMoves().toSet();
  }

  String _turnPrompt() {
    if (over) return endReason;
    final n = playerName(engine.turn);
    if (_aiTurn) return '$n IS THINKING…';
    return '$n — PLACE A ${engine.turn == 1 ? 'BLACK' : 'WHITE'} DISC';
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
        audio.play(ClubSound.timeUp);
        _endGame(winnerColor: 3 - engine.turn, wonOnTime: true);
        return;
      }
    } else {
      elapsed += 0.1;
    }
    notifyListeners();
  }

  // ---------- watchdog ----------
  //
  // Runs every 750ms and repairs any phase found without a live driver:
  // missed AI scheduling, a stuck AI timer, a vanished wave timer, or a
  // legal-move set that disagrees with the engine. The game can never sit
  // in a state with no legal forward action.

  void _watchdogTick() {
    if (over || paused) return;
    // 1. The side to move is the automaton but nothing is driving it.
    if (_aiTurn &&
        !aiThinking &&
        phase != TurnPhase.animating &&
        phase != TurnPhase.passNotice &&
        (_aiTimer == null || !_aiTimer!.isActive)) {
      _scheduleAi();
      return;
    }
    // 2. AI thinking ran past its sanity cap — kill and reschedule.
    if (aiThinking &&
        _aiThinkStarted != null &&
        DateTime.now().difference(_aiThinkStarted!) >
            const Duration(seconds: 12)) {
      _aiTimer?.cancel();
      _aiTimer = null;
      aiThinking = false;
      _scheduleAi();
      return;
    }
    // 3. Animation phase with no live wave driver — finish the cascade.
    if (phase == TurnPhase.animating &&
        (_waveTimer == null || !_waveTimer!.isActive)) {
      visibleFlipped = Set.of(justFlipped);
      _finishMove();
      return;
    }
    // 4. Awaiting a move but the engine disagrees about legality — settle.
    if (phase == TurnPhase.awaitingMove) {
      final engineLegal = engine.legalMoves();
      if (legal.isEmpty && engineLegal.isNotEmpty) {
        _refreshLegal();
        notifyListeners();
      } else if (engineLegal.isEmpty) {
        _settleTurn();
      }
    }
  }

  // ---------- player input ----------

  void tapCell(int i) {
    if (!_awaitingInput) return;
    if (!legal.contains(i)) {
      // Illegal tap: ignored with a subtle shake (RULES.md §13.7).
      shakeIndex = i;
      shakeGen++;
      audio.play(ClubSound.invalid);
      settings.buzz();
      notifyListeners();
      return;
    }
    _executeMove(i);
  }

  /// Engine-owned move execution: the placed disc drops, then every
  /// outflanked direction flips as a visible cascade wave — nothing
  /// resolves instantly or silently.
  void _executeMove(int i) {
    final mover = engine.turn;
    _pushUndo();
    final waves = engine.flipLines(i, mover);
    final flips = engine.play(i);
    _animToken++;
    final token = _animToken;
    justPlaced = i;
    justFlipped = waves.expand((w) => w).toSet();
    visibleFlipped = {};
    phase = TurnPhase.animating;
    movesMade++;
    totalFlipped += flips;
    maxChain = max(maxChain, flips);
    final sq = ReversiEngine.squareName(i);
    narration = waves.length <= 1
        ? '${playerName(mover)} PLAYS $sq — FLIPS $flips'
        : '${playerName(mover)} PLAYS $sq — ${waves.length}-WAY FLIP ×$flips';
    animGen++;
    audio.play(ClubSound.place);
    settings.buzz();
    notifyListeners();
    _waveTimer?.cancel();
    var waveIdx = 0;
    _waveTimer = Timer.periodic(const Duration(milliseconds: 200), (t) {
      if (token != _animToken || over) {
        t.cancel();
        return;
      }
      if (waveIdx < waves.length) {
        visibleFlipped.addAll(waves[waveIdx]);
        waveIdx++;
        audio.play(ClubSound.flip);
        notifyListeners();
      } else {
        t.cancel();
        _finishMove();
      }
    });
  }

  /// The cascade finished: resolve pass / game-end / next turn.
  void _finishMove() {
    _waveTimer?.cancel();
    _waveTimer = null;
    justPlaced = null;
    _settleTurn();
  }

  void _settleTurn() {
    if (over) return;
    phase = TurnPhase.awaitingMove;
    // Auto-pass when the side to move has no legal move (RULES.md §7).
    if (engine.legalMoves().isEmpty) {
      if (engine.full || engine.legalMoves(3 - engine.turn).isEmpty) {
        _endGame(winnerColor: _countWinner(), wonOnTime: false);
        return;
      }
      phase = TurnPhase.passNotice;
      passBanner = '${playerName(engine.turn)} PASSES — NO LEGAL MOVE';
      narration = passBanner!;
      audio.play(ClubSound.pass);
      engine.turn = 3 - engine.turn; // pass
      notifyListeners();
      _passTimer?.cancel();
      _passTimer = Timer(const Duration(milliseconds: 1600), () {
        passBanner = null;
        _settleTurnComplete();
      });
      return;
    }
    _settleTurnComplete();
  }

  void _settleTurnComplete() {
    if (over) return;
    phase = TurnPhase.awaitingMove;
    _refreshLegal();
    narration = _turnPrompt();
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
    _aiTimer = null;
    if (!_aiTurn) {
      aiThinking = false;
      return;
    }
    aiThinking = true;
    _aiThinkStarted = DateTime.now();
    phase = TurnPhase.aiThinking;
    narration = '${playerName(engine.turn)} IS THINKING…';
    notifyListeners();
    final board = List<int>.from(engine.b);
    final turn = engine.turn;
    final level = aiLevel;
    final seed = rng.nextInt(1 << 30);
    // Visible beat before the automaton commits — bot turns are never
    // instant.
    _aiTimer =
        Timer(Duration(milliseconds: 700 + rng.nextInt(500)), () async {
      if (over || paused || engine.turn != turn) {
        aiThinking = false;
        _scheduleAi();
        return;
      }
      try {
        // RULES.md §11: in Rush mode the AI never exceeds its thinking cap.
        final deadline = isBlitz
            ? DateTime.now().add(const Duration(seconds: 2))
            : null;
        final move = await Isolate.run(
            () => _aiIsolatePickWithDeadline((board, turn, level.index, seed),
                deadline?.millisecondsSinceEpoch));
        if (over || paused || engine.turn != turn) {
          aiThinking = false;
          _scheduleAi();
          return;
        }
        aiThinking = false;
        _aiThinkStarted = null;
        if (!engine.legalMoves(turn).contains(move)) {
          // Paranoia: never play an illegal move. Settle instead.
          _settleTurn();
          return;
        }
        _executeMove(move);
      } catch (_) {
        aiThinking = false;
        _aiThinkStarted = null;
        // Fallback: a fast greedy move keeps the game un-stuck; the
        // watchdog would otherwise reschedule anyway.
        final moves = engine.legalMoves(turn);
        if (moves.isNotEmpty && engine.turn == turn && !over && !paused) {
          _executeMove(moves[rng.nextInt(moves.length)]);
        } else {
          _settleTurn();
        }
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
      maxChain: maxChain,
      narration: narration,
    ));
    if (_undo.length > 60) _undo.removeAt(0);
  }

  /// Undo restores the board and clocks to before the last move (a pass is
  /// also reverted, restoring the turn — RULES.md §7). Disabled in blitz.
  void undo() {
    if (!undoAvailable) return;
    audio.play(ClubSound.click);
    _Snapshot s = _undo.removeLast();
    if (mode != PlayMode.twoPlayer) {
      // Revert the automaton's reply too, back to the human's last turn.
      while (s.turn != humanColor && _undo.isNotEmpty) {
        s = _undo.removeLast();
      }
    }
    _restore(s);
    _animToken++; // cancel any stray wave driver
    _waveTimer?.cancel();
    _waveTimer = null;
    justPlaced = null;
    justFlipped = {};
    visibleFlipped = {};
    passBanner = null;
    phase = TurnPhase.awaitingMove;
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
    maxChain = s.maxChain;
    narration = s.narration;
    _refreshLegal();
  }

  /// Highlights one legal square for a moment. Never affects scoring.
  void hint() {
    if (!_awaitingInput || legal.isEmpty) return;
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
    _aiTimer = null;
    aiThinking = false;
    _animToken++; // freeze any in-flight cascade driver; watchdog restarts it
    audio.play(ClubSound.click);
    notifyListeners();
  }

  void resume() {
    if (over || !paused) return;
    paused = false;
    audio.play(ClubSound.gameStart);
    // If we froze mid-cascade, reveal the rest instantly and settle.
    if (phase == TurnPhase.animating) {
      visibleFlipped = Set.of(justFlipped);
      _finishMove();
    } else {
      _settleTurnComplete();
    }
    notifyListeners();
  }

  /// Blitz readiness gate: each pilot confirms in turn, then the chrono
  /// starts (RULES.md §7: the game may not start until both confirm).
  void ready(int color) {
    if (over || !paused || !isBlitz) return;
    if (color == 1) {
      readyBlack = true;
    } else {
      readyWhite = true;
    }
    audio.play(ClubSound.click);
    if (readyBlack && readyWhite) {
      paused = false;
      phase = TurnPhase.awaitingMove;
      narration = _turnPrompt();
      audio.play(ClubSound.gameStart);
    }
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
    startGame(mode: mode, aiLevel: aiLevel, blitzVsAi: blitzVsAi);
  }

  // ---------- game end ----------

  void _endGame(
      {required int winnerColor, required bool wonOnTime, bool resigned = false}) {
    if (over) return;
    over = true;
    phase = TurnPhase.over;
    _disposeTimers(keepWatchdog: true);
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
    narration = endReason;
    final humanWon = humanColor != 0 && winnerColor == humanColor;
    final humanLost =
        humanColor != 0 && winnerColor != 0 && winnerColor != humanColor;
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
    _disposeTimers();
    super.dispose();
  }
}

int _aiIsolatePickWithDeadline(
    (List<int>, int, int, int) args, int? deadlineMs) {
  final e = ReversiEngine()
    ..b = List<int>.from(args.$1)
    ..turn = args.$2;
  return ReversiAi.pick(
      e,
      AiLevel.values[args.$3],
      Random(args.$4),
      deadline: deadlineMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(deadlineMs));
}
