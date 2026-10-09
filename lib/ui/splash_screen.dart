import 'package:flutter/material.dart';

import '../audio/club_audio.dart';
import '../state/club_state.dart';
import '../theme/club_theme.dart';

/// Launch splash flow per the club branding rules:
/// 1. WAJIHA company splash (official winged-W logo, untouched).
/// 2. Game splash: Reversi Rush logo + name, animated loading line,
///    "Credits: WAJIHA" with the company logo.
/// Audio is pre-warmed while the loading line runs.
class SplashScreen extends StatefulWidget {
  final ClubAudio audio;
  final ClubSettings settings;
  final VoidCallback onDone;

  const SplashScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.onDone,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _loader;
  late final AnimationController _fade;
  bool _company = true;

  @override
  void initState() {
    super.initState();
    _loader = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _run();
  }

  Future<void> _run() async {
    // Company moment first.
    widget.audio.prewarm();
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() => _company = false);
    _fade.forward();
    _loader.forward();
    widget.audio.startMenuMusic();
    await Future.delayed(const Duration(milliseconds: 2100));
    if (!mounted) return;
    widget.onDone();
  }

  @override
  void dispose() {
    _loader.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_company) {
      return Scaffold(
        backgroundColor: const Color(0xFF141210),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/wajiha_logo.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 18),
              Text(
                'WAJIHA',
                style: Club.label(26,
                    color: Club.cream, spacing: 8.0),
              ),
            ],
          ),
        ),
      );
    }
    return FadeTransition(
      opacity: _fade,
      child: Scaffold(
        backgroundColor: Club.walnut,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Club.brass, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x99000000),
                      offset: Offset(0, 10),
                      blurRadius: 24,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset('assets/reversirush_logo.png',
                    fit: BoxFit.cover),
              ),
              const SizedBox(height: 22),
              Text(
                'REVERSI RUSH',
                style: Club.hDisplay(44, color: Club.cream),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'MID-CENTURY SPEED CLUB',
                style: Club.label(13, color: Club.brassHi, spacing: 3.0),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: 220,
                child: AnimatedBuilder(
                  animation: _loader,
                  builder: (_, _) => Column(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: Colors.black.withValues(alpha: 0.45),
                          border: Border.all(
                              color: Club.brass.withValues(alpha: 0.5)),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _loader.value.clamp(0.02, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: Club.brassHi,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _loader.value < 1 ? 'Warming up the chrono…' : 'Ready!',
                        style: Club.bodyText(13,
                            color: Club.cream.withValues(alpha: 0.75)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 44),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/wajiha_logo.png',
                    width: 30,
                    height: 30,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Credits: WAJIHA',
                    style: Club.label(14, color: Club.cream, spacing: 2.0),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
