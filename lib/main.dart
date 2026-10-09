import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'audio/club_audio.dart';
import 'services/iap_service.dart';
import 'state/club_state.dart';
import 'theme/club_theme.dart';
import 'ui/game_over_screen.dart';
import 'ui/game_screen.dart';
import 'ui/menu_screen.dart';
import 'ui/pro_screen.dart';
import 'ui/records_screen.dart';
import 'ui/settings_screen.dart';
import 'ui/splash_screen.dart';
import 'ui/theme_picker_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  final settings = ClubSettings();
  await settings.load();
  final records = ClubRecords();
  await records.load();
  final audio = ClubAudio();
  await audio.init(
      musicOn: settings.musicOn, sfxOn: settings.sfxOn, volume: settings.volume);
  await audio.applySettings();
  final store = StoreService();
  // Store init is best-effort and never blocks launch.
  unawaited(store.init());

  runApp(ClubApp(
      settings: settings, records: records, audio: audio, store: store));
}

enum _Screen { splash, menu, game, over, settings, records, themes, pro }

/// Reversi Rush — Mid-Century Speed Club edition.
class ClubApp extends StatefulWidget {
  final ClubSettings settings;
  final ClubRecords records;
  final ClubAudio audio;
  final StoreService store;

  const ClubApp({
    super.key,
    required this.settings,
    required this.records,
    required this.audio,
    required this.store,
  });

  @override
  State<ClubApp> createState() => _ClubAppState();
}

class _ClubAppState extends State<ClubApp> with WidgetsBindingObserver {
  _Screen _screen = _Screen.splash;
  _Screen _returnTo = _Screen.menu;
  late final ClubController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = ClubController(
      audio: widget.audio,
      settings: widget.settings,
      records: widget.records,
    );
    _controller.onGameOver = () {
      if (mounted) {
        setState(() => _screen = _Screen.over);
        widget.audio.startMenuMusic();
      }
    };
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _controller.onBackground();
      widget.audio.pauseMusic();
    } else if (state == AppLifecycleState.resumed) {
      widget.audio.resumeMusic();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    widget.audio.dispose();
    widget.store.dispose();
    super.dispose();
  }

  void _startGame(PlayMode mode, {bool blitzVsAi = false}) {
    widget.audio.play(ClubSound.click);
    _controller.startGame(
        mode: mode,
        aiLevel: widget.settings.aiLevel,
        blitzVsAi: mode == PlayMode.blitz ? blitzVsAi : false,
        blitzMinutes: widget.settings.blitzMinutes);
    widget.audio.startGameMusic();
    setState(() => _screen = _Screen.game);
  }

  void _openSettings() {
    _returnTo = _screen == _Screen.game ? _Screen.game : _Screen.menu;
    setState(() => _screen = _Screen.settings);
  }

  void _openThemes() {
    _returnTo = _screen == _Screen.game ? _Screen.game : _Screen.menu;
    setState(() => _screen = _Screen.themes);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reversi Rush',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: Club.body,
        scaffoldBackgroundColor: Club.cream,
        colorScheme: ColorScheme.fromSeed(seedColor: Club.brass),
        useMaterial3: true,
      ),
      home: switch (_screen) {
        _Screen.splash => SplashScreen(
            audio: widget.audio,
            settings: widget.settings,
            onDone: () => setState(() => _screen = _Screen.menu),
          ),
        _Screen.menu => MenuScreen(
            settings: widget.settings,
            audio: widget.audio,
            store: widget.store,
            onPlayVsAi: () => _startGame(PlayMode.vsAi),
            onTwoPlayers: () => _startGame(PlayMode.twoPlayer),
            onBlitz: ({required bool vsAi}) =>
                _startGame(PlayMode.blitz, blitzVsAi: vsAi),
            onSettings: _openSettings,
            onRecords: () => setState(() => _screen = _Screen.records),
            onThemes: _openThemes,
            onPro: () {
              _returnTo = _Screen.menu;
              setState(() => _screen = _Screen.pro);
            },
          ),
        _Screen.game => GameScreen(
            controller: _controller,
            onQuitToMenu: () {
              _controller.pause();
              widget.audio.startMenuMusic();
              setState(() => _screen = _Screen.menu);
            },
            onOpenSettings: _openSettings,
          ),
        _Screen.over => GameOverScreen(
            controller: _controller,
            onRematch: () => _startGame(_controller.mode,
                blitzVsAi: _controller.blitzVsAi),
            onMenu: () => setState(() => _screen = _Screen.menu),
          ),
        _Screen.settings => SettingsScreen(
            settings: widget.settings,
            audio: widget.audio,
            onBack: () => setState(() => _screen = _returnTo),
            onThemes: _openThemes,
          ),
        _Screen.records => RecordsScreen(
            records: widget.records,
            onBack: () => setState(() => _screen = _Screen.menu),
          ),
        _Screen.themes => ThemePickerScreen(
            settings: widget.settings,
            audio: widget.audio,
            onBack: () => setState(() => _screen = _returnTo),
          ),
        _Screen.pro => ProScreen(
            store: widget.store,
            audio: widget.audio,
            onBack: () => setState(() => _screen = _returnTo),
          ),
      },
    );
  }
}
