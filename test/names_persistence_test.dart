import 'package:flutter_test/flutter_test.dart';
import 'package:reversirush/state/club_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Regression tests for the player-name persistence bug found in batch-1
/// (2026-10-09): SharedPreferences.setStringList is backed by an UNORDERED
/// StringSet on Android, so name lists stored that way came back scrambled
/// after an app restart.
///
/// Reversi Rush stores each pilot name under its OWN string key
/// (rr_name_solo1, rr_name_solo2, rr_name_duo1, ...), which is inherently
/// order-preserving. These tests lock that in: a rename must survive a
/// save/load cycle in the exact slot it was written to, with no
/// setStringList anywhere in the name path.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ClubSettings> fresh() async {
    final s = ClubSettings();
    await s.load();
    return s;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('renamed pilot names survive save/load in their exact slots', () async {
    final s = await fresh();
    final names = {
      'soloHuman': 'Wajiha',
      'soloAi': 'ZaraBot',
      'duoBlack': 'Onyx',
      'duoWhite': 'Pearl',
      'blitzBlack': 'Night Pilot',
      'blitzWhite': 'Dawn Pilot',
    };
    for (final e in names.entries) {
      s.setPilotName(e.key, e.value);
    }
    // Simulate an app restart: brand-new settings object, same prefs store.
    final reloaded = await fresh();
    for (final e in names.entries) {
      expect(reloaded.pilotName(e.key), e.value,
          reason: 'slot ${e.key} must keep its own name after restart');
    }
  });

  test('each slot has its own persisted string key (order-safe)', () async {
    final s = await fresh();
    s.setPilotName('soloHuman', 'Slot A');
    s.setPilotName('duoWhite', 'Slot B');
    final p = await SharedPreferences.getInstance();
    expect(p.getString('rr_name_solo1'), 'Slot A');
    expect(p.getString('rr_name_duo2'), 'Slot B');
    // And no list-based storage is used for names.
    expect(p.getStringList('rr_name_solo1'), isNull);
  });

  test('blank renames fall back to the slot default, not an empty name',
      () async {
    final s = await fresh();
    s.setPilotName('soloHuman', '   ');
    final reloaded = await fresh();
    expect(reloaded.pilotName('soloHuman'), 'YOU');
  });
}
