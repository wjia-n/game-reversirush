import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'audio/club_audio.dart';
import 'state/club_state.dart';
import 'theme/club_theme.dart';
import 'ui/game_over_screen.dart';
import 'ui/game_screen.dart';
import 'ui/menu_screen.dart';
import 'ui/records_screen.dart';
import 'ui/settings_screen.dart';

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

  runApp(ClubApp(settings: settings, records: records, audio: audio));
}

enum _Screen { menu, game, over, settings, records }

/// Reversi Rush — Mid-Century Speed Club edition.
class ClubApp extends StatefulWidget {
  final ClubSettings settings;
  final ClubRecords records;
  final ClubAudio audio;

  const ClubApp({
    super.key,
    required this.settings,
    required this.records,
    required this.audio,
  });

  @override
  State<ClubApp> createState() => _ClubAppState();
}

class _ClubAppState extends State<ClubApp> with WidgetsBindingObserver {
  _Screen _screen = _Screen.menu;
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
    widget.audio.startMenuMusic();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _controller.onBackground();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    widget.audio.dispose();
    super.dispose();
  }

  void _startGame(PlayMode mode) {
    widget.audio.play(ClubSound.click);
    _controller.startGame(
        mode: mode,
        aiLevel: widget.settings.aiLevel,
        blitzMinutes: widget.settings.blitzMinutes);
    widget.audio.startGameMusic();
    setState(() => _screen = _Screen.game);
  }

  void _openSettings() {
    _returnTo = _screen;
    setState(() => _screen = _Screen.settings);
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
        _Screen.menu => MenuScreen(
            settings: widget.settings,
            onPlayVsAi: () => _startGame(PlayMode.vsAi),
            onTwoPlayers: () => _startGame(PlayMode.twoPlayer),
            onBlitz: () => _startGame(PlayMode.blitz),
            onSettings: _openSettings,
            onRecords: () => setState(() => _screen = _Screen.records),
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
            onRematch: () => _startGame(_controller.mode),
            onMenu: () => setState(() => _screen = _Screen.menu),
          ),
        _Screen.settings => SettingsScreen(
            settings: widget.settings,
            audio: widget.audio,
            onBack: () => setState(() => _screen = _returnTo),
          ),
        _Screen.records => RecordsScreen(
            records: widget.records,
            onBack: () => setState(() => _screen = _Screen.menu),
          ),
      },
    );
  }
}
