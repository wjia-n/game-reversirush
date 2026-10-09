import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

/// Synthesized club audio: brass clicks, enamel ticks, stopwatch winding,
/// lounge music beds. All waveforms are generated in code (no audio assets),
/// matching the game's physical identity: teak, brass, enamel, stopwatch.
class ClubSynth {
  static const rate = 22050;
  static final _rng = Random(1234);

  /// Encodes mono 16-bit PCM samples into a WAV byte buffer.
  static Uint8List wav(List<double> s) {
    final n = s.length;
    final data = ByteData(44 + n * 2);
    void ascii(int o, String t) {
      for (var i = 0; i < t.length; i++) {
        data.setUint8(o + i, t.codeUnitAt(i));
      }
    }

    ascii(0, 'RIFF');
    data.setUint32(4, 36 + n * 2, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little); // PCM
    data.setUint16(22, 1, Endian.little); // mono
    data.setUint32(24, rate, Endian.little);
    data.setUint32(28, rate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    ascii(36, 'data');
    data.setUint32(40, n * 2, Endian.little);
    for (var i = 0; i < n; i++) {
      final v = s[i].clamp(-1.0, 1.0);
      data.setInt16(44 + i * 2, (v * 32767).round(), Endian.little);
    }
    return data.buffer.asUint8List();
  }

  static List<double> _tone(double freq, double secs,
      {double decay = 6, double attack = 0.004, double harmonic = 0.0}) {
    final n = (secs * rate).round();
    final out = List<double>.filled(n, 0);
    for (var i = 0; i < n; i++) {
      final t = i / rate;
      final env = (1 - exp(-t / max(attack, 1e-4))) * exp(-t * decay);
      out[i] = (sin(2 * pi * freq * t) + harmonic * sin(2 * pi * freq * 4 * t)) *
          env;
    }
    return out;
  }

  static List<double> _noise(double secs, {double decay = 40}) {
    final n = (secs * rate).round();
    final out = List<double>.filled(n, 0);
    for (var i = 0; i < n; i++) {
      out[i] = (_rng.nextDouble() * 2 - 1) * exp(-(i / rate) * decay);
    }
    return out;
  }

  static List<double> _mix(List<List<double>> parts) {
    var n = 0;
    for (final p in parts) {
      n = max(n, p.length);
    }
    final out = List<double>.filled(n, 0);
    for (final p in parts) {
      for (var i = 0; i < p.length; i++) {
        out[i] += p[i];
      }
    }
    final peak = out.fold<double>(0, (a, b) => max(a, b.abs()));
    if (peak > 0.98) {
      for (var i = 0; i < n; i++) {
        out[i] *= 0.98 / peak;
      }
    }
    return out;
  }

  static List<double> _at(List<double> s, double secs) {
    final off = (secs * rate).round();
    final out = List<double>.filled(off + s.length, 0);
    for (var i = 0; i < s.length; i++) {
      out[off + i] += s[i];
    }
    return out;
  }

  // ---------- one-shots ----------

  /// Brass dash-button click.
  static List<double> click() {
    final n = (0.09 * rate).round();
    final out = List<double>.filled(n, 0);
    for (var i = 0; i < n; i++) {
      final t = i / rate;
      final f = 3600 - 1400 * (t / 0.09);
      out[i] = sin(2 * pi * f * t) * exp(-t * 55) * 0.7;
      if (i < _noise(0.012).length) out[i] += _noise(0.012)[i] * 0.35;
    }
    return out;
  }

  /// Disc placed: teak thunk + enamel ping.
  static List<double> place() => _mix([
        _tone(150, 0.16, decay: 22),
        _tone(2400, 0.05, decay: 60, harmonic: 0.2),
        _noise(0.02, decay: 90),
      ]);

  /// Disc flip tick.
  static List<double> flip() => _tone(4800, 0.045, decay: 70);

  /// Illegal move: dull brass clunk.
  static List<double> invalid() => _mix([
        _tone(95, 0.18, decay: 18),
        _tone(65, 0.2, decay: 14),
      ]);

  /// Stopwatch wind-up at game start.
  static List<double> gameStart() {
    final parts = <List<double>>[];
    for (var k = 0; k < 8; k++) {
      parts.add(_at(_tone(1000 + k * 150, 0.03, decay: 80), k * 0.055));
    }
    parts.add(_at(_mix([_tone(3000, 0.06, decay: 50), _noise(0.03)]), 0.48));
    return _mix(parts);
  }

  /// Victory: brass vibraphone arpeggio.
  static List<double> win() {
    final notes = [329.63, 392.0, 493.88, 659.25];
    final parts = <List<double>>[];
    for (var k = 0; k < notes.length; k++) {
      final tone = _tone(notes[k], 0.5, decay: 4, harmonic: 0.25);
      for (var i = 0; i < tone.length; i++) {
        tone[i] *= 0.75 + 0.25 * sin(2 * pi * 6 * i / rate);
      }
      parts.add(_at(tone, k * 0.14));
    }
    return _mix(parts);
  }

  /// Defeat: descending low tones.
  static List<double> lose() {
    final notes = [220.0, 174.61, 146.83];
    final parts = <List<double>>[];
    for (var k = 0; k < notes.length; k++) {
      parts.add(_at(_tone(notes[k], 0.4, decay: 5), k * 0.2));
    }
    return _mix(parts);
  }

  /// Countdown stopwatch tick.
  static List<double> tick() => _tone(6000, 0.03, decay: 90);

  /// Pass: soft mechanical sweep.
  static List<double> pass() {
    final n = (0.25 * rate).round();
    final out = List<double>.filled(n, 0);
    for (var i = 0; i < n; i++) {
      final t = i / rate;
      out[i] = sin(2 * pi * (900 - 2400 * t) * t) * exp(-t * 9) * 0.4;
    }
    return _mix([out, _at(_tone(1200, 0.05, decay: 40), 0.2)]);
  }

  /// Hint chime.
  static List<double> hint() => _mix([
        _at(_tone(1568, 0.2, decay: 12, harmonic: 0.2), 0),
        _at(_tone(2093, 0.25, decay: 12, harmonic: 0.2), 0.12),
      ]);

  // ---------- music loops ----------

  static List<double> _pad(List<double> freqs, double secs) {
    final parts = freqs
        .map((f) => _tone(f, secs, decay: 0.6, attack: secs * 0.3))
        .toList();
    final mixed = _mix(parts);
    // gentle release at loop end for seamless looping
    final fade = (0.4 * rate).round();
    for (var i = 0; i < fade && i < mixed.length; i++) {
      final k = i / fade;
      mixed[mixed.length - 1 - i] *= k * k;
    }
    return mixed;
  }

  static List<double> _brushedTick(double at, double gain) =>
      _at(_noise(0.05, decay: 60).map((v) => v * gain).toList(), at);

  /// Menu bed: mid-century lounge pads, brushed ticks.
  static List<double> menuMusic() {
    const barLen = 2.4;
    final chords = [
      [110.0, 220.0, 261.63, 329.63], // Am add9-ish
      [87.31, 174.61, 220.0, 329.63], // Fmaj9-ish
      [146.83, 293.66, 349.23, 440.0], // Dm
      [164.81, 329.63, 415.30, 493.88], // E7-ish
    ];
    final total = (barLen * 4 * rate).round();
    final out = List<double>.filled(total, 0);
    for (var c = 0; c < 4; c++) {
      final pad = _pad(chords[c], barLen);
      final off = (c * barLen * rate).round();
      for (var i = 0; i < pad.length && off + i < total; i++) {
        out[off + i] += pad[i] * 0.5;
      }
      for (var b = 0; b < 4; b++) {
        final tick = _brushedTick(0, 0.12);
        final toff = (off + (b * barLen / 4 * rate)).round();
        for (var i = 0; i < tick.length && toff + i < total; i++) {
          out[toff + i] += tick[i];
        }
      }
    }
    return out;
  }

  /// Gameplay bed: same lounge family with a steady stopwatch pulse.
  static List<double> gameMusic() {
    const barLen = 2.0;
    final chords = [
      [110.0, 220.0, 261.63, 392.0],
      [87.31, 174.61, 261.63, 349.23],
      [130.81, 261.63, 329.63, 392.0],
      [98.0, 196.0, 246.94, 392.0],
    ];
    final total = (barLen * 6 * rate).round();
    final out = List<double>.filled(total, 0);
    for (var c = 0; c < 6; c++) {
      final pad = _pad(chords[c % 4], barLen);
      final off = (c * barLen * rate).round();
      for (var i = 0; i < pad.length && off + i < total; i++) {
        out[off + i] += pad[i] * 0.42;
      }
      // stopwatch pulse: two ticks per second
      for (var t = 0; t < barLen * 2; t++) {
        final tick = _tone(t.isEven ? 5200 : 4300, 0.03, decay: 80);
        final toff = (off + (t * 0.5 * rate)).round();
        for (var i = 0; i < tick.length && toff + i < total; i++) {
          out[toff + i] += tick[i] * 0.10;
        }
      }
      // soft bass pulse
      final bass = _tone(chords[c % 4][0] / 2, 0.3, decay: 8);
      for (var i = 0; i < bass.length && off + i < total; i++) {
        out[off + i] += bass[i] * 0.35;
      }
    }
    return out;
  }
}

enum ClubSound { click, place, flip, invalid, gameStart, win, lose, tick, pass, hint }

/// Audio service: one looping music player + a small SFX pool.
class ClubAudio {
  final AudioPlayer _music = AudioPlayer();
  final List<AudioPlayer> _pool = List.generate(4, (_) => AudioPlayer());
  int _poolIdx = 0;
  final Map<ClubSound, Uint8List> _sfxCache = {};
  Uint8List? _menuMusic;
  Uint8List? _gameMusic;

  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.7;
  bool _musicIsGame = false;

