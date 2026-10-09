import 'package:flutter/material.dart';

import '../audio/club_audio.dart';
import '../engine/reversi.dart';
import '../state/club_state.dart';
import '../theme/club_theme.dart';
import 'menu_screen.dart';
import 'widgets/brass_widgets.dart';

/// Club preferences: brass header, cream rally-card rows, heavy brass lever
/// toggles, blitz chrono selector, automaton calibre, machined volume gauge.
class SettingsScreen extends StatelessWidget {
  final ClubSettings settings;
  final ClubAudio audio;
  final VoidCallback onBack;
  final VoidCallback onThemes;

  const SettingsScreen({
    super.key,
    required this.settings,
    required this.audio,
    required this.onBack,
    required this.onThemes,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (_, _) => Scaffold(
        backgroundColor: Club.cream,
        body: Column(
          children: [
            ClubHeader(
              title: 'CLUB PREFERENCES',
              sub: 'PADDOCK CLUB PREFERENCES',
              trailing: BrassIconButton(
                icon: Icons.check,
                onTap: () {
                  audio.play(ClubSound.click);
                  settings.save();
                  onBack();
                },
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle('AUDIO & TELEMETRY'),
                    RallyCard(
                      child: Column(
                        children: [
                          _ToggleRow(
                            label: 'CLUB MUSIC',
                            sub: 'Lounge bed in lobby & duel',
                            value: settings.musicOn,
                            onChanged: (v) {
                              settings.setMusic(v);
                              audio.musicOn = v;
                              audio.applySettings();
                              if (v) audio.startMenuMusic();
                            },
                          ),
                          const _Divider(),
                          _ToggleRow(
                            label: 'BRASS & ENAMEL SFX',
                            sub: 'Clicks, ticks, stopwatch stings',
                            value: settings.sfxOn,
                            onChanged: (v) {
                              settings.setSfx(v);
                              audio.sfxOn = v;
                              audio.applySettings();
                              audio.play(ClubSound.click);
                            },
                          ),
                          const _Divider(),
                          _ToggleRow(
                            label: 'MECHANICAL HAPTICS',
                            sub: 'A nudge on every disc placed',
                            value: settings.hapticsOn,
                            onChanged: (v) {
                              settings.setHaptics(v);
                            },
                          ),
                          const _Divider(),
                          _ToggleRow(
                            label: 'LEGAL-MOVE HINTS',
                            sub: 'Brass rings on playable squares',
                            value: settings.hintsOn,
                            onChanged: (v) {
                              settings.setHints(v);
                            },
                          ),
                          const _Divider(),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('VOLUME',
                                    style: Club.label(12,
                                        color: Club.darkTeak
                                            .withValues(alpha: 0.7))),
                                const SizedBox(height: 8),
                                VolumeGauge(
                                  value: settings.volume,
                                  onChanged: (v) {
                                    settings.setVolume(v);
                                    audio.volume = v;
                                    audio.applySettings();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionTitle('PILOT NAMES'),
                    RallyCard(
                      child: Column(
                        children: [
                          for (final entry in const [
                            ('SOLO — BLACK PILOT', 'soloHuman'),
                            ('SOLO — AUTOMATON', 'soloAi'),
                            ('DUEL — BLACK', 'duoBlack'),
                            ('DUEL — WHITE', 'duoWhite'),
                            ('BLITZ — BLACK PILOT', 'blitzBlack'),
                            ('BLITZ — WHITE PILOT', 'blitzWhite'),
                          ])
                            _NameRow(
                              label: entry.$1,
                              slot: entry.$2,
                              settings: settings,
                              audio: audio,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionTitle('TABLE & DISCS'),
                    RallyCard(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('DRESS THE CLUB',
                                        style: Club.label(13,
                                            spacing: 1.8)),
                                    Text(
                                        '${settings.theme.name} · ${settings.discStyle.name}',
                                        style: Club.bodyText(11,
                                            color: Club.darkTeak.withValues(
                                                alpha: 0.6))),
                                  ],
                                ),
                              ),
                              BrassIconButton(
                                icon: Icons.palette,
                                onTap: () {
                                  audio.play(ClubSound.click);
                                  onThemes();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionTitle('RACE RULES & CHRONO INTERVALS'),
                    RallyCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CHRONO BLITZ (TIME PER PILOT)',
                              style: Club.label(12,
                                  color:
                                      Club.darkTeak.withValues(alpha: 0.7))),
                          const SizedBox(height: 8),
                          Segmented(
                            options: const ['5 MIN', '10 MIN', '15 MIN'],
                            selected: const [5, 10, 15]
                                .indexOf(settings.blitzMinutes),
                            onSelect: (i) {
                              settings.setBlitzMinutes([5, 10, 15][i]);
                              audio.play(ClubSound.click);
                            },
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Run dry on your chrono and you lose on time — regardless of the board.',
                            style: Club.bodyText(11,
                                color: Club.darkTeak.withValues(alpha: 0.6)),
                          ),
                          const _Divider(),
                          _ToggleRow(
                            label: 'BLITZ VS AUTOMATON',
                            sub: 'Blitz duels pit you against the automaton',
                            value: settings.blitzVsAi,
                            onChanged: (v) {
                              settings.setBlitzVsAi(v);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionTitle('AUTOMATON OPPONENT (SOLO)'),
                    RallyCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('STARTER TIMING RATE',
                              style: Club.label(12,
                                  color:
                                      Club.darkTeak.withValues(alpha: 0.7))),
                          const SizedBox(height: 8),
                          Segmented(
                            options:
                                AiLevel.values.map((e) => e.label).toList(),
                            selected: settings.aiLevel.index,
                            onSelect: (i) {
                              settings.setAiLevel(AiLevel.values[i]);
                              audio.play(ClubSound.click);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    BrassButton(
                      label: 'SAVE PREFERENCES',
                      primary: true,
                      onTap: () {
                        audio.play(ClubSound.click);
                        settings.save();
                        onBack();
                      },
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'All preferences live on this device — the club keeps no ledgers elsewhere.',
                        textAlign: TextAlign.center,
                        style: Club.bodyText(11,
                            color: Club.darkTeak.withValues(alpha: 0.55)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(text,
          style: Club.label(13, color: Club.brassDeep, spacing: 2.4)),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final String sub;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.sub,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: Club.label(13, spacing: 1.8)),
                Text(sub,
                    style: Club.bodyText(11,
                        color: Club.darkTeak.withValues(alpha: 0.6))),
              ],
            ),
          ),
          LeverToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: Club.hairline,
    );
  }
}

class _NameRow extends StatelessWidget {
  final String label;
  final String slot;
  final ClubSettings settings;
  final ClubAudio audio;

  const _NameRow({
    required this.label,
    required this.slot,
    required this.settings,
    required this.audio,
  });

  Future<void> _edit(BuildContext context) async {
    final text = TextEditingController(text: settings.pilotName(slot));
    // Focus-loss commit: tapping outside the dialog (barrier dismiss) saves
    // whatever was typed; only explicit CANCEL discards. Keyboard-done and
    // the SAVE button commit as before.
    var cancelled = false;
    final next = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Club.cream,
        title: Text('RENAME PILOT',
            style: Club.label(14, color: Club.darkTeak, spacing: 2.4)),
        content: TextField(
          controller: text,
          autofocus: true,
          maxLength: 16,
          style: Club.bodyText(16),
          decoration: const InputDecoration(
            hintText: 'Pilot name',
            counterText: '',
          ),
          onSubmitted: (_) => Navigator.of(ctx).pop(text.text),
        ),
        actions: [
          TextButton(
            onPressed: () {
              cancelled = true;
              Navigator.of(ctx).pop();
            },
            child: Text('CANCEL',
                style: Club.label(12, color: Club.darkTeak)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(text.text),
            child:
                Text('SAVE', style: Club.label(12, color: Club.brassDeep)),
          ),
        ],
      ),
    );
    if (next != null || !cancelled) {
      settings.setPilotName(slot, next ?? text.text);
      audio.play(ClubSound.click);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Club.label(11, spacing: 1.8)),
                Text(settings.pilotName(slot),
                    style: Club.bodyText(14, color: Club.brassDeep)),
              ],
            ),
          ),
          BrassIconButton(
            icon: Icons.edit,
            size: 38,
            onTap: () => _edit(context),
          ),
        ],
      ),
    );
  }
}