  Future<void> init({required bool musicOn, required bool sfxOn, required double volume}) async {
    this.musicOn = musicOn;
    this.sfxOn = sfxOn;
    this.volume = volume;
    await _music.setVolume(volume * 0.9);
    await _music.setReleaseMode(ReleaseMode.loop);
  }

  Future<void> applySettings() async {
    await _music.setVolume(musicOn ? volume * 0.9 : 0);
    for (final p in _pool) {
      await p.setVolume(sfxOn ? volume : 0);
    }
  }

  Uint8List _bytes(ClubSound s) => _sfxCache.putIfAbsent(s, () {
        final samples = switch (s) {
          ClubSound.click => ClubSynth.click(),
          ClubSound.place => ClubSynth.place(),
          ClubSound.flip => ClubSynth.flip(),
          ClubSound.invalid => ClubSynth.invalid(),
          ClubSound.gameStart => ClubSynth.gameStart(),
          ClubSound.win => ClubSynth.win(),
          ClubSound.lose => ClubSynth.lose(),
          ClubSound.tick => ClubSynth.tick(),
          ClubSound.pass => ClubSynth.pass(),
          ClubSound.hint => ClubSynth.hint(),
        };
        return ClubSynth.wav(samples);
      });

  Future<void> play(ClubSound s) async {
    if (!sfxOn) return;
    try {
      final p = _pool[_poolIdx];
      _poolIdx = (_poolIdx + 1) % _pool.length;
      await p.setVolume(volume);
      await p.play(BytesSource(_bytes(s)));
    } catch (_) {
      // Audio is best-effort; never break gameplay.
    }
  }

  Future<void> startMenuMusic() async {
    if (_musicIsGame == false && _menuMusic != null) return;
    _menuMusic ??= ClubSynth.wav(ClubSynth.menuMusic());
    _musicIsGame = false;
    try {
      await _music.stop();
      await _music.setVolume(musicOn ? volume * 0.9 : 0);
      await _music.play(BytesSource(_menuMusic!));
    } catch (_) {}
  }

  Future<void> startGameMusic() async {
    if (_musicIsGame && _gameMusic != null) return;
    _gameMusic ??= ClubSynth.wav(ClubSynth.gameMusic());
    _musicIsGame = true;
    try {
      await _music.stop();
      await _music.setVolume(musicOn ? volume * 0.9 : 0);
      await _music.play(BytesSource(_gameMusic!));
    } catch (_) {}
  }

  Future<void> stopMusic() async {
    try {
      await _music.stop();
    } catch (_) {}
    _menuMusic = null;
    _gameMusic = null;
  }

  Future<void> dispose() async {
    await _music.dispose();
    for (final p in _pool) {
      await p.dispose();
    }
  }
}
